import React, { useState, useEffect } from 'react';
import profileImg from './1.png';

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
        {/* Photo Card */}
        <div className="hero-photo-card glass">
          <div className="photo-container">
           <img src={profileImg} alt="Yeabsira Teklu" className="hero-profile-img" />
            <div className="status-badge">
              <span className="status-dot"></span> Available for work
            </div>
          </div>
        </div>

        {/* Terminal Card */}
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
              <div className="code-line indent">stack: [<span class="green-text">'React'</span>, <span className="green-text">'FastAPI'</span>, <span className="green-text">'Node'</span>, <span className="green-text">'PostgreSQL'</span>],</div>
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
