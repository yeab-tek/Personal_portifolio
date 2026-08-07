import React, { useState, useEffect } from 'react';

export default function Projects() {
  const [projects, setProjects] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    fetch('/api/projects')
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) setProjects(data);
      })
      .catch(() => {
        // Default fallback if backend API is offline during build preview
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
