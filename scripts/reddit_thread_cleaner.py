#!/usr/bin/env python3
"""
Fetch and clean Reddit thread JSON into a lightweight structure.

Keeps:
- usernames
- comments / post body
- upvotes / downvotes
- compact stats
- full reply tree present in the input JSON

Features:
- Accepts either a local JSON file or a Reddit post URL
- Automatically converts a Reddit post URL to its .json endpoint
- Interactive mode when no input is provided
- Optional pretty-print output
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urlparse, urlunparse

import requests

USER_AGENT = "linux:reddit-thread-cleaner:1.0 (by /u/your_username)"


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
    stats: Dict[str, Any] = {}
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
    stats: Dict[str, Any] = {}
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

    replies: List[Dict[str, Any]] = []
    for child in normalize_replies(data.get("replies")):
        cleaned = clean_comment(child)
        if cleaned is not None:
            replies.append(cleaned)

    out: Dict[str, Any] = {
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
    if isinstance(obj, list):
        for item in obj:
            found = find_first_post_object(item)
            if found is not None:
                return found
        return None

    if isinstance(obj, dict):
        if obj.get("kind") == "t3":
            return obj

        if obj.get("kind") == "Listing":
            for child in obj.get("data", {}).get("children", []) or []:
                found = find_first_post_object(child)
                if found is not None:
                    return found

        data = obj.get("data")
        if isinstance(data, dict):
            name = data.get("name", "")
            if (
                "title" in data
                or obj.get("kind") == "t3"
                or (isinstance(name, str) and name.startswith("t3_"))
            ):
                return {"kind": "t3", "data": data}

    return None


def find_comment_listing(obj: Any) -> List[Dict[str, Any]]:
    if isinstance(obj, list):
        if len(obj) >= 2:
            second = obj[1]
            if isinstance(second, dict) and second.get("kind") == "Listing":
                children = second.get("data", {}).get("children", []) or []
                if isinstance(children, list):
                    return children

        for item in obj:
            children = find_comment_listing(item)
            if children:
                return children
        return []

    if isinstance(obj, dict):
        if obj.get("kind") == "Listing":
            children = obj.get("data", {}).get("children", []) or []
            if any(
                isinstance(c, dict) and c.get("kind") in {"t1", "more"}
                for c in children
            ):
                return children

            for child in children:
                nested = find_comment_listing(child)
                if nested:
                    return nested

        if obj.get("kind") in {"t1", "more"}:
            return [obj]

    return []


def clean_post(node: Dict[str, Any]) -> Dict[str, Any]:
    data = node.get("data", {})
    out: Dict[str, Any] = {
        "title": data.get("title"),
        "author": data.get("author"),
        "post": data.get("selftext", data.get("body", "")),
        "upvotes": data.get("ups", data.get("score")),
        "downvotes": data.get("downs", 0),
        "post_stats": post_stats(data),
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

    cleaned_comments: List[Dict[str, Any]] = []
    for node in comment_nodes:
        cleaned = clean_comment(node)
        if cleaned is not None:
            cleaned_comments.append(cleaned)

    result: Dict[str, Any] = {"thread": {}}

    if post_obj is not None:
        result["thread"].update(clean_post(post_obj))

    result["thread"]["comments"] = cleaned_comments
    result["thread"]["thread_stats"] = {
        "top_level_items": len(comment_nodes),
        "top_level_comments": sum(
            1 for n in comment_nodes if isinstance(n, dict) and n.get("kind") == "t1"
        ),
        "more_placeholders": sum(
            1 for n in comment_nodes if isinstance(n, dict) and n.get("kind") == "more"
        ),
    }

    return result


def is_url(value: str) -> bool:
    return value.startswith("http://") or value.startswith("https://")


def reddit_json_url(url: str) -> str:
    parsed = urlparse(url.strip())

    if not parsed.scheme or not parsed.netloc:
        raise ValueError("Not a valid URL.")

    if "reddit.com" not in parsed.netloc and "redd.it" not in parsed.netloc:
        raise ValueError("URL must be a Reddit URL.")

    path = parsed.path.rstrip("/")
    if not path.endswith(".json"):
        path += ".json"

    return urlunparse((parsed.scheme, parsed.netloc, path, "", "", ""))


def slugify(text: str, fallback: str = "reddit_thread") -> str:
    text = text.strip().lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = text.strip("_")
    return text or fallback


def default_output_path_for_file(input_path: Path) -> Path:
    return input_path.with_name(f"{input_path.stem}.cleaned.json")


def default_output_path_for_url(cleaned: Dict[str, Any]) -> Path:
    thread = cleaned.get("thread", {})
    title = thread.get("title") or ""
    post_id = thread.get("id") or "thread"
    base = slugify(title, fallback=f"reddit_{post_id}")
    return Path(f"{base}.cleaned.json")


def fetch_json_from_url(url: str) -> Any:
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
    }

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()

    content_type = response.headers.get("content-type", "")
    if "json" not in content_type.lower():
        raise ValueError(f"Expected JSON response, got: {content_type or 'unknown'}")

    return response.json()


def load_raw_input(source: str) -> Tuple[Any, str]:
    if is_url(source):
        json_url = reddit_json_url(source)
        raw = fetch_json_from_url(json_url)
        return raw, json_url

    path = Path(source)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    with path.open("r", encoding="utf-8") as f:
        raw = json.load(f)
    return raw, str(path)


def interactive_prompt() -> argparse.Namespace:
    print("Reddit Thread Cleaner")
    print("- Paste a Reddit URL or local JSON file path.")
    source = input("Input URL or file: ").strip()

    pretty_answer = input("Pretty-print output? [y/N]: ").strip().lower()
    pretty = pretty_answer in {"y", "yes"}

    output = input("Output file (leave blank for auto): ").strip()

    return argparse.Namespace(
        input=source,
        output=Path(output) if output else None,
        pretty=pretty,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fetch and clean Reddit thread JSON into a lightweight structure."
    )
    parser.add_argument(
        "input",
        nargs="?",
        help="Reddit post URL or local JSON file path",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Output path (default: auto-generated)",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print output JSON",
    )

    args = parser.parse_args()

    if not args.input:
        args = interactive_prompt()

    try:
        raw, source_label = load_raw_input(args.input)
        cleaned = clean_reddit_json(raw)

        if args.output is not None:
            output_path = args.output
        elif is_url(args.input):
            output_path = default_output_path_for_url(cleaned)
        else:
            output_path = default_output_path_for_file(Path(args.input))

        with output_path.open("w", encoding="utf-8") as f:
            if args.pretty:
                json.dump(cleaned, f, ensure_ascii=False, indent=2)
            else:
                json.dump(cleaned, f, ensure_ascii=False, separators=(",", ":"))
            f.write("\n")

        print(f"Source: {source_label}")
        print(f"Saved:  {output_path}")

    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}", file=sys.stderr)
        sys.exit(1)
    except requests.HTTPError as e:
        status = e.response.status_code if e.response is not None else "unknown"
        print(f"HTTP error: {status}", file=sys.stderr)
        sys.exit(1)
    except requests.RequestException as e:
        print(f"Network error: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
