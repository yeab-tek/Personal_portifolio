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
          {/* Software Skill Bars */}
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

          {/* Media Skill Bars */}
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
