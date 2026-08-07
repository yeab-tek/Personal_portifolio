import React from 'react';

export default function Navbar({ onOpenAdmin }) {
  return (
    <nav class="navbar">
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
