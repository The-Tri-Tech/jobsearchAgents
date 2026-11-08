import os
import re
from pathlib import Path
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from app.api.v1.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/resume", tags=["Resume"])

# Local storage directory (sibling of the backend folder: <project-root>/uploads/resumes)
UPLOAD_DIR = Path(__file__).resolve().parents[4] / "uploads" / "resumes"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {".pdf", ".doc", ".docx"}
ALLOWED_CONTENT_TYPES = {
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
}
MAX_FILE_SIZE_MB = 10


def _safe_filename(name: str) -> str:
    """Sanitise filename, including parentheses used by duplicate uploads."""
    name = name.strip()
    name = re.sub(r"[^\w.()\-]", "_", name)
    return name


def _unique_filename(directory: Path, filename: str) -> str:
    """
    If `filename` already exists in `directory`, append (1), (2), … before
    the extension until a free slot is found.
    """
    stem = Path(filename).stem
    suffix = Path(filename).suffix
    candidate = filename
    counter = 1
    while (directory / candidate).exists():
        candidate = f"{stem}({counter}){suffix}"
        counter += 1
    return candidate


# ── Upload ────────────────────────────────────────────────────────────────────
@router.post("/upload", status_code=status.HTTP_201_CREATED)
async def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    # Validate extension
    suffix = Path(file.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type '{suffix}'. Only PDF and DOCX/DOC are allowed.",
        )

    # Validate content-type header (best-effort)
    if file.content_type and file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid content type. Upload a PDF or Word document.",
        )

    # Read content and validate size
    content = await file.read()
    size_mb = len(content) / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds the {MAX_FILE_SIZE_MB} MB limit.",
        )

    # Build unique, safe filename
    safe_name = _safe_filename(file.filename or "resume" + suffix)
    unique_name = _unique_filename(UPLOAD_DIR, safe_name)
    dest = UPLOAD_DIR / unique_name

    dest.write_bytes(content)

    return {
        "filename": unique_name,
        "original_filename": file.filename,
        "size_bytes": len(content),
        "content_type": file.content_type,
        "url": f"/api/v1/resume/file/{unique_name}",
    }


# ── List ──────────────────────────────────────────────────────────────────────
@router.get("/list")
def list_resumes(current_user: User = Depends(get_current_user)):
    files = []
    for f in sorted(UPLOAD_DIR.iterdir()):
        if f.is_file() and f.suffix.lower() in ALLOWED_EXTENSIONS:
            stat = f.stat()
            files.append(
                {
                    "filename": f.name,
                    "size_bytes": stat.st_size,
                    "uploaded_at": stat.st_mtime,
                    "url": f"/api/v1/resume/file/{f.name}",
                }
            )
    return {"resumes": files, "count": len(files)}


# ── Serve file ────────────────────────────────────────────────────────────────
@router.get("/file/{filename}")
def get_resume_file(
    filename: str,
    current_user: User = Depends(get_current_user),
):
    # Prevent path-traversal
    safe = _safe_filename(filename)
    file_path = UPLOAD_DIR / safe
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found.")

    suffix = file_path.suffix.lower()
    media_type_map = {
        ".pdf": "application/pdf",
        ".doc": "application/msword",
        ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    }
    return FileResponse(
        path=str(file_path),
        media_type=media_type_map.get(suffix, "application/octet-stream"),
        filename=safe,
        headers={"Content-Disposition": f'inline; filename="{safe}"'},
    )


# ── Delete ────────────────────────────────────────────────────────────────────
@router.delete("/file/{filename}", status_code=status.HTTP_200_OK)
def delete_resume(
    filename: str,
    current_user: User = Depends(get_current_user),
):
    safe = _safe_filename(filename)
    file_path = UPLOAD_DIR / safe
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found.")
    file_path.unlink()
    return {"detail": f"'{safe}' deleted successfully."}
