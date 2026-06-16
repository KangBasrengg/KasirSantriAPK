import { useState } from 'react';
import { login as loginApi } from '../api';
import { useAuth } from '../context/AuthContext';
import { Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  const { loginUser } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = await loginApi(email, password);
      loginUser(res.data.token, res.data.user);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="logo-section">
          <div className="logo-icon">
            <img src="/icon.png" alt="TokoKas Logo" style={{ width: '100%', height: '100%', objectFit: 'contain', transform: 'scale(1.6)' }} />
          </div>
          <h2>TokoKas</h2>
          <p className="tagline">Sistem POS Toko Pribadi</p>
        </div>

        {error && <div className="login-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input id="email" type="email" className="form-control" placeholder="admin@tokokas.com" value={email} onChange={e => setEmail(e.target.value)} required />
          </div>
          <div className="form-group">
            <label htmlFor="password">Password</label>
            <div style={{ position: 'relative' }}>
              <input id="password" type={showPw ? 'text' : 'password'} className="form-control" placeholder="Masukkan password" value={password} onChange={e => setPassword(e.target.value)} required style={{ paddingRight: 44 }} />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{ position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)' }}>
                {showPw ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>
          <button type="submit" className="btn btn-primary btn-lg" disabled={loading} style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
            {loading ? <><div className="spinner"></div> Masuk...</> : 'Masuk'}
          </button>
        </form>

        <p style={{ textAlign: 'center', fontSize: 12, color: 'var(--text-light)', marginTop: 24 }}>
          Default: admin@tokokas.com / admin123
        </p>
      </div>
    </div>
  );
}
