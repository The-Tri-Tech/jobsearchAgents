from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, UserOut, UserUpdate, Token
from app.core.security import (
    verify_password,
    get_password_hash,
    create_access_token,
    decode_access_token,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()
security_optional = HTTPBearer(auto_error=False)

def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_optional),
    db: Session = Depends(get_db)
) -> User:
    """Return authenticated user, or default system user for seamless no-auth mode."""
    if credentials:
        try:
            user_id = decode_access_token(credentials.credentials)
            if user_id:
                user = db.query(User).filter(User.id == int(user_id)).first()
                if user:
                    return user
        except Exception:
            pass

    # Default user for no-auth mode
    user = db.query(User).first()
    if not user:
        user = User(
            id=1,
            email="student@skillbridge.ai",
            full_name="Student",
            hashed_password="local_no_auth_password",
            plan="Pro plan",
            avatar_letter="S",
        )
        db.add(user)
        try:
            db.commit()
            db.refresh(user)
        except Exception:
            db.rollback()
    return user

def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_optional),
    db: Session = Depends(get_db)
) -> Optional[User]:
    if not credentials:
        return None
    try:
        user_id = decode_access_token(credentials.credentials)
        if user_id:
            return db.query(User).filter(User.id == int(user_id)).first()
    except Exception:
        pass
    return None

@router.post("/signup", response_model=Token, status_code=status.HTTP_201_CREATED)
def signup(user_in: UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(User).filter(User.email == user_in.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email already exists.",
        )
    
    name = user_in.full_name.strip() if user_in.full_name else "Student"
    avatar = name[0].upper() if name else user_in.email[0].upper()
    
    new_user = User(
        email=user_in.email.lower().strip(),
        full_name=name,
        hashed_password=get_password_hash(user_in.password),
        plan="Pro plan",
        avatar_letter=avatar,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = create_access_token(subject=str(new_user.id))
    return Token(
        access_token=token,
        token_type="bearer",
        user=UserOut.model_validate(new_user),
    )

@router.post("/login", response_model=Token)
def login(user_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_in.email.lower().strip()).first()
    if not user or not verify_password(user_in.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    token = create_access_token(subject=str(user.id))
    return Token(
        access_token=token,
        token_type="bearer",
        user=UserOut.model_validate(user),
    )

@router.get("/me", response_model=UserOut)
def read_current_user(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserOut)
def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user_update.full_name is not None and user_update.full_name.strip():
        current_user.full_name = user_update.full_name.strip()
        current_user.avatar_letter = current_user.full_name[0].upper()
    if user_update.phone_number is not None:
        current_user.phone_number = user_update.phone_number.strip()
    if user_update.location is not None:
        current_user.location = user_update.location.strip()
    if user_update.target_role is not None:
        current_user.target_role = user_update.target_role.strip()
    if user_update.bio is not None:
        current_user.bio = user_update.bio.strip()
    if user_update.email is not None and user_update.email.strip():
        current_user.email = user_update.email.lower().strip()
    
    db.commit()
    db.refresh(current_user)
    return current_user


