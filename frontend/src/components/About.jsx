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
