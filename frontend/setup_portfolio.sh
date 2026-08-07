#!/usr/bin/env bash

echo "🚀 Setting up Yeabsira Teklu Full-Stack Cinematic Portfolio..."

# 1. Create Directory Structure
mkdir -p backend
mkdir -p frontend/public
mkdir -p frontend/src/components

# 2. Write Backend Files
cat << 'MAINPY' > backend/main.py
import os
import smtplib
from datetime import datetime, timedelta
from typing import List, Optional
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, EmailStr
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import jwt
from passlib.context import CryptContext

SECRET_KEY = os.getenv("SECRET_KEY", "yeabsira_fastapi_cinematic_secret_2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./portfolio.db")
engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

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

def init_db():
    db = SessionLocal()
    if not db.query(DBUser).filter(DBUser.username == "yeabsira").first():
        admin_user = DBUser(username="yeabsira", password_hash=pwd_context.hash("yeab1234"))
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

app = FastAPI(title="Yeabsira Teklu Cinematic Portfolio API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    user = db.query(DBUser).filter(DBUser.username == username).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def send_email_notification(name: str, email: str, message_body: str):
    smtp_host = os.getenv("SMTP_HOST", "smtp.gmail.com")
    smtp_user = os.getenv("SMTP_USER", "")
    smtp_pass = os.getenv("SMTP_PASS", "")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    target_email = os.getenv("NOTIFICATION_EMAIL", "yeabtek7@gmail.com")

    if smtp_host and smtp_user and smtp_pass:
        try:
            msg = MIMEMultipart()
            msg["From"] = smtp_user
            msg["To"] = target_email
            msg["Subject"] = f"New Portfolio Message from {name}"
            html_body = f"<h2>New Message</h2><p><b>Name:</b> {name}</p><p><b>Email:</b> {email}</p><p>{message_body}</p>"
            msg.attach(MIMEText(html_body, "html"))
            server = smtplib.SMTP(smtp_host, smtp_port)
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.sendmail(smtp_user, target_email, msg.as_string())
            server.quit()
            return True
        except Exception as e:
            print("Email Error:", e)
            return False
    return False

@app.get("/api/projects", response_model=List[ProjectSchema])
def get_projects(db: Session = Depends(get_db)):
    return db.query(DBProject).all()

@app.post("/api/contact")
def submit_contact(msg: ContactMessageSchema, db: Session = Depends(get_db)):
    db_msg = DBMessage(name=msg.name, email=msg.email, message=msg.message)
    db.add(db_msg)
    db.commit()
    email_sent = send_email_notification(msg.name, msg.email, msg.message)
    return {"success": True, "message": "Thank you for reaching out! Message received.", "email_sent": email_sent}

@app.post("/api/auth/login", response_model=Token)
def login_admin(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(DBUser).filter(DBUser.username == form_data.username).first()
    if not user or not pwd_context.verify(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token = create_access_token(data={"sub": user.username})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/api/admin/projects", response_model=ProjectSchema)
def add_project(project: ProjectSchema, admin: DBUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    db_project = DBProject(
        title=project.title, category=project.category, company_tag=project.company_tag,
        description=project.description, tech_stack=project.tech_stack, link=project.link
    )
    db.add(db_project)
    db.commit()
    db.refresh(db_project)
    return db_project

@app.delete("/api/admin/projects/{project_id}")
def delete_project(project_id: int, admin: DBUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    db_proj = db.query(DBProject).filter(DBProject.id == project_id).first()
    if not db_proj:
        raise HTTPException(status_code=404, detail="Project not found")
    db.delete(db_proj)
    db.commit()
    return {"success": True, "message": "Project deleted"}

@app.get("/api/admin/messages")
def get_messages(admin: DBUser = Depends(get_current_admin), db: Session = Depends(get_db)):
    return db.query(DBMessage).order_by(DBMessage.created_at.desc()).all()
MAINPY

cat << 'REQ' > backend/requirements.txt
fastapi>=0.100.0
uvicorn[standard]>=0.22.0
sqlalchemy>=2.0.0
pydantic>=2.0.0
pyjwt>=2.7.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6
REQ

# 3. Write Frontend Files
cat << 'PKG' > frontend/package.json
{
  "name": "yeabsira-cinematic-react-portfolio",
  "private": true,
  "version": "2.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "start": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.2.0"
  }
}
PKG

cat << 'VITE' > frontend/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})
VITE

cat << 'HTML' > frontend/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Yeabsira Teklu | Full Stack Developer & Visual Storyteller</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;600&family=Inter:wght@300;400;600;700;800&display=swap" rel="stylesheet">
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
HTML

cat << 'CSS' > frontend/src/index.css
:root {
  --bg-dark: #0b0f17;
  --bg-card: rgba(15, 23, 42, 0.75);
  --bg-terminal: #0f172a;
  --bg-alt: #080c14;
  --text-main: #f1f5f9;
  --text-muted: #94a3b8;
  --teal: #2dd4bf;
  --teal-glow: #5eead4;
  --gold: #f59e0b;
  --gold-glow: #fbbf24;
  --accent-purple: #c084fc;
  --accent-green: #4ade80;
  --border-glass: rgba(255, 255, 255, 0.08);
  --font-heading: 'Inter', sans-serif;
  --font-code: 'Fira Code', monospace;
}

* { margin: 0; padding: 0; box-sizing: border-box; scroll-behavior: smooth; }

body {
  background-color: var(--bg-dark);
  color: var(--text-main);
  font-family: var(--font-heading);
  line-height: 1.6;
  overflow-x: hidden;
}

a { color: inherit; text-decoration: none; }
.teal-text { color: var(--teal); }
.gold-text { color: var(--gold); }
.purple-text { color: var(--accent-purple); }
.green-text { color: var(--accent-green); }

.cinematic-bg {
  position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; z-index: -1;
  background: radial-gradient(circle at 50% 20%, #111827 0%, #0b0f17 80%);
}

.glow-orb { position: absolute; border-radius: 50%; filter: blur(120px); opacity: 0.12; }
.orb-1 { width: 500px; height: 500px; background: var(--teal); top: -100px; right: -100px; }
.orb-2 { width: 600px; height: 600px; background: var(--gold); bottom: -150px; left: -150px; }

.glass {
  background: var(--bg-card);
  backdrop-filter: blur(12px);
  border: 1px solid var(--border-glass);
  border-radius: 12px;
  padding: 2rem;
}

.container { max-width: 1100px; margin: 0 auto; padding: 0 1.5rem; }
.section { padding: 6rem 0; }
.alt-bg { background: var(--bg-alt); }
.section-title { font-size: 2rem; margin-bottom: 2.5rem; font-weight: 700; }

.navbar {
  display: flex; justify-content: space-between; align-items: center;
  padding: 1.2rem 5%; position: fixed; top: 0; width: 100%;
  background: rgba(11, 15, 23, 0.85); backdrop-filter: blur(12px); z-index: 1000;
  border-bottom: 1px solid var(--border-glass);
}

.logo { font-family: var(--font-code); font-size: 1.1rem; font-weight: 600; }
.nav-links { display: flex; list-style: none; gap: 2rem; align-items: center; }
.nav-links a { font-size: 0.95rem; color: var(--text-muted); }
.nav-links a:hover { color: var(--teal); }

.btn-teal-sm {
  background: var(--teal); color: #000 !important; padding: 0.5rem 1.2rem;
  border-radius: 6px; font-weight: 700; font-size: 0.85rem; cursor: pointer; border: none;
}

.btn-action {
  display: inline-flex; align-items: center; gap: 0.6rem; padding: 0.85rem 1.6rem;
  border-radius: 8px; font-weight: 700; font-size: 0.95rem; cursor: pointer; border: none;
}
.btn-teal { background: var(--teal); color: #000; }
.btn-gold { background: var(--gold); color: #000; }
.btn-outline { background: transparent; border: 1px solid rgba(255, 255, 255, 0.2); color: var(--text-main); }

.hero { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 7rem 5% 4rem; }
.hero-wrapper { display: grid; grid-template-columns: 320px 1fr; gap: 2.5rem; max-width: 1100px; width: 100%; align-items: center; }

.hero-photo-card { padding: 1.2rem; border-radius: 16px; text-align: center; }
.photo-container { position: relative; border-radius: 12px; overflow: hidden; border: 1px solid rgba(45, 212, 191, 0.3); }
.hero-profile-img { width: 100%; height: 380px; object-fit: cover; display: block; }

.status-badge {
  position: absolute; bottom: 12px; left: 50%; transform: translateX(-50%);
  background: rgba(15, 23, 42, 0.9); border: 1px solid var(--border-glass);
  padding: 0.4rem 1rem; border-radius: 20px; font-size: 0.8rem; display: flex; align-items: center; gap: 0.5rem;
}
.status-dot { width: 8px; height: 8px; background-color: var(--accent-green); border-radius: 50%; }

.terminal-card { border-radius: 16px; overflow: hidden; background: var(--bg-terminal); border: 1px solid rgba(255, 255, 255, 0.1); }
.terminal-header { background: #090d16; padding: 0.8rem 1.2rem; display: flex; align-items: center; border-bottom: 1px solid var(--border-glass); position: relative; }
.traffic-lights { display: flex; gap: 0.5rem; }
.dot { width: 12px; height: 12px; border-radius: 50%; }
.dot.red { background: #ff5f56; }
.dot.yellow { background: #ffbd2e; }
.dot.green { background: #27c93f; }
.terminal-title { position: absolute; left: 50%; transform: translateX(-50%); font-family: var(--font-code); font-size: 0.85rem; color: var(--text-muted); }
.terminal-body { padding: 2.2rem; }
.terminal-name { font-size: 2.8rem; font-weight: 800; margin-bottom: 0.5rem; }
.terminal-subtitle { font-family: var(--font-code); font-size: 1.1rem; color: var(--gold); margin-bottom: 1.5rem; }

.code-graphic-box { background: #090d16; border-radius: 8px; padding: 1.2rem; font-family: var(--font-code); font-size: 0.88rem; margin-bottom: 2rem; }
.code-line { margin-bottom: 0.3rem; }
.code-line.indent { padding-left: 1.5rem; }
.hero-actions { display: flex; flex-wrap: wrap; gap: 1rem; }

.projects-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 2rem; }
.project-card { display: flex; flex-direction: column; justify-content: space-between; }
.project-tag { font-size: 0.75rem; color: var(--teal); text-transform: uppercase; margin-bottom: 0.5rem; }
.company-tag { font-size: 0.85rem; color: var(--gold); margin-bottom: 0.8rem; }
.tech-stack { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 1rem; }
.tech-stack span { background: rgba(255, 255, 255, 0.05); padding: 0.2rem 0.6rem; border-radius: 4px; font-size: 0.8rem; color: var(--text-muted); }

.grid-2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 2rem; }
.skill-bar-group { margin-bottom: 1.4rem; }
.skill-info { display: flex; justify-content: space-between; font-size: 0.9rem; margin-bottom: 0.4rem; }
.progress-track { width: 100%; height: 8px; background: rgba(255, 255, 255, 0.08); border-radius: 10px; overflow: hidden; }
.progress-fill { height: 100%; border-radius: 10px; }
.progress-fill.fill-teal { background: linear-gradient(90deg, var(--teal) 0%, var(--teal-glow) 100%); }
.progress-fill.fill-gold { background: linear-gradient(90deg, var(--gold) 0%, var(--gold-glow) 100%); }

.form-group { margin-bottom: 1.2rem; }
.form-group label { display: block; font-size: 0.85rem; color: var(--text-muted); margin-bottom: 0.4rem; }
.form-group input, .form-group textarea, .form-group select {
  width: 100%; padding: 0.8rem; background: rgba(0, 0, 0, 0.3); border: 1px solid var(--border-glass);
  border-radius: 6px; color: var(--text-main); font-family: var(--font-heading);
}
.width-100 { width: 100%; }

.fade-in-section {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1), transform 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}
.fade-in-section.is-visible {
  opacity: 1;
  transform: translateY(0);
}

@media (max-width: 900px) {
  .hero-wrapper { grid-template-columns: 1fr; }
  .nav-links { display: none; }
}
CSS

cat << 'MAINJSX' > frontend/src/main.jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
MAINJSX

cat << 'FADEIN' > frontend/src/components/FadeIn.jsx
import React, { useState, useEffect, useRef } from 'react';

export default function FadeIn({ children }) {
  const [isVisible, setIsVisible] = useState(false);
  const domRef = useRef();

  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      });
    }, { threshold: 0.15 });

    const currentRef = domRef.current;
    if (currentRef) observer.observe(currentRef);

    return () => {
      if (currentRef) observer.unobserve(currentRef);
    };
  }, []);

  return (
    <div ref={domRef} className={`fade-in-section ${isVisible ? 'is-visible' : ''}`}>
      {children}
    </div>
  );
}
FADEIN

cat << 'NAVBAR' > frontend/src/components/Navbar.jsx
import React from 'react';

export default function Navbar({ onOpenAdmin }) {
  return (
    <nav className="navbar">
      <div className="logo">
        <span className="teal-text">&lt;</span>YEABSIRA<span className="gold-text">.TEKLU</span><span className="teal-text"> /&gt;</span>
      </div>
      <ul className="nav-links">
        <li><a href="#hero">Home</a></li>
        <li><a href="#about">About</a></li>
        <li><a href="#projects">Work</a></li>
        <li><a href="#skills">Skills</a></li>
        <li><a href="#experience">Experience</a></li>
        <li>
          <a href="/Yeabsira_Teklu_CV.pdf" download className="btn-teal-sm">
            Download CV
          </a>
        </li>
        <li>
          <button onClick={onOpenAdmin} className="btn-teal-sm" style={{ background: 'transparent', border: '1px solid var(--teal)', color: 'var(--teal)' }}>
            Admin Portal
          </button>
        </li>
      </ul>
    </nav>
  );
}
NAVBAR

cat << 'HERO' > frontend/src/components/Hero.jsx
import React, { useState, useEffect } from 'react';

export default function Hero() {
  const roles = [
    "Full Stack Web Developer",
    "Cinematographer & Video Editor",
    "React & Node.js Engineer",
    "FastAPI & PostgreSQL Specialist",
    "After Effects & Motion Visualist"
  ];

  const [text, setText] = useState('');
  const [roleIdx, setRoleIndex] = useState(0);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const currentRole = roles[roleIdx];
    let timer;

    if (!isDeleting && text.length < currentRole.length) {
      timer = setTimeout(() => {
        setText(currentRole.substring(0, text.length + 1));
      }, 90);
    } else if (!isDeleting && text.length === currentRole.length) {
      timer = setTimeout(() => setIsDeleting(true), 2000);
    } else if (isDeleting && text.length > 0) {
      timer = setTimeout(() => {
        setText(currentRole.substring(0, text.length - 1));
      }, 45);
    } else if (isDeleting && text.length === 0) {
      setIsDeleting(false);
      setRoleIndex((prev) => (prev + 1) % roles.length);
    }

    return () => clearTimeout(timer);
  }, [text, isDeleting, roleIdx]);

  return (
    <section id="hero" className="hero">
      <div className="hero-wrapper">
        <div className="hero-photo-card glass">
          <div className="photo-container">
            <img src="/profile.jpg" alt="Yeabsira Teklu" className="hero-profile-img" onError={(e) => { e.target.src = 'https://ui-avatars.com/api/?name=Yeabsira+Teklu&background=2dd4bf&color=000&size=300'; }} />
            <div className="status-badge">
              <span className="status-dot"></span> Available for work
            </div>
          </div>
        </div>

        <div className="terminal-card glass">
          <div className="terminal-header">
            <div className="traffic-lights">
              <span className="dot red"></span>
              <span className="dot yellow"></span>
              <span className="dot green"></span>
            </div>
            <div className="terminal-title">whoami.sh</div>
          </div>
          <div className="terminal-body">
            <h1 className="terminal-name">Yeabsira Teklu<span className="teal-text">█</span></h1>
            <div className="terminal-subtitle">
              <span className="gold-text">&gt; </span>{text}<span className="teal-text">|</span>
            </div>

            <div className="code-graphic-box">
              <div className="code-line"><span className="purple-text">const</span> developer = &#123;</div>
              <div className="code-line indent">role: <span className="green-text">'Full Stack Web & Mobile'</span>,</div>
              <div className="code-line indent">stack: [<span className="green-text">'React'</span>, <span className="green-text">'FastAPI'</span>, <span className="green-text">'Node'</span>, <span className="green-text">'PostgreSQL'</span>],</div>
              <div className="code-line indent">media: [<span className="green-text">'Cinematography'</span>, <span className="green-text">'After Effects VFX'</span>]</div>
              <div className="code-line">&#125;;</div>
            </div>

            <div className="hero-actions">
              <a href="/Yeabsira_Teklu_CV.pdf" download className="btn-action btn-teal">
                ↓ Download CV
              </a>
              <a href="#contact" className="btn-action btn-gold">
                🤝 Hire Me
              </a>
              <a href="#experience" className="btn-action btn-outline">
                ↓ View Experience
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
HERO

cat << 'ABOUT' > frontend/src/components/About.jsx
import React from 'react';

export default function About() {
  return (
    <section id="about" className="section">
      <div className="container">
        <h2 className="section-title"><span className="teal-text">01.</span> About Me</h2>
        <div className="about-grid">
          <div className="about-text glass">
            <p>
              I am a <strong>Full Stack Web Developer</strong> and Computer Science student at Admas University in Addis Ababa, Ethiopia. I specialize in building responsive, enterprise-grade web applications using <strong>React, Node.js, Express, Supabase, and PostgreSQL</strong>.
            </p>
            <p>
              Beyond writing clean, efficient code, I am a <strong>cinematographer and video editor</strong> skilled in Adobe Premiere Pro, After Effects, and cinema camera operations. Whether designing complex RESTful APIs and secure JWT auth systems or crafting cinematic visual narratives, I bring precision, creativity, and technical depth to every project.
            </p>
          </div>
          <div className="about-card glass">
            <h3 style={{ marginBottom: '1rem', color: 'var(--teal)' }}>Quick Bio Matrix</h3>
            <ul style={{ listStyle: 'none' }}>
              <li style={{ padding: '0.6rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}><strong>Location:</strong> Addis Ababa, Ethiopia</li>
              <li style={{ padding: '0.6rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}><strong>Education:</strong> B.Sc. Computer Science (Admas Univ)</li>
              <li style={{ padding: '0.6rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}><strong>Certification:</strong> Full Stack Web Dev (Grace Academy)</li>
              <li style={{ padding: '0.6rem 0' }}><strong>Status:</strong> <span className="teal-text">● Available for Work</span></li>
            </ul>
          </div>
        </div>
      </div>
    </section>
  );
}
ABOUT

cat << 'PROJECTS' > frontend/src/components/Projects.jsx
import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:8000';

export default function Projects() {
  const [projects, setProjects] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetch(`${API_BASE}/api/projects`)
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) setProjects(data);
      })
      .catch(() => {
        setProjects([
          {
            id: 1,
            title: "OmniScan — Coffee Export Management",
            category: "dev",
            company_tag: "Client: LATA AGRI EXPORT (ALTA Computec PLC engagement)",
            description: "Full-stack enterprise application for coffee export operations. Integrated OCR document scanning with AI-driven data extraction, FastAPI async backend, SQLAlchemy, Pydantic, and React/TypeScript analytics dashboard.",
            tech_stack: "FastAPI, React, TypeScript, PostgreSQL, OCR AI"
          },
          {
            id: 2,
            title: "Vibey Hub",
            category: "dev",
            company_tag: "Personal Full-Stack Social Platform",
            description: "A feature-rich social platform with secure user registration, post creation, JWT authentication, responsive mobile/desktop layout, and real-time data persistence with Supabase and Express backend.",
            tech_stack: "React, Node.js, Express, Supabase, JWT",
            link: "https://github.com/yeab-tek/vibey_hub"
          },
          {
            id: 3,
            title: "Cinematic Visuals & Video Production",
            category: "media",
            company_tag: "Yeab's Production & Commercial Work",
            description: "High-end post-production, video editing, color grading, and camera direction using Adobe Premiere Pro, After Effects, and Sony cinema camera setups for brand campaigns and documentaries.",
            tech_stack: "Premiere Pro, After Effects, Color Grading, Sony Cinema"
          }
        ]);
      });
  }, []);

  const filteredProjects = projects.filter(p => filter === 'all' || p.category === filter);

  return (
    <section id="projects" className="section alt-bg">
      <div className="container">
        <h2 className="section-title"><span className="teal-text">02.</span> Selected Work</h2>
        
        <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem' }}>
          <button className={`btn-action ${filter === 'all' ? 'btn-teal' : 'btn-outline'}`} onClick={() => setFilter('all')}>All</button>
          <button className={`btn-action ${filter === 'dev' ? 'btn-teal' : 'btn-outline'}`} onClick={() => setFilter('dev')}>Full-Stack Dev</button>
          <button className={`btn-action ${filter === 'media' ? 'btn-teal' : 'btn-outline'}`} onClick={() => setFilter('media')}>Cinematography & Video</button>
        </div>

        <div className="projects-grid">
          {filteredProjects.map((p) => (
            <div key={p.id} className="project-card glass">
              <div>
                <div className="project-tag">{p.category === 'dev' ? 'Full-Stack Dev' : 'Cinematic Media'}</div>
                <h3>{p.title}</h3>
                {p.company_tag && <p className="company-tag">{p.company_tag}</p>}
                <p>{p.description}</p>
              </div>
              <div>
                <div className="tech-stack">
                  {p.tech_stack && p.tech_stack.split(',').map((t, idx) => <span key={idx}>{t.trim()}</span>)}
                </div>
                {p.link && (
                  <div style={{ marginTop: '1rem' }}>
                    <a href={p.link} target="_blank" rel="noopener noreferrer" className="teal-text" style={{ fontWeight: 600 }}>
                      View Repository →
                    </a>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
PROJECTS

cat << 'SKILLS' > frontend/src/components/SkillGraphs.jsx
import React from 'react';

export default function SkillGraphs() {
  const devSkills = [
    { name: "React.js & Frontend Architecture", level: 92 },
    { name: "Node.js & Express.js", level: 90 },
    { name: "Python & FastAPI", level: 85 },
    { name: "PostgreSQL & Supabase Architecture", level: 88 },
    { name: "JWT Authentication & RESTful APIs", level: 95 }
  ];

  const mediaSkills = [
    { name: "Adobe Premiere Pro (Video Editing)", level: 95 },
    { name: "Adobe After Effects (Motion & VFX)", level: 90 },
    { name: "Camera Operations (DSLR / Mirrorless / Drone)", level: 92 },
    { name: "Color Grading & Sound Mixing", level: 88 },
    { name: "Visual Storytelling & Direction", level: 94 }
  ];

  return (
    <section id="skills" className="section">
      <div className="container">
        <h2 className="section-title"><span className="teal-text">03.</span> Technical Skill Graphs</h2>
        <div className="grid-2">
          <div className="glass">
            <h3 style={{ marginBottom: '1.5rem' }}><span className="teal-text">&lt;/&gt;</span> Software & Full-Stack Proficiency</h3>
            {devSkills.map((s, idx) => (
              <div key={idx} className="skill-bar-group">
                <div className="skill-info">
                  <span>{s.name}</span>
                  <span className="teal-text" style={{ fontWeight: 700 }}>{s.level}%</span>
                </div>
                <div className="progress-track">
                  <div className="progress-fill fill-teal" style={{ width: `${s.level}%` }}></div>
                </div>
              </div>
            ))}
          </div>

          <div className="glass">
            <h3 style={{ marginBottom: '1.5rem' }}><span className="gold-text">🎬</span> Cinematography & Video Post Graph</h3>
            {mediaSkills.map((s, idx) => (
              <div key={idx} className="skill-bar-group">
                <div className="skill-info">
                  <span>{s.name}</span>
                  <span className="gold-text" style={{ fontWeight: 700 }}>{s.level}%</span>
                </div>
                <div className="progress-track">
                  <div className="progress-fill fill-gold" style={{ width: `${s.level}%` }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
SKILLS

cat << 'EXP' > frontend/src/components/Experience.jsx
import React from 'react';

export default function Experience() {
  return (
    <section id="experience" className="section alt-bg">
      <div className="container">
        <h2 className="section-title"><span className="teal-text">04.</span> Experience & Credentials</h2>
        <div style={{ borderLeft: '2px solid var(--teal)', paddingLeft: '2rem', display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <div className="glass">
            <div style={{ fontSize: '0.85rem', color: 'var(--teal)' }}>Feb 2026 – Present</div>
            <h3>Full Stack Developer (Contract)</h3>
            <h4 style={{ color: 'var(--gold)', marginBottom: '0.5rem' }}>ALTA Computec PLC (Client: LATA AGRI EXPORT)</h4>
            <p style={{ color: 'var(--text-muted)' }}>Developed OmniScan enterprise system covering OCR document extraction, FastAPI backend, and React analytics dashboard.</p>
          </div>
          <div className="glass">
            <div style={{ fontSize: '0.85rem', color: 'var(--teal)' }}>Certified 2025</div>
            <h3>Full Stack Web Development</h3>
            <h4 style={{ color: 'var(--gold)', marginBottom: '0.5rem' }}>Grace Academy</h4>
            <p style={{ color: 'var(--text-muted)' }}>Completed intensive training in full-stack architecture, React, Node.js, databases, and secure web application development.</p>
          </div>
          <div className="glass">
            <div style={{ fontSize: '0.85rem', color: 'var(--teal)' }}>In Progress</div>
            <h3>B.Sc. in Computer Science</h3>
            <h4 style={{ color: 'var(--gold)', marginBottom: '0.5rem' }}>Admas University, Addis Ababa</h4>
            <p style={{ color: 'var(--text-muted)' }}>Advanced studies in algorithms, database management, software engineering, and web development.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
EXP

cat << 'CONTACT' > frontend/src/components/Contact.jsx
import React, { useState } from 'react';

const API_BASE = 'http://localhost:8000';

export default function Contact() {
  const [formData, setFormData] = useState({ name: '', email: '', message: '' });
  const [status, setStatus] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setStatus('Sending message...');

    try {
      const res = await fetch(`${API_BASE}/api/contact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (res.ok) {
        setStatus(data.message || 'Message received! I will get back to you shortly.');
        setFormData({ name: '', email: '', message: '' });
      } else {
        setStatus(data.detail || 'Failed to send message.');
      }
    } catch (err) {
      setStatus('Message received! Thank you for reaching out.');
      setFormData({ name: '', email: '', message: '' });
    }
  };

  return (
    <section id="contact" className="section">
      <div className="container">
        <h2 className="section-title"><span className="teal-text">05.</span> Let's Build Together</h2>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: '2.5rem' }} className="glass">
          <div>
            <h3>Get In Touch</h3>
            <p style={{ color: 'var(--text-muted)', marginBottom: '1.5rem' }}>
              Have a full-stack web project, custom web app, or cinematic media production in mind? Let's discuss how we can bring it to life.
            </p>
            <ul style={{ listStyle: 'none' }}>
              <li style={{ padding: '0.6rem 0' }}>
                <a href="mailto:yeabtek7@gmail.com" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem' }}>
                  📧 yeabtek7@gmail.com
                </a>
              </li>
              <li style={{ padding: '0.6rem 0' }}>
                <a href="tel:+251963008735" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', fontWeight: 600 }}>
                  📞 +251 963 008 735
                </a>
              </li>
              <li style={{ padding: '0.6rem 0' }}>
                <a href="https://maps.google.com/?q=Addis+Ababa,+Ethiopia" target="_blank" rel="noopener noreferrer" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem' }}>
                  📍 Addis Ababa, Ethiopia
                </a>
              </li>
              <li style={{ padding: '0.6rem 0' }}>
                <a href="https://github.com/yeab-tek" target="_blank" rel="noopener noreferrer" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem' }}>
                  🔗 github.com/yeab-tek
                </a>
              </li>
            </ul>
          </div>

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Your Name</label>
              <input type="text" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} placeholder="John Doe" required />
            </div>
            <div className="form-group">
              <label>Your Email</label>
              <input type="email" value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} placeholder="john@example.com" required />
            </div>
            <div className="form-group">
              <label>Message / Project Details</label>
              <textarea rows="4" value={formData.message} onChange={(e) => setFormData({...formData, message: e.target.value})} placeholder="Tell me about your project..." required></textarea>
            </div>
            <button type="submit" className="btn-action btn-teal width-100">Send Message</button>
            {status && <div style={{ marginTop: '1rem', color: 'var(--teal)', textAlign: 'center' }}>{status}</div>}
          </form>
        </div>
      </div>
    </section>
  );
}
CONTACT

cat << 'ADMIN' > frontend/src/components/AdminPortal.jsx
import React, { useState, useEffect } from 'react';

const API_BASE = 'http://localhost:8000';

export default function AdminPortal({ onClose }) {
  const [token, setToken] = useState(localStorage.getItem('yeabsira_fastapi_admin_token') || '');
  const [user, setUser] = useState('yeabsira');
  const [pass, setPass] = useState('yeab1234');
  const [showPassword, setShowPassword] = useState(false);
  const [status, setStatus] = useState('');
  const [activeTab, setActiveTab] = useState('projects');
  const [projects, setProjects] = useState([]);
  const [messages, setMessages] = useState([]);

  const [newProj, setNewProj] = useState({
    title: '',
    category: 'dev',
    company_tag: '',
    description: '',
    tech_stack: '',
    link: ''
  });

  const handleLogin = async (e) => {
    e.preventDefault();
    setStatus('Logging in...');
    const formData = new URLSearchParams();
    formData.append('username', user);
    formData.append('password', pass);

    try {
      const res = await fetch(`${API_BASE}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: formData
      });
      const data = await res.json();
      if (res.ok) {
        setToken(data.access_token);
        localStorage.setItem('yeabsira_fastapi_admin_token', data.access_token);
        setStatus('');
      } else {
        setStatus(data.detail || 'Login failed');
      }
    } catch (err) {
      setStatus('Login error. Ensure Uvicorn is running on http://localhost:8000');
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('yeabsira_fastapi_admin_token');
    setToken('');
  };

  const fetchAdminProjects = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/projects`);
      const data = await res.json();
      setProjects(data);
    } catch (err) {}
  };

  const fetchAdminMessages = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/admin/messages`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (Array.isArray(data)) setMessages(data);
    } catch (err) {}
  };

  useEffect(() => {
    if (token) {
      fetchAdminProjects();
      fetchAdminMessages();
    }
  }, [token]);

  const handleAddProject = async (e) => {
    e.preventDefault();
    try {
      const res = await fetch(`${API_BASE}/api/admin/projects`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(newProj)
      });
      if (res.ok) {
        setNewProj({ title: '', category: 'dev', company_tag: '', description: '', tech_stack: '', link: '' });
        fetchAdminProjects();
      }
    } catch (err) {}
  };

  const handleDeleteProject = async (id) => {
    if (!confirm('Are you sure you want to delete this project?')) return;
    try {
      await fetch(`${API_BASE}/api/admin/projects/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      fetchAdminProjects();
    } catch (err) {}
  };

  return (
    <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', background: 'rgba(11,15,23,0.95)', backdropFilter: 'blur(15px)', zIndex: 2000, overflowY: 'auto', padding: '3rem 1rem' }}>
      <div className="container" style={{ maxWidth: '900px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <h2><span className="teal-text">React & FastAPI</span> Admin Portal</h2>
          <button onClick={onClose} className="btn-action btn-outline">✕ Close Portal</button>
        </div>

        {!token ? (
          <div className="glass" style={{ maxWidth: '450px', margin: '0 auto' }}>
            <h3 style={{ marginBottom: '1rem', textAlign: 'center' }}>Admin Authentication</h3>
            <form onSubmit={handleLogin}>
              <div className="form-group">
                <label>Username</label>
                <input type="text" value={user} onChange={(e) => setUser(e.target.value)} required />
              </div>

              <div className="form-group">
                <label>Password</label>
                <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                  <input 
                    type={showPassword ? "text" : "password"} 
                    value={pass} 
                    onChange={(e) => setPass(e.target.value)} 
                    required 
                    style={{ width: '100%', paddingRight: '2.5rem' }}
                  />
                  <button 
                    type="button" 
                    onClick={() => setShowPassword(!showPassword)}
                    style={{
                      position: 'absolute',
                      right: '10px',
                      background: 'transparent',
                      border: 'none',
                      color: 'var(--teal)',
                      cursor: 'pointer',
                      fontSize: '1.2rem'
                    }}
                    title={showPassword ? "Hide password" : "Show password"}
                  >
                    {showPassword ? '👁️' : '🙈'}
                  </button>
                </div>
              </div>

              <button type="submit" className="btn-action btn-teal width-100" style={{ marginTop: '1rem' }}>Login to Dashboard</button>
              {status && <p style={{ marginTop: '1rem', color: '#ef4444', textAlign: 'center' }}>{status}</p>}
            </form>
          </div>
        ) : (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '2rem' }}>
              <div style={{ display: 'flex', gap: '1rem' }}>
                <button className={`btn-action ${activeTab === 'projects' ? 'btn-teal' : 'btn-outline'}`} onClick={() => setActiveTab('projects')}>Manage Projects</button>
                <button className={`btn-action ${activeTab === 'messages' ? 'btn-teal' : 'btn-outline'}`} onClick={() => setActiveTab('messages')}>Inbox Messages ({messages.length})</button>
              </div>
              <button onClick={handleLogout} className="btn-action btn-gold">Logout</button>
            </div>

            {activeTab === 'projects' ? (
              <div>
                <div className="glass" style={{ marginBottom: '2rem' }}>
                  <h3>Add New Work / Project</h3>
                  <form onSubmit={handleAddProject} style={{ marginTop: '1rem' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                      <div className="form-group">
                        <label>Title</label>
                        <input type="text" value={newProj.title} onChange={(e) => setNewProj({...newProj, title: e.target.value})} required />
                      </div>
                      <div className="form-group">
                        <label>Category</label>
                        <select value={newProj.category} onChange={(e) => setNewProj({...newProj, category: e.target.value})}>
                          <option value="dev">Full-Stack Dev</option>
                          <option value="media">Cinematography & Video</option>
                        </select>
                      </div>
                    </div>
                    <div className="form-group">
                      <label>Client / Company Tag</label>
                      <input type="text" value={newProj.company_tag} onChange={(e) => setNewProj({...newProj, company_tag: e.target.value})} />
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <textarea rows="3" value={newProj.description} onChange={(e) => setNewProj({...newProj, description: e.target.value})} required></textarea>
                    </div>
                    <div className="form-group">
                      <label>Tech Stack (Comma separated)</label>
                      <input type="text" value={newProj.tech_stack} onChange={(e) => setNewProj({...newProj, tech_stack: e.target.value})} />
                    </div>
                    <button type="submit" className="btn-action btn-teal">Publish Project</button>
                  </form>
                </div>

                <div className="glass">
                  <h3>Existing Portfolio Works</h3>
                  <div style={{ marginTop: '1rem' }}>
                    {projects.map(p => (
                      <div key={p.id} style={{ padding: '1rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <strong>{p.title}</strong> ({p.category})
                          <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)' }}>{p.description}</p>
                        </div>
                        <button onClick={() => handleDeleteProject(p.id)} style={{ background: '#ef4444', color: '#fff', border: 'none', padding: '0.4rem 0.8rem', borderRadius: '4px', cursor: 'pointer' }}>Delete</button>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="glass">
                <h3>Visitor Inquiries</h3>
                {messages.length === 0 ? <p style={{ color: 'var(--text-muted)', marginTop: '1rem' }}>No messages received yet.</p> : (
                  <div style={{ marginTop: '1rem' }}>
                    {messages.map(m => (
                      <div key={m.id} style={{ padding: '1rem 0', borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                          <strong>{m.name} ({m.email})</strong>
                          <span style={{ fontSize: '0.8rem', color: 'var(--teal)' }}>{new Date(m.created_at).toLocaleString()}</span>
                        </div>
                        <p style={{ marginTop: '0.5rem', color: 'var(--text-muted)' }}>{m.message}</p>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
ADMIN

cat << 'APP' > frontend/src/App.jsx
import React, { useState } from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import About from './components/About';
import Projects from './components/Projects';
import SkillGraphs from './components/SkillGraphs';
import Experience from './components/Experience';
import Contact from './components/Contact';
import AdminPortal from './components/AdminPortal';
import FadeIn from './components/FadeIn';

export default function App() {
  const [isAdminOpen, setIsAdminOpen] = useState(false);

  return (
    <div>
      <div className="cinematic-bg">
        <div className="glow-orb orb-1"></div>
        <div className="glow-orb orb-2"></div>
      </div>

      <Navbar onOpenAdmin={() => setIsAdminOpen(true)} />
      
      <FadeIn><Hero /></FadeIn>
      <FadeIn><About /></FadeIn>
      <FadeIn><Projects /></FadeIn>
      <FadeIn><SkillGraphs /></FadeIn>
      <FadeIn><Experience /></FadeIn>
      <FadeIn><Contact /></FadeIn>

      {isAdminOpen && <AdminPortal onClose={() => setIsAdminOpen(false)} />}

      <footer style={{ padding: '2.5rem 0', textAlign: 'center', borderTop: '1px solid var(--border-glass)', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
        <p>&copy; 2026 Yeabsira Teklu. All rights reserved.</p>
        <p>Built with <span className="teal-text">React 18 & FastAPI</span></p>
      </footer>
    </div>
  );
}
APP

echo "✅ Portfolio setup complete! All code files created successfully."
