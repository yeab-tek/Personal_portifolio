import React, { useState, useEffect } from 'react';

// Explicit FastAPI Backend Base URL
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

  // New Project Form State
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

              {/* Password Field with Eye Icon Toggle */}
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