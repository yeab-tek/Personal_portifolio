import React, { useState } from 'react';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import About from './components/About';
import Projects from './components/Projects';
import SkillGraphs from './components/SkillGraphs';
import Experience from './components/Experience';
import Contact from './components/Contact';
import AdminPortal from './components/AdminPortal';

export default function App() {
  const [isAdminOpen, setIsAdminOpen] = useState(false);

  return (
    <div>
      <div className="cinematic-bg">
        <div className="glow-orb orb-1"></div>
        <div className="glow-orb orb-2"></div>
      </div>

      <Navbar onOpenAdmin={() => setIsAdminOpen(true)} />
      <Hero />
      <About />
      <Projects />
      <SkillGraphs />
      <Experience />
      <Contact />

      {isAdminOpen && <AdminPortal onClose={() => setIsAdminOpen(false)} />}

      <footer style={{ padding: '2.5rem 0', textAlign: 'center', borderTop: '1px solid var(--border-glass)', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
        <p>&copy; 2026 Yeabsira Teklu. All rights reserved.</p>
        <p>Built with <span className="teal-text">React 18 + Vite & FastAPI</span></p>
      </footer>
    </div>
  );
}
