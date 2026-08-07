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
