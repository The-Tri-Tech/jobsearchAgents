# SkillBridge - AI Career OS

SkillBridge is an AI Career operating system featuring a **Flutter** frontend, **FastAPI** backend, and **PostgreSQL** database.

---

## 🏗️ Architecture

- **Backend**: FastAPI with Python 3.14, SQLAlchemy, Pydantic, Passlib (bcrypt), and python-jose (JWT).
- **Frontend**: Flutter Web & Desktop with Material 3, clean SaaS styling matching the SkillBridge design.
- **Database**: PostgreSQL (configured in `backend/.env`, with automatic fallback to SQLite for local development).

---

## 🚀 How to Run

### 1. Run the Backend (FastAPI)
In a terminal, navigate to the `backend` directory:
```powershell
cd backend
uv run python3 run.py
```
The API server will start on: **http://127.0.0.1:8000**
- API Documentation / Swagger: **http://127.0.0.1:8000/docs**
- Health check: **http://127.0.0.1:8000/health**

---

### 2. Run the Frontend (Flutter)
In another terminal, navigate to the `frontend` directory:

#### Run on Web (Chrome / Edge):
```powershell
cd frontend
flutter run -d chrome
```

#### Run on Windows Desktop:
```powershell
cd frontend
flutter run -d windows
```

---

## 🔑 Authentication & Testing Credentials
- **Pre-filled demo credentials**:
  - Email: `student@skillbridge.ai`
  - Password: `password123`
- You can also switch the tab to **Sign Up** to register a new account with your name, email, and password.
- Upon login, you are automatically redirected to the **SkillBridge Overview Dashboard** with all metric cards, progress tracking, and tasks.

