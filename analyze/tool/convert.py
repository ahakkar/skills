# /// script
# requires-python = ">=3.11"
# dependencies = ["openpyxl", "python-docx", "python-pptx"]
# ///
"""Convert one document into text files that check_citations.py can cite by line.

Usage: uv run --no-project convert.py FILE OUT_DIR

The output file name says where in the document a citation points:
  PDF   p07.txt           one file per physical page. pdftotext reading order, not
                          -layout: -layout puts columns side by side, so a quote that
                          spans two lines never matches.
  PPTX  s03.txt           one file per slide; speaker notes after a "[notes]" line.
  XLSX  sheet02-Name.txt  one file per sheet; line N is row N: "A: … | C: …".
  DOCX  doc.txt           paragraphs and table rows in order; Word has no fixed pages.
Prints one line per output file, with a note for empty PDF pages and hidden sheets.
"""
import re
import subprocess
import sys
from pathlib import Path

from docx import Document
from openpyxl import load_workbook
from pptx import Presentation


def width(n: int) -> int:
    return len(str(n))


def pdf(path: Path):
    text = subprocess.run(
        ["pdftotext", "-q", str(path), "-"], capture_output=True, text=True, check=True
    ).stdout
    pages = text.split("\f")
    if pages and not pages[-1].strip():
        pages.pop()
    for i, page in enumerate(pages, 1):
        note = "" if page.strip() else "no text: an image? read it as one"
        yield f"p{i:0{width(len(pages))}d}.txt", page, note


def xlsx(path: Path):
    wb = load_workbook(path, data_only=True)
    for i, ws in enumerate(wb.worksheets, 1):
        lines = [
            " | ".join(
                f"{c.column_letter}: {' '.join(str(c.value).split())}"
                for c in row
                if c.value is not None and str(c.value).strip()
            )
            for row in ws.iter_rows()
        ]
        name = re.sub(r"[^\w-]+", "_", ws.title).strip("_")
        note = "" if ws.sheet_state == "visible" else ws.sheet_state
        yield f"sheet{i:0{width(len(wb.worksheets))}d}-{name}.txt", "\n".join(lines), note


def docx(path: Path):
    out = []
    for el in Document(path).element.body.iterchildren():
        tag = el.tag.rsplit("}", 1)[-1]
        if tag == "p":
            out.append("".join(t.text or "" for t in el.iter() if t.tag.endswith("}t")))
        elif tag == "tbl":
            for tr in el.iter():
                if tr.tag.endswith("}tr"):
                    cells = [
                        " ".join("".join(t.text or "" for t in tc.iter() if t.tag.endswith("}t")).split())
                        for tc in tr
                        if tc.tag.endswith("}tc")
                    ]
                    out.append("| " + " | ".join(cells) + " |")
    yield "doc.txt", "\n".join(out), ""


def shape_lines(shape):
    if shape.shape_type == 6:  # group
        for s in shape.shapes:
            yield from shape_lines(s)
    if shape.has_text_frame:
        for p in shape.text_frame.paragraphs:
            yield p.text.replace("\v", " ")
    if getattr(shape, "has_table", False) and shape.has_table:
        for row in shape.table.rows:
            yield "| " + " | ".join(" ".join(c.text.split()) for c in row.cells) + " |"


def pptx(path: Path):
    slides = Presentation(path).slides
    for i, slide in enumerate(slides, 1):
        lines = [line for s in slide.shapes for line in shape_lines(s)]
        notes = slide.notes_slide.notes_text_frame if slide.has_notes_slide else None
        if notes is not None and notes.text.strip():
            lines += ["[notes]", *notes.text.splitlines()]
        yield f"s{i:0{width(len(slides))}d}.txt", "\n".join(lines), ""


CONVERTERS = {".pdf": pdf, ".xlsx": xlsx, ".docx": docx, ".pptx": pptx}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    convert = CONVERTERS.get(src.suffix.lower())
    if convert is None:
        sys.exit(f"{src.suffix}: not supported. Cite .txt, .md and .csv files directly.")
    out.mkdir(parents=True, exist_ok=True)
    for name, text, note in convert(src):
        (out / name).write_text(text.rstrip() + "\n")
        print(f"{len(text.split()):7d} words  {out / name}" + (f"  ({note})" if note else ""))


if __name__ == "__main__":
    main()
