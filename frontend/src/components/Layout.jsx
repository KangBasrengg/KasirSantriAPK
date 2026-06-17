import { useState, useEffect } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { updateProfile } from '../api';
import { LayoutDashboard, Package, ShoppingCart, BarChart2, LogOut, Menu, X, ChevronUp, Sun, Moon, Settings, Eye, EyeOff } from 'lucide-react';

export default function Layout() {
  const { user, logout, loginUser, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light');
  const [showSettings, setShowSettings] = useState(false);

  // Account settings state
  const [settingsNama, setSettingsNama] = useState('');
  const [passwordLama, setPasswordLama] = useState('');
  const [passwordBaru, setPasswordBaru] = useState('');
  const [showPwLama, setShowPwLama] = useState(false);
  const [showPwBaru, setShowPwBaru] = useState(false);
  const [settingsMsg, setSettingsMsg] = useState('');
  const [settingsErr, setSettingsErr] = useState('');
  const [settingsLoading, setSettingsLoading] = useState(false);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
    setDropdownOpen(false);
  };

  const openSettings = () => {
    setSettingsNama(user?.nama || '');
    setPasswordLama('');
    setPasswordBaru('');
    setSettingsMsg('');
    setSettingsErr('');
    setShowSettings(true);
    setDropdownOpen(false);
  };

  const handleSaveSettings = async (e) => {
    e.preventDefault();
    setSettingsMsg('');
    setSettingsErr('');
    setSettingsLoading(true);

    try {
      const payload = { nama: settingsNama };
      if (passwordBaru) {
        if (!passwordLama) { setSettingsErr('Password lama wajib diisi.'); setSettingsLoading(false); return; }
        if (passwordBaru.length < 6) { setSettingsErr('Password baru minimal 6 karakter.'); setSettingsLoading(false); return; }
        payload.password_lama = passwordLama;
        payload.password_baru = passwordBaru;
      }

      const res = await updateProfile(payload);
      setSettingsMsg(res.message);

      // Update user data in context
      if (res.data) {
        const token = localStorage.getItem('tokokas_token');
        loginUser(token, res.data);
      }

      setPasswordLama('');
      setPasswordBaru('');
    } catch (err) {
      setSettingsErr(err.message);
    } finally {
      setSettingsLoading(false);
    }
  };

  const handleLogout = () => {
    if (confirm('Yakin ingin keluar?')) {
      logout();
      navigate('/login');
    }
  };

  const navItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard', adminOnly: false },
    { to: '/pos', icon: ShoppingCart, label: 'Kasir (POS)', adminOnly: false },
    { to: '/products', icon: Package, label: 'Produk & Stok', adminOnly: false },
    { to: '/reports', icon: BarChart2, label: 'Laporan', adminOnly: true },
  ];

  return (
    <div className="app-layout">
      {/* Mobile Overlay */}
      {sidebarOpen && (
        <div 
          style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 90 }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-brand">
          <div className="logo"><img src="/icon.png" alt="TokoKas Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} /></div>
          <h1>TokoKas</h1>
          <button 
            style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#fff', display: 'var(--mobile-only, none)' }}
            onClick={() => setSidebarOpen(false)}
          >
            <X size={20} />
          </button>
        </div>

        <nav className="sidebar-nav">
          <div className="nav-section-title">Menu Utama</div>
          {navItems.filter(item => !item.adminOnly || isAdmin).map(item => (
            <NavLink 
              key={item.to} 
              to={item.to} 
              className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
              onClick={() => setSidebarOpen(false)}
            >
              <item.icon size={18} />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer" style={{ position: 'relative' }}>
          {dropdownOpen && (
            <div className="user-dropdown">
              <button onClick={openSettings}>
                <Settings size={16} /> Pengaturan Akun
              </button>
              <button onClick={toggleTheme}>
                {theme === 'light' ? <><Moon size={16} /> Mode Gelap</> : <><Sun size={16} /> Mode Terang</>}
              </button>
              <div className="divider"></div>
              <button onClick={handleLogout} className="text-danger">
                <LogOut size={16} /> Keluar
              </button>
            </div>
          )}
          
          <div className="user-card" onClick={() => setDropdownOpen(!dropdownOpen)} style={{ cursor: 'pointer' }}>
            <div className="user-avatar">{user?.nama?.charAt(0).toUpperCase()}</div>
            <div className="user-info">
              <div className="name">{user?.nama}</div>
              <div className="role">{user?.role}</div>
            </div>
            <ChevronUp size={16} style={{ marginLeft: 'auto', color: 'var(--text-light)', transform: dropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }} />
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content" style={{ width: '100%' }}>
        {/* Mobile Header */}
        <div style={{ display: 'none', alignItems: 'center', padding: '16px 24px', background: 'var(--bg-card)', borderBottom: '1px solid var(--border)' }} className="mobile-header">
          <button onClick={() => setSidebarOpen(true)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <Menu size={24} color="var(--text-primary)" />
          </button>
          <h2 style={{ marginLeft: 16, fontSize: 18, fontWeight: 700 }}>TokoKas</h2>
        </div>
        
        {/* Konten Halaman */}
        <Outlet />
      </main>

      {/* Account Settings Modal */}
      {showSettings && (
        <div className="modal-overlay" onClick={() => setShowSettings(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 460 }}>
            <div className="modal-header">
              <h3>Pengaturan Akun</h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setShowSettings(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSaveSettings}>
              <div className="modal-body settings-form">
                {settingsMsg && <div className="settings-success">{settingsMsg}</div>}
                {settingsErr && <div className="login-error">{settingsErr}</div>}

                <div className="info-row">
                  <span className="label">Email</span>
                  <span className="value">{user?.email}</span>
                </div>
                <div className="info-row" style={{ borderBottom: 'none', marginBottom: 16 }}>
                  <span className="label">Role</span>
                  <span className="value" style={{ textTransform: 'capitalize' }}>{user?.role}</span>
                </div>

                <div className="form-group">
                  <label htmlFor="settings-nama">Nama Lengkap</label>
                  <input id="settings-nama" type="text" className="form-control" value={settingsNama} onChange={e => setSettingsNama(e.target.value)} required />
                </div>

                <div style={{ borderTop: '1px solid var(--border)', paddingTop: 16, marginTop: 8 }}>
                  <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 12 }}>Ubah Password (opsional, kosongkan jika tidak ingin mengubah)</p>
                  <div className="form-group">
                    <label htmlFor="settings-pw-lama">Password Lama</label>
                    <div style={{ position: 'relative' }}>
                      <input id="settings-pw-lama" type={showPwLama ? 'text' : 'password'} className="form-control" value={passwordLama} onChange={e => setPasswordLama(e.target.value)} placeholder="Masukkan password lama" style={{ paddingRight: 44 }} />
                      <button type="button" onClick={() => setShowPwLama(!showPwLama)} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)' }}>
                        {showPwLama ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>
                  <div className="form-group">
                    <label htmlFor="settings-pw-baru">Password Baru</label>
                    <div style={{ position: 'relative' }}>
                      <input id="settings-pw-baru" type={showPwBaru ? 'text' : 'password'} className="form-control" value={passwordBaru} onChange={e => setPasswordBaru(e.target.value)} placeholder="Minimal 6 karakter" style={{ paddingRight: 44 }} />
                      <button type="button" onClick={() => setShowPwBaru(!showPwBaru)} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)' }}>
                        {showPwBaru ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowSettings(false)}>Batal</button>
                <button type="submit" className="btn btn-primary" disabled={settingsLoading}>
                  {settingsLoading ? 'Menyimpan...' : 'Simpan Perubahan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <style>{`
        @media (max-width: 768px) {
          .mobile-header { display: flex !important; }
          .sidebar .sidebar-brand button { display: block !important; }
        }
      `}</style>
    </div>
  );
}
