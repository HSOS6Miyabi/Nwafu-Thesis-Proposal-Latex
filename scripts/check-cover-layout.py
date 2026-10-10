#!/usr/bin/env python3
"""Check example PDF fonts and ensure cover title groups do not intersect."""
from pathlib import Path
import subprocess
import re
import sys
from xml.etree import ElementTree


def capture(*command: str) -> str:
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def check(pdf_file: Path, build_log: Path, expected_english_lines: int = 3) -> None:
    font_table = capture("pdffonts", str(pdf_file))
    font_names = [line.split()[0] for line in font_table.splitlines()[2:] if line.strip()]
    log = build_log.read_text(encoding="utf-8", errors="replace")
    selected_fonts = (
        ("Latin", {
            "Times New Roman": ("TimesNewRoman", "Times-New-Roman"),
            "XITS": ("XITS-Regular",),
        }),
        ("Song", {
            "SimSun": ("SimSun",),
            "Chinese Songti": ("Songti", "STSong", "SimSun", "宋体"),
            "FandolSong": ("FandolSong",),
        }),
        ("Hei", {
            "SimHei": ("SimHei",),
            "Chinese Heiti": ("Heiti", "STHei", "SimHei", "黑体"),
            "FandolHei": ("FandolHei",),
        }),
    )
    for family, choices in selected_fonts:
        actual = [choice for choice in choices
                  if f"Proposal {family} font: {choice}" in log]
        if len(actual) != 1:
            raise ValueError(f"{pdf_file.name}: missing or ambiguous {family} font selection")
        if not any(token in name for name in font_names for token in choices[actual[0]]):
            raise ValueError(
                f"{pdf_file.name}: requested {family} font {actual[0]} not embedded in PDF"
            )

    html = capture("pdftotext", "-f", "1", "-l", "1", "-bbox", str(pdf_file), "-")
    root = ElementTree.fromstring(html)
    words = [("".join(tag.itertext()).strip(), float(tag.attrib["yMin"]),
              float(tag.attrib["yMax"])) for tag in root.iter() if tag.tag.endswith("}word")]
    chinese = [w for w in words if w[0] in {
        "开题报告中文标题第一行", "开题报告中文标题第二行"}]
    english = [w for w in words if w[0] in {
        "English", "Title", "of", "the", "Research", "Proposal", "Goes", "Here", "Extended", "Example"}]
    fields = [w for w in words if w[0] == "学院（系、所）名称"]

    if len(chinese) != 2 or len(english) != (8 if expected_english_lines == 3 else 10) or len(fields) != 1:
        raise ValueError(f"{pdf_file.name}: expected public title or field is missing")

    # Check local 22 pt, 1.5x line spacing and the separation of title blocks.
    chinese_tops = sorted(word[1] for word in chinese)
    english_tops = sorted({word[1] for word in english})
    if len(english_tops) != expected_english_lines:
        raise ValueError(f"{pdf_file.name}: expected {expected_english_lines} English title lines")
    chinese_leading = chinese_tops[1] - chinese_tops[0]
    english_leadings = [
        english_tops[i + 1] - english_tops[i] for i in range(expected_english_lines - 1)
    ]
    selected = set(re.findall(
        r"Proposal English title line stretch: (1\.5|1\.35|1\.2)", log
    ))
    if len(selected) != 1:
        raise ValueError(f"{pdf_file.name}: ambiguous English line-stretch selection")
    selected_stretch = float(next(iter(selected)))
    expected_leading = 22 * selected_stretch
    if not 32 <= chinese_leading <= 34 or any(
        abs(leading - expected_leading) > 1.5 for leading in english_leadings
    ):
        raise ValueError(
            f"{pdf_file.name}: incorrect cover title line spacing "
            f"(Chinese {chinese_leading:.1f}pt; "
            f"English {', '.join(f'{x:.1f}' for x in english_leadings)}pt)"
        )

    between_titles = min(w[1] for w in english) - max(w[2] for w in chinese)
    before_fields = fields[0][1] - max(w[2] for w in english)
    if not 20 <= between_titles <= 40 or before_fields < 20:
        raise ValueError(
            f"{pdf_file.name}: title areas too close "
            f"(Chinese/English gap {between_titles:.1f}pt; English/fields gap {before_fields:.1f}pt)"
        )
    print(f"PASS: {pdf_file.name} fonts and cover typography, "
          f"English line stretch {selected_stretch:g}, "
          f"line spacing {chinese_leading:.1f}pt / "
          f"{english_leadings[0]:.1f}pt, gaps "
          f"{between_titles:.1f}pt / {before_fields:.1f}pt")


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        raise SystemExit("Usage: check-cover-layout.py <example.pdf> <build.log> [English lines]")
    try:
        check(Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3]) if len(sys.argv) == 4 else 3)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        raise SystemExit(str(error)) from error
