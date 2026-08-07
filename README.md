# Yeabsira Teklu — Cinematic Portfolio (FastAPI + React/HTML Full-Stack)

A full-stack portfolio and admin management application built using **Python FastAPI**, **SQLAlchemy/PostgreSQL**, and a **Cinematic Dark-Mode Frontend**.

## Features

1. **Public Visitor Interface (No Login Needed)**:
   - Terminal Hero (`whoami.sh`) with typewriter effect and live status badge (`🟢 Available for work`).
   - Project showcase dynamically loaded from the FastAPI database API (`GET /api/projects`).
   - Technical skill progress graphs & visual bar indicators.
   - Interactive "Hire Me" contact form that stores inquiries in the database and sends real email notifications.
   - Direct download link for `Yeabsira_Teklu_CV.pdf`.

2. **Admin Management Portal (Yeabsira / Authenticated User)**:
   - Admin Login at `/admin.html` with OAuth2/JWT token authentication (`username: yeabsira`, `password: yeab1234`).
   - **Manage Works**: Add new projects, update existing projects, or delete works.
   - **Visitor Inbox**: View all received "Hire Me" contact messages with sender names, emails, timestamps, and message text.

3. **Real Email Notifications**:
   - Integrated email sending via SMTP (configured with `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `NOTIFICATION_EMAIL`).

## How to Run locally with FastAPI

```bash
# 1. Navigate to backend directory
cd backend

# 2. Install Python dependencies
pip install -r requirements.txt

# 3. Start the FastAPI server with Uvicorn
uvicorn main:app --reload --port 8000
```

Open `http://localhost:8000` in your web browser.
- Main Portfolio: `http://localhost:8000`
- Admin Portal: `http://localhost:8000/admin.html`
- Interactive API Docs: `http://localhost:8000/docs`
