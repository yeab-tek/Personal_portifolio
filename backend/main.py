import os
import secrets
from dotenv import load_dotenv
from datetime import datetime, timedelta
from typing import List, Optional
import resend
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import jwt
from passlib.context import CryptContext


load_dotenv()

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY")
if not SECRET_KEY:
    # Falls back to a random key generated at startup so the app never runs
    # with a publicly-known secret. NOTE: this means tokens won't survive a
    # restart/redeploy unless you set SECRET_KEY yourself on Render.
    SECRET_KEY = secrets.token_urlsafe(32)
    print("⚠️  SECRET_KEY not set in environment — generated a temporary one for this run.")
    print("⚠️  Set SECRET_KEY in Render's Environment tab so tokens stay valid across restarts.")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 Hours

ADMIN_USERNAME = os.getenv("ADMIN_USERNAME", "yeabsira")

# Resend Email Configuration
resend.api_key = os.getenv("RESEND_API_KEY")
NOTIFY_EMAIL = os.getenv("NOTIFY_EMAIL")
RESEND_FROM = os.getenv("RESEND_FROM", "onboarding@resend.dev")

# Database Setup (SQLite for development, easily switchable to PostgreSQL)
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL is not set. Make sure a .env file exists next to this "
        "script (or the env var is set in your deployment environment) and "
        "that load_dotenv() can find it."
    )

if "postgresql" in DATABASE_URL and "pooler.supabase.com" in DATABASE_URL:
    if "postgres." not in DATABASE_URL.split("@")[0]:
        print(
            "WARNING: Supabase pooler connections require the username to be "
            "in the form 'postgres.<project-ref>', not just 'postgres'. "
            "Double check Settings -> Database -> Connection string in your "
            "Supabase dashboard."
        )

connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}

try:
    engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
    with engine.connect() as _conn:
        pass
except OperationalError as e:
    raise RuntimeError(
        "Could not connect to the database using DATABASE_URL. This is "
        "almost always a Supabase-side issue, not a code issue:\n"
        "  1. Confirm the project ref in the connection string matches your "
        "current Supabase project (Dashboard URL: "
        "supabase.com/dashboard/project/<ref>).\n"
        "  2. Check whether the project is paused (free tier auto-pauses "
        "after ~1 week idle) and restore it if so.\n"
        "  3. Re-copy the connection string fresh from Settings -> Database "
        "in the Supabase dashboard rather than reusing an old one.\n"
        f"Original error: {e}"
    ) from e

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Password Hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

# --- SQLAlchemy Database Models ---
class DBUser(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    password_hash = Column(String)

class DBProject(Base):
    __tablename__ = "projects"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    category = Column(String)
    company_tag = Column(String, nullable=True)
    description = Column(Text)
    tech_stack = Column(String)
    link = Column(String, nullable=True)

class DBMessage(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String)
    message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# Seed Initial Data if empty
def init_db():
    db = SessionLocal()
    if not db.query(DBUser).filter(DBUser.username == ADMIN_USERNAME).first():
        admin_password = os.getenv("ADMIN_INITIAL_PASSWORD")
        if not admin_password:
            admin_password = secrets.token_urlsafe(12)
            print(f"⚠️  No ADMIN_INITIAL_PASSWORD set. One-time generated admin password: {admin_password}")
            print("⚠️  Copy this from the logs now, log in, then change it via /api/auth/change-password.")
        admin_user = DBUser(
            username=ADMIN_USERNAME,
            password_hash=pwd_context.hash(admin_password)
        )
        db.add(admin_user)

    if db.query(DBProject).count() == 0:
        initial_projects = [
            DBProject(
                title="OmniScan — Coffee Export Management",
                category="dev",
                company_tag="Client: LATA AGRI EXPORT (ALTA Computec PLC engagement)",
                description="Full-stack enterprise application for coffee export operations. Integrated OCR document scanning with AI-driven data extraction, FastAPI async backend, SQLAlchemy, Pydantic, and React/TypeScript analytics dashboard.",
                tech_stack="FastAPI, React, TypeScript, PostgreSQL, OCR AI",
                link=""
            ),
            DBProject(
                title="Vibey Hub",
                category="dev",
                company_tag="Personal Full-Stack Social Platform",
                description="A feature-rich social platform with secure user registration, post creation, JWT authentication, responsive mobile/desktop layout, and real-time data persistence with Supabase and Express backend.",
                tech_stack="React, Node.js, Express, Supabase, JWT",
                link="https://github.com/yeab-tek/vibey_hub"
            ),
            DBProject(
                title="Cinematic Visuals & Video Production",
                category="media",
                company_tag="Yeab's Production & Commercial Work",
                description="High-end post-production, video editing, color grading, and camera direction using Adobe Premiere Pro, After Effects, and Sony cinema camera setups for brand campaigns and documentaries.",
                tech_stack="Premiere Pro, After Effects, Color Grading, Sony Cinema",
                link=""
            )
        ]
        db.add_all(initial_projects)
    db.commit()
    db.close()

init_db()

# --- Pydantic Schemas ---
class Token(BaseModel):
    access_token: str
    token_type: str

class ProjectSchema(BaseModel):
    id: Optional[int] = None
    title: str
    category: str
    company_tag: Optional[str] = None
    description: str
    tech_stack: str
    link: Optional[str] = None

    class Config:
        from_attributes = True

class ContactMessageSchema(BaseModel):
    name: str
    email: EmailStr
    message: str

class ChangePasswordSchema(BaseModel):
    current_password: str
    new_password: str

# FastAPI Application
app = FastAPI(title="Yeabsira Teklu Cinematic Portfolio API", version="2.0.0")

ALLOWED_ORIGINS = os.getenv(
    "ALLOWED_ORIGINS",
    "http://localhost:5173,https://personal-portifolio-black.vercel.app"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Auth Utilities
def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")

    user = db.query(DBUser).filter(DBUser.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# Email Sending Utility (via Resend)
def send_email_notification(name: str, email: str, message_body: str):
    if not resend.api_key or not NOTIFY_EMAIL:
        print("Resend not configured: RESEND_API_KEY or NOTIFY_EMAIL missing.")
        return False

    html_body = f"""
    <div style="font-family: Arial, sans-serif; background: #0b0f17; color: #f1f5f9; padding: 20px;">
        <h2 style="color: #2dd4bf;">New Hire Me Inquiry</h2>
        <p><strong>Name:</strong> {name}</p>
        <p><strong>Email:</strong> {email}</p>
        <p><strong>Message:</strong></p>
        <blockquote style="background: #1e293b; padding: 15px; border-left: 4px solid #f59e0b;">{message_body}</blockquote>
    </div>
    """

    try:
        resend.Emails.send({
            "from": RESEND_FROM,
            "to": NOTIFY_EMAIL,
            "subject": f"New Portfolio Inquiry from {name}",
            "html": html_body,
        })
        return True
    except Exception as e:
        print("Resend email sending error:", e)
        return False

# --- ROUTES ---

@app.get("/api/projects", response_model=List[ProjectSchema])
def get_projects(db: Session = Depends(get_db)):
    return db.query(DBProject).all()

@app.post("/api/contact")
def submit_contact(msg: ContactMessageSchema, db: Session = Depends(get_db)):
    db_msg = DBMessage(name=msg.name, email=msg.email, message=msg.message)
    db.add(db_msg)
    db.commit()

    email_sent = send_email_notification(msg.name, msg.email, msg.message)

    return {
        "success": True,
        "message": "Thank you for reaching out! Your message has been received.",
        "email_sent": email_sent
    }

@app.post("/api/auth/login", response_model=Token)
def login_admin(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(DBUser).filter(DBUser.username == form_data.username).first()
    if not user or not pwd_context.verify(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/auth/change-password")
def change_password(
    payload: ChangePasswordSchema,
    admin: DBUser = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    if not pwd_context.verify(payload.current_password, admin.password_hash):
        raise HTTPException(status_code=401, detail="Current password is incorrect")
    admin.password_hash = pwd_context.hash(payload.new_password)
    db.commit()
    return {"success": True, "message": "Password updated successfully"}

@app.post("/api/admin/projects", response_model=ProjectSchema)
def add_project(
    project: ProjectSchema,
    admin: DBUser = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    db_project = DBProject(
        title=project.title,
        category=project.category,
        company_tag=project.company_tag,
        description=project.description,
        tech_stack=project.tech_stack,
        link=project.link
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

@app.put("/api/admin/projects/{project_id}", response_model=ProjectSchema)
def update_project(
    project_id: int,
    project: ProjectSchema,
    admin: DBUser = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    db_proj = db.query(DBProject).filter(DBProject.id == project_id).first()
    if not db_proj:
        raise HTTPException(status_code=404, detail="Project not found")

    db_proj.title = project.title
    db_proj.category = project.category
    db_proj.company_tag = project.company_tag
    db_proj.description = project.description
    db_proj.tech_stack = project.tech_stack
    db_proj.link = project.link

    db.commit()
    db.refresh(db_proj)
    return db_proj

@app.delete("/api/admin/projects/{project_id}")
def delete_project(
    project_id: int,
    admin: DBUser = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    db_proj = db.query(DBProject).filter(DBProject.id == project_id).first()
    if not db_proj:
        raise HTTPException(status_code=404, detail="Project not found")
    db.delete(db_proj)
    db.commit()
    return {"success": True, "message": "Project deleted successfully"}

@app.get("/api/admin/messages")
def get_messages(
    admin: DBUser = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return db.query(DBMessage).order_by(DBMessage.created_at.desc()).all()

frontend_path = os.path.join(os.path.dirname(__file__), "..", "frontend")
if os.path.exists(frontend_path):
    app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")