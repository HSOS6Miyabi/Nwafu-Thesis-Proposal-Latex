#!/usr/bin/env python3
"""Check example PDF fonts and ensure cover title groups do not intersect."""
from pathlib import Path
import subprocess
import sys
from xml.etree import ElementTree


def capture(*command: str) -> str:
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def check(pdf_file: Path) -> None:
    font_table = capture("pdffonts", str(pdf_file))
    for font in ("FandolSong-Regular", "FandolHei-Regular", "XITS-Regular"):
        if font not in font_table:
            raise ValueError(f"{pdf_file.name}: missing embedded font {font}")

    html = capture("pdftotext", "-f", "1", "-l", "1", "-bbox", str(pdf_file), "-")
    root = ElementTree.fromstring(html)
    words = [("".join(tag.itertext()).strip(), float(tag.attrib["yMin"]),
              float(tag.attrib["yMax"])) for tag in root.iter() if tag.tag.endswith("}word")]
    chinese = [w for w in words if w[0] in {
        "开题报告中文标题第一行", "开题报告中文标题第二行"}]
    english = [w for w in words if w[0] in {
        "English", "Title", "of", "the", "Research", "Proposal", "Goes", "Here"}]
    fields = [w for w in words if w[0] == "学院（系、所）名称"]

    if len(chinese) != 2 or len(english) != 8 or len(fields) != 1:
        raise ValueError(f"{pdf_file.name}: expected public title or field is missing")
    between_titles = min(w[1] for w in english) - max(w[2] for w in chinese)
    before_fields = fields[0][1] - max(w[2] for w in english)
    if between_titles < 8 or before_fields < 8:
        raise ValueError(
            f"{pdf_file.name}: title areas too close "
            f"(Chinese/English gap {between_titles:.1f}pt; English/fields gap {before_fields:.1f}pt)"
        )
    print(f"PASS: {pdf_file.name} fonts and cover typography, gaps "
          f"{between_titles:.1f}pt / {before_fields:.1f}pt")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: check-cover-layout.py <example.pdf>")
    try:
        check(Path(sys.argv[1]))
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
