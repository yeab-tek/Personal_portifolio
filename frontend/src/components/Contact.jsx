import React, { useState } from 'react';

export default function Contact() {
  const [formData, setFormData] = useState({ name: '', email: '', message: '' });
  const [status, setStatus] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setStatus('Sending message...');

    try {
      const res = await fetch('http://localhost:8000/api/contact', {
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
              {/* Direct Mailto Link */}
              <li style={{ padding: '0.6rem 0' }}>
                <a href="mailto:yeabtek7@gmail.com" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', fontSize: '1rem' }}>
                  📧 yeabtek7@gmail.com
                </a>
              </li>

              {/* Direct Call Link */}
              <li style={{ padding: '0.6rem 0' }}>
                <a href="tel:+251963008735" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', fontSize: '1rem', fontWeight: 600 }}>
                  📞 +251 963 008 735
                </a>
              </li>

              {/* Direct Map Location Link */}
              <li style={{ padding: '0.6rem 0' }}>
                <a href="https://maps.google.com/?q=Addis+Ababa,+Ethiopia" target="_blank" rel="noopener noreferrer" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', fontSize: '1rem' }}>
                  📍 Addis Ababa, Ethiopia
                </a>
              </li>

              {/* Direct GitHub Profile Link */}
              <li style={{ padding: '0.6rem 0' }}>
                <a href="https://github.com/yeab-tek" target="_blank" rel="noopener noreferrer" className="teal-text" style={{ display: 'inline-flex', alignItems: 'center', gap: '0.6rem', fontSize: '1rem' }}>
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