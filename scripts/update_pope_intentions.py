#!/usr/bin/env python3
"""Refresh Rosary Guide's Holy Father's intention feed from public sources.

The iOS app reads RosaryGuide/Data/PopeIntentions.json. This script keeps that
file in a stable app-facing schema while sourcing current content from official
public pages. It is intentionally dependency-free so GitHub Actions can run it
without setup beyond Python.
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "RosaryGuide" / "Data" / "PopeIntentions.json"
VATICAN_PRAYERS_INDEX = "https://www.vatican.va/content/leo-xiv/en/prayers.html"
PWPN_YEAR_URL = "https://www.popesprayer.va/the-popes-prayer-intentions-for-{year}/"

MONTHS = {
    "january": 1,
    "february": 2,
    "march": 3,
    "april": 4,
    "may": 5,
    "june": 6,
    "july": 7,
    "august": 8,
    "september": 9,
    "october": 10,
    "november": 11,
    "december": 12,
}


def fetch(url: str) -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "RosaryGuideIntentionsBot/1.0 (+https://github.com/Xultptyltd/RosaryGuide)",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as response:
        charset = response.headers.get_content_charset() or "utf-8"
        return response.read().decode(charset, errors="replace")


def clean_text(value: str) -> str:
    value = re.sub(r"<script[\s\S]*?</script>", " ", value, flags=re.I)
    value = re.sub(r"<style[\s\S]*?</style>", " ", value, flags=re.I)
    value = re.sub(r"<[^>]+>", " ", value)
    value = html.unescape(value)
    value = value.replace("\u00a0", " ")
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r"\s*\n\s*", "\n", value)
    return value.strip()


def paragraph_texts(page_html: str) -> list[str]:
    paragraphs = re.findall(r"<p\b[^>]*>([\s\S]*?)</p>", page_html, flags=re.I)
    cleaned = [clean_text(p) for p in paragraphs]
    return [p for p in cleaned if len(p) >= 20]


def find_vatican_pages(index_html: str, year: int, month: int) -> list[str]:
    candidates: list[str] = []
    for href in re.findall(r'href=["\']([^"\']+)["\']', index_html, flags=re.I):
        lower = href.lower()
        if "prayers/documents/" not in lower:
            continue
        if "pope" not in lower and "prayer" not in lower and "preghiera" not in lower:
            continue
        if str(year) not in lower:
            continue
        full = urllib.parse.urljoin(VATICAN_PRAYERS_INDEX, href)
        if "/en/" not in full.lower():
            continue
        if full not in candidates:
            candidates.append(full)

    # Prefer month-coded Vatican URLs such as 20260901-...
    needle = f"{year}{month:02d}"
    candidates.sort(key=lambda url: (needle not in url, url))
    return candidates


def title_from_text(text: str, year: int, month: int) -> str | None:
    month_name = month_name_for(month)
    patterns = [
        rf"{month_name}\s+{year}\s*[:\-–]\s*(For [^\n.]+)",
        rf"{month_name.upper()}\s*[:\-–]\s*(For [^\n.]+)",
        r"Prayer Intention\s*[-–:]\s*(For [^\n.]+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.I)
        if match:
            return normalize_title(match.group(1))
    return None


def normalize_title(title: str) -> str:
    title = clean_text(title).strip(" .:-–")
    if not title:
        return title
    return title[0].upper() + title[1:]


def month_name_for(month: int) -> str:
    for name, number in MONTHS.items():
        if number == month:
            return name.capitalize()
    raise ValueError(month)


def note_from_year_page(year: int, month: int) -> str | None:
    try:
        text = clean_text(fetch(PWPN_YEAR_URL.format(year=year)))
    except (urllib.error.URLError, TimeoutError):
        return None

    month_name = month_name_for(month)
    start = re.search(rf"\b{month_name}\b", text, flags=re.I)
    if not start:
        return None
    segment = text[start.start() : start.start() + 1200]
    match = re.search(r"(Let us pray[^.]+(?:\.[^.]+){0,2})", segment, flags=re.I)
    if match:
        return clean_text(match.group(1)).strip()
    return None


def extract_from_vatican_page(page_html: str) -> list[str]:
    blocked = (
        "pray with the pope",
        "videomessage of the holy father",
        "pope's worldwide prayer network",
        "copyright",
        "bollettino",
        "press office",
        "vatican.va",
    )
    result: list[str] = []
    for paragraph in paragraph_texts(page_html):
        compact = paragraph.strip()
        lower = compact.lower()
        if any(token in lower for token in blocked):
            continue
        if re.fullmatch(r"[_\-\s]+", compact):
            continue
        if re.fullmatch(r"[A-Z]+\s*:\s*For .+", compact):
            continue
        if lower.startswith("in the name of the father"):
            continue
        if compact not in result:
            result.append(compact)

    # Keep the devotional body, but avoid dragging in a whole webpage.
    return result[:10]


def fetch_current_intention(year: int, month: int) -> dict[str, object] | None:
    index_html = fetch(VATICAN_PRAYERS_INDEX)
    pages = find_vatican_pages(index_html, year, month)
    target_month = month_name_for(month).lower()

    for url in pages:
        try:
            page_html = fetch(url)
        except (urllib.error.URLError, TimeoutError):
            continue
        text = clean_text(page_html)
        if target_month not in text.lower() or str(year) not in text:
            continue

        title = title_from_text(text, year, month)
        extract = extract_from_vatican_page(page_html)
        if not title and extract:
            first_for = next((p for p in extract if p.lower().startswith("for ")), None)
            title = normalize_title(first_for or "")

        if title:
            item: dict[str, object] = {
                "yearMonth": f"{year:04d}-{month:02d}",
                "title": title,
                "note": note_from_year_page(year, month) or title,
                "description": "A monthly prayer intention from Pope Leo.",
                "extract": extract,
                "sourceTitle": f"Vatican, Pray with the Pope, {month_name_for(month)} {year}",
                "sourceURL": url,
            }
            return item
    return None


def load_existing(path: Path) -> list[dict[str, object]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array")
    return data


def write_feed(path: Path, items: list[dict[str, object]]) -> None:
    path.write_text(json.dumps(items, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def upsert(items: list[dict[str, object]], item: dict[str, object]) -> list[dict[str, object]]:
    key = item["yearMonth"]
    by_month = {existing.get("yearMonth"): existing for existing in items}
    existing = by_month.get(key, {})
    cleaned = {k: v for k, v in item.items() if v not in (None, "", [])}

    if existing.get("note") and cleaned.get("note") == cleaned.get("title"):
        cleaned["note"] = existing["note"]
    if existing.get("description") and cleaned.get("description") == "A monthly prayer intention from Pope Leo.":
        cleaned["description"] = existing["description"]
    if existing.get("extract") and len(cleaned.get("extract", [])) < len(existing.get("extract", [])):
        cleaned["extract"] = existing["extract"]

    by_month[key] = cleaned
    return [by_month[k] for k in sorted(by_month.keys()) if isinstance(k, str)]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--date", help="Date to update, YYYY-MM-DD. Defaults to today UTC.")
    parser.add_argument("--output", type=Path, default=DATA_PATH)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    today = dt.date.fromisoformat(args.date) if args.date else dt.datetime.utcnow().date()
    item = fetch_current_intention(today.year, today.month)
    if not item:
        print(f"No official intention found for {today.year}-{today.month:02d}; leaving feed unchanged.")
        return 0

    items = upsert(load_existing(args.output), item)
    write_feed(args.output, items)
    print(f"Updated {args.output} with {item['yearMonth']}: {item['title']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
