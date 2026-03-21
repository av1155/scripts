#!/usr/bin/env python3
"""
Clean bulky Reddit thread JSON into a lightweight structure.

Keeps:
- usernames
- comments / post body
- upvotes / downvotes
- compact stats
- full reply tree present in the input JSON

Works best on Reddit JSON exports shaped like:
- the standard /comments/<id>.json response (two Listing objects), or
- a Listing / nested comment tree dump, or
- a single comment / post object.

Usage:
  python reddit_thread_cleaner.py input.json
  python reddit_thread_cleaner.py input.json -o cleaned.json
  python reddit_thread_cleaner.py input.json --pretty

Notes:
- This cleans only what is already present in the file.
- If your source JSON contains Reddit "more" placeholders instead of fully
  expanded comments, this script preserves the placeholders but cannot fetch
  missing comments offline.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Optional


def pick(d: Dict[str, Any], *keys: str) -> Dict[str, Any]:
    return {k: d[k] for k in keys if k in d and d[k] is not None}


def listing_children(node: Any) -> List[Dict[str, Any]]:
    if isinstance(node, dict) and node.get("kind") == "Listing":
        return node.get("data", {}).get("children", []) or []
    return []


def normalize_replies(raw: Any) -> List[Dict[str, Any]]:
    if raw in (None, ""):
        return []
    if isinstance(raw, dict):
        return listing_children(raw)
    return []


def comment_stats(data: Dict[str, Any]) -> Dict[str, Any]:
    stats = {}
    for key in (
        "score",
        "created_utc",
        "depth",
        "controversiality",
        "is_submitter",
        "edited",
        "stickied",
        "collapsed",
    ):
        if key in data:
            stats[key] = data[key]
    return stats


def post_stats(data: Dict[str, Any]) -> Dict[str, Any]:
    stats = {}
    for key in (
        "score",
        "upvote_ratio",
        "num_comments",
        "created_utc",
        "downs",
        "ups",
        "is_self",
        "over_18",
        "spoiler",
        "locked",
        "stickied",
        "archived",
        "pinned",
    ):
        if key in data:
            stats[key] = data[key]
    return stats


def clean_more(node: Dict[str, Any]) -> Dict[str, Any]:
    data = node.get("data", {}) if isinstance(node, dict) else {}
    out = {
        "kind": "more",
        "parent_id": data.get("parent_id"),
        "count": data.get("count"),
        "children_ids": data.get("children", []),
    }
    return {k: v for k, v in out.items() if v not in (None, [], "")}


def clean_comment(node: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    if not isinstance(node, dict):
        return None

    kind = node.get("kind")
    data = node.get("data", {})

    if kind == "more":
        return clean_more(node)

    if kind != "t1":
        return None

    replies = []
    for child in normalize_replies(data.get("replies")):
        cleaned = clean_comment(child)
        if cleaned is not None:
            replies.append(cleaned)

    out = {
        "username": data.get("author"),
        "comment": data.get("body", ""),
        "upvotes": data.get("ups", data.get("score")),
        "downvotes": data.get("downs", 0),
        "stats": comment_stats(data),
    }

    if "id" in data:
        out["id"] = data["id"]
    if "parent_id" in data:
        out["parent_id"] = data["parent_id"]
    if replies:
        out["replies"] = replies

    return out


def find_first_post_object(obj: Any) -> Optional[Dict[str, Any]]:
    """Try to find the main post (t3) in common Reddit JSON shapes."""
    if isinstance(obj, list):
        # Standard Reddit comments endpoint: [post_listing, comments_listing]
        for item in obj:
            found = find_first_post_object(item)
            if found:
                return found
        return None

    if isinstance(obj, dict):
        if obj.get("kind") == "t3":
            return obj
        if obj.get("kind") == "Listing":
            for child in obj.get("data", {}).get("children", []) or []:
                found = find_first_post_object(child)
                if found:
                    return found
        # Fallback for already-unwrapped objects
        data = obj.get("data")
        if isinstance(data, dict) and (
            "title" in data or obj.get("kind") == "t3" or data.get("name", "").startswith("t3_")
        ):
            return {"kind": "t3", "data": data}

    return None


def find_comment_listing(obj: Any) -> List[Dict[str, Any]]:
    """Return top-level comment nodes from common Reddit JSON shapes."""
    if isinstance(obj, list):
        # Standard Reddit /comments/<id>.json response
        if len(obj) >= 2:
            second = obj[1]
            if isinstance(second, dict) and second.get("kind") == "Listing":
                return second.get("data", {}).get("children", []) or []
        # Otherwise search recursively and merge the first comment listing found
        for item in obj:
            children = find_comment_listing(item)
            if children:
                return children
        return []

    if isinstance(obj, dict):
        if obj.get("kind") == "Listing":
            children = obj.get("data", {}).get("children", []) or []
            # If this listing itself is comments/more objects, use it.
            if any(isinstance(c, dict) and c.get("kind") in {"t1", "more"} for c in children):
                return children
            # Else recurse into children.
            for child in children:
                nested = find_comment_listing(child)
                if nested:
                    return nested
        # Already unwrapped comment tree object?
        if obj.get("kind") in {"t1", "more"}:
            return [obj]

    return []


def clean_post(node: Dict[str, Any]) -> Dict[str, Any]:
    data = node.get("data", {})
    out = {
        "title": data.get("title"),
        "author": data.get("author"),
        "post": data.get("selftext", data.get("body", "")),
        "upvotes": data.get("ups", data.get("score")),
        "downvotes": data.get("downs", 0),
        "stats": post_stats(data),
    }

    for key_in, key_out in (
        ("id", "id"),
        ("subreddit", "subreddit"),
        ("subreddit_name_prefixed", "subreddit_name"),
        ("url", "url"),
        ("permalink", "permalink"),
    ):
        if key_in in data and data[key_in] is not None:
            out[key_out] = data[key_in]

    return out


def clean_reddit_json(raw: Any) -> Dict[str, Any]:
    post_obj = find_first_post_object(raw)
    comment_nodes = find_comment_listing(raw)

    cleaned_comments = []
    for node in comment_nodes:
        cleaned = clean_comment(node)
        if cleaned is not None:
            cleaned_comments.append(cleaned)

    result: Dict[str, Any] = {"thread": {}}

    if post_obj is not None:
        result["thread"].update(clean_post(post_obj))

    result["thread"]["comments"] = cleaned_comments
    result["thread"]["stats"] = {
        "top_level_items": len(comment_nodes),
        "top_level_comments": sum(1 for n in comment_nodes if isinstance(n, dict) and n.get("kind") == "t1"),
        "more_placeholders": sum(1 for n in comment_nodes if isinstance(n, dict) and n.get("kind") == "more"),
    }

    return result


def default_output_path(input_path: Path) -> Path:
    return input_path.with_suffix("").with_name(input_path.stem + ".cleaned.json")


def main() -> None:
    parser = argparse.ArgumentParser(description="Clean Reddit thread JSON into a lightweight structure.")
    parser.add_argument("input", type=Path, help="Path to the Reddit JSON file")
    parser.add_argument("-o", "--output", type=Path, help="Output path (default: <input>.cleaned.json)")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print output JSON")
    args = parser.parse_args()

    with args.input.open("r", encoding="utf-8") as f:
        raw = json.load(f)

    cleaned = clean_reddit_json(raw)
    output_path = args.output or default_output_path(args.input)

    with output_path.open("w", encoding="utf-8") as f:
        if args.pretty:
            json.dump(cleaned, f, ensure_ascii=False, indent=2)
        else:
            json.dump(cleaned, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")

    print(output_path)


if __name__ == "__main__":
    main()
