from datetime import timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.v1.auth import get_current_user
from app.db.session import get_db
from app.models.follow_up import FollowUp
from app.models.user import User
from app.schemas.follow_up import FollowUpCreate, FollowUpList, FollowUpOut

router = APIRouter(prefix="/follow-ups", tags=["Follow Ups"])


@router.post("", response_model=FollowUpOut, status_code=status.HTTP_201_CREATED)
def create_follow_up(
    payload: FollowUpCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    follow_up = FollowUp(
        user_id=current_user.id,
        report_title=payload.report_title.strip(),
        resume_filename=payload.resume_filename,
        application_date=payload.application_date,
        follow_up_after_days=payload.follow_up_after_days,
        follow_up_date=payload.application_date
        + timedelta(days=payload.follow_up_after_days),
        status="pending",
    )
    db.add(follow_up)
    db.commit()
    db.refresh(follow_up)
    return follow_up


@router.get("", response_model=FollowUpList)
def list_follow_ups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    follow_ups = (
        db.query(FollowUp)
        .filter(FollowUp.user_id == current_user.id, FollowUp.status == "pending")
        .order_by(FollowUp.follow_up_date.asc())
        .all()
    )
    return FollowUpList(follow_ups=follow_ups, count=len(follow_ups))


@router.put("/{follow_up_id}/toggle", response_model=FollowUpOut)
def toggle_follow_up(
    follow_up_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    follow_up = (
        db.query(FollowUp)
        .filter(FollowUp.id == follow_up_id, FollowUp.user_id == current_user.id)
        .first()
    )
    if not follow_up:
        raise HTTPException(status_code=404, detail="Follow-up not found")

    follow_up.status = "completed" if follow_up.status == "pending" else "pending"
    db.commit()
    db.refresh(follow_up)
    return follow_up


@router.delete("/{follow_up_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_follow_up(
    follow_up_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    follow_up = (
        db.query(FollowUp)
        .filter(FollowUp.id == follow_up_id, FollowUp.user_id == current_user.id)
        .first()
    )
    if not follow_up:
        raise HTTPException(status_code=404, detail="Follow-up not found")

    db.delete(follow_up)
    db.commit()
    return None
