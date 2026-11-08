from pathlib import Path

from docx import Document
from pypdf import PdfReader


class ResumeExtractionError(ValueError):
    pass


def extract_resume_text(path: Path) -> str:
    """Extract readable text from an uploaded PDF or DOCX resume."""
    suffix = path.suffix.lower()
    try:
        if suffix == ".pdf":
            text = "\n".join(page.extract_text() or "" for page in PdfReader(path).pages)
        elif suffix == ".docx":
            document = Document(path)
            paragraphs = [p.text for p in document.paragraphs]
            table_rows = [
                " | ".join(cell.text for cell in row.cells)
                for table in document.tables
                for row in table.rows
            ]
            text = "\n".join(paragraphs + table_rows)
        elif suffix == ".doc":
            raise ResumeExtractionError(
                "Legacy .doc files cannot be analysed. Re-upload this resume as PDF or DOCX."
            )
        else:
            raise ResumeExtractionError("Unsupported resume format.")
    except ResumeExtractionError:
        raise
    except Exception as exc:
        raise ResumeExtractionError(
            "The resume could not be read. Ensure it is a valid, non-encrypted document."
        ) from exc

    cleaned = "\n".join(line.strip() for line in text.splitlines() if line.strip())
    if len(cleaned) < 40:
        raise ResumeExtractionError(
            "No usable text was found in this resume. Upload a text-based PDF or DOCX."
        )
    return cleaned[:80_000]
