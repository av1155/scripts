-- abs.lua — absolutize relative URLs using BASE_URL env var
local base = os.getenv("BASE_URL") or ""

local function is_abs(u)
    return u:match("^%a[%w+.-]*://") or u:match("^//")
end

local function join(u)
    -- normalize leading "./"
    u = u:gsub("^%./", "")
    -- if path starts with "/", join with site root (scheme+host only)
    if u:sub(1, 1) == "/" then
        return base:gsub("^(https?://[^/]+).*", "%1") .. u
    end
    return base .. u
end

local function absolutize(u)
    if base == "" or is_abs(u or "") then
        return u
    end
    return join(u)
end

function Image(el)
    el.src = absolutize(el.src)
    return el
end

function Link(el)
    el.target = absolutize(el.target)
    return el
end

-- Handle raw HTML <img src>, <a href>, <script src>, <link href>, etc.
local function rewrite_raw_html(html)
    if base == "" then
        return html
    end
    -- match src= or href= with "..." or '...'
    html = html:gsub("([%s>])(src|href)=(['\"])(.-)%3", function(sp, attr, quote, url)
        if is_abs(url) then
            return sp .. attr .. "=" .. quote .. url .. quote
        end
        return sp .. attr .. "=" .. quote .. join(url) .. quote
    end)
    return html
end

function RawInline(el)
    if el.format:match("html") then
        el.text = rewrite_raw_html(el.text)
    end
    return el
end

function RawBlock(el)
    if el.format:match("html") then
        el.text = rewrite_raw_html(el.text)
    end
    return el
end
