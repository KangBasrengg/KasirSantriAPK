import { useState, useEffect } from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { LayoutDashboard, Package, ShoppingCart, BarChart2, LogOut, Menu, X, ChevronUp, Sun, Moon, Settings } from 'lucide-react';

export default function Layout() {
  const { user, logout, isAdmin } = useAuth();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'light');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggleTheme = () => {
    setTheme(theme === 'light' ? 'dark' : 'light');
    setDropdownOpen(false);
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
              <button onClick={() => { setDropdownOpen(false); alert('Menu Pengaturan Akun akan segera hadir!'); }}>
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
        {/* Mobile Header (Hanya tampil di layar kecil) */}
        <div style={{ display: 'none', alignItems: 'center', padding: '16px 24px', background: '#fff', borderBottom: '1px solid var(--border)' }} className="mobile-header">
          <button onClick={() => setSidebarOpen(true)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
            <Menu size={24} color="var(--text-primary)" />
          </button>
          <h2 style={{ marginLeft: 16, fontSize: 18, fontWeight: 700 }}>TokoKas</h2>
        </div>
        
        {/* Konten Halaman */}
        <Outlet />
      </main>

      <style>{`
        @media (max-width: 768px) {
          .mobile-header { display: flex !important; }
          .sidebar .sidebar-brand button { display: block !important; }
        }
      `}</style>
    </div>
  );
}
