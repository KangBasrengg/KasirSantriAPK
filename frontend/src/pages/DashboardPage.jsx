import { useState, useEffect } from 'react';
import { getDashboard, getProfitReport } from '../api';
import { formatRupiah, formatDateTime } from '../utils/format';
import { TrendingUp, ShoppingCart, Package, AlertTriangle, DollarSign } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, AreaChart, Area } from 'recharts';

export default function DashboardPage() {
  const [data, setData] = useState(null);
  const [profit, setProfit] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      getDashboard().then(res => setData(res.data)),
      getProfitReport().then(res => setProfit(res.data)).catch(() => null)
    ])
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="page-body"><div style={{ textAlign: 'center', padding: 48 }}><div className="spinner" style={{ margin: '0 auto', borderColor: 'rgba(37,99,235,0.2)', borderTopColor: '#2563eb', width: 32, height: 32 }}></div></div></div>;

  const d = data || { hari_ini: { omzet: 0, jumlah_transaksi: 0 }, bulan_ini: { omzet: 0, jumlah_transaksi: 0 }, total_produk: 0, stok_kritis: 0, produk_terlaris: [], omzet_7_hari: [], transaksi_terakhir: [] };
  const p = profit || { hari_ini: { penjualan: 0, modal: 0, laba: 0 }, bulan_ini: { penjualan: 0, modal: 0, laba: 0 }, laba_7_hari: [] };

  return (
    <>
      <div className="page-header">
        <div>
          <h2>Dashboard</h2>
          <p className="subtitle">Ringkasan performa toko hari ini</p>
        </div>
      </div>
      <div className="page-body">
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-icon blue"><TrendingUp size={24} /></div>
            <div className="stat-info">
              <h4>Omzet Hari Ini</h4>
              <div className="value">{formatRupiah(d.hari_ini.omzet)}</div>
              <div className="sub">{d.hari_ini.jumlah_transaksi} transaksi</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon green"><ShoppingCart size={24} /></div>
            <div className="stat-info">
              <h4>Omzet Bulan Ini</h4>
              <div className="value">{formatRupiah(d.bulan_ini.omzet)}</div>
              <div className="sub">{d.bulan_ini.jumlah_transaksi} transaksi</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon orange"><DollarSign size={24} /></div>
            <div className="stat-info">
              <h4>Laba Hari Ini</h4>
              <div className="value" style={{ color: p.hari_ini.laba >= 0 ? '#059669' : '#dc2626' }}>{formatRupiah(p.hari_ini.laba)}</div>
              <div className="sub">Modal: {formatRupiah(p.hari_ini.modal)}</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon purple"><Package size={24} /></div>
            <div className="stat-info">
              <h4>Total Produk</h4>
              <div className="value">{d.total_produk}</div>
              <div className="sub">produk aktif</div>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon red"><AlertTriangle size={24} /></div>
            <div className="stat-info">
              <h4>Stok Kritis</h4>
              <div className="value">{d.stok_kritis}</div>
              <div className="sub">perlu restock</div>
            </div>
          </div>
        </div>

        {/* Charts Grid */}
        <div className="charts-grid">
          <div className="card">
            <div className="card-header"><h3>Omzet 7 Hari Terakhir</h3></div>
            <div className="card-body">
              {d.omzet_7_hari.length > 0 ? (
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart data={d.omzet_7_hari.map(i => ({ ...i, omzet: parseFloat(i.omzet) }))}>
                    <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                    <XAxis dataKey="tanggal" tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} tickFormatter={v => new Date(v).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' })} />
                    <YAxis tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                    <Tooltip formatter={v => formatRupiah(v)} labelFormatter={v => new Date(v).toLocaleDateString('id-ID')} contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 8, color: 'var(--text-primary)' }} />
                    <Bar dataKey="omzet" fill="#2563eb" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="empty-state"><p>Belum ada data penjualan</p></div>
              )}
            </div>
          </div>

          <div className="card">
            <div className="card-header"><h3>Produk Terlaris Hari Ini</h3></div>
            <div className="card-body">
              {d.produk_terlaris.length > 0 ? (
                <div>
                  {d.produk_terlaris.map((pr, i) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 0', borderBottom: i < d.produk_terlaris.length - 1 ? '1px solid var(--border)' : 'none' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <span style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--primary-light)', color: 'var(--primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 12, fontWeight: 700 }}>{i + 1}</span>
                        <span style={{ fontSize: 14, fontWeight: 500 }}>{pr.nama_produk}</span>
                      </div>
                      <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--primary)' }}>{pr.total_qty}x</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="empty-state"><p>Belum ada penjualan hari ini</p></div>
              )}
            </div>
          </div>
        </div>

        {/* Laba Chart */}
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>📊 Laba 7 Hari Terakhir</h3>
            <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
              Laba Bulan Ini: <span style={{ fontWeight: 700, color: p.bulan_ini.laba >= 0 ? '#059669' : '#dc2626' }}>{formatRupiah(p.bulan_ini.laba)}</span>
            </div>
          </div>
          <div className="card-body">
            {p.laba_7_hari.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={p.laba_7_hari.map(i => ({ ...i, laba: parseFloat(i.laba), total_penjualan: parseFloat(i.total_penjualan), total_modal: parseFloat(i.total_modal) }))}>
                  <defs>
                    <linearGradient id="labaGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#059669" stopOpacity={0.3} />
                      <stop offset="95%" stopColor="#059669" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="penjualanGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#2563eb" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis dataKey="tanggal" tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} tickFormatter={v => new Date(v).toLocaleDateString('id-ID', { day: '2-digit', month: 'short' })} />
                  <YAxis tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} tickFormatter={v => `${(v / 1000).toFixed(0)}k`} />
                  <Tooltip
                    formatter={(v, name) => [formatRupiah(v), name === 'laba' ? 'Laba' : name === 'total_penjualan' ? 'Penjualan' : 'Modal']}
                    labelFormatter={v => new Date(v).toLocaleDateString('id-ID')}
                    contentStyle={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 8, color: 'var(--text-primary)' }}
                  />
                  <Legend formatter={v => v === 'laba' ? 'Laba Bersih' : v === 'total_penjualan' ? 'Penjualan' : 'Modal'} />
                  <Area type="monotone" dataKey="total_penjualan" stroke="#2563eb" fill="url(#penjualanGradient)" strokeWidth={2} />
                  <Area type="monotone" dataKey="laba" stroke="#059669" fill="url(#labaGradient)" strokeWidth={2.5} />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="empty-state"><p>Belum ada data laba</p></div>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-header"><h3>Transaksi Terakhir</h3></div>
          <div className="table-container">
            <table>
              <thead><tr><th>No. Transaksi</th><th>Kasir</th><th>Total</th><th>Metode</th><th>Waktu</th></tr></thead>
              <tbody>
                {d.transaksi_terakhir.length > 0 ? d.transaksi_terakhir.map(t => (
                  <tr key={t.id}>
                    <td style={{ fontWeight: 600, fontFamily: 'monospace', fontSize: 13 }}>{t.nomor_transaksi}</td>
                    <td>{t.kasir_nama}</td>
                    <td style={{ fontWeight: 600 }}>{formatRupiah(t.total)}</td>
                    <td><span className={`badge-status ${t.metode_bayar === 'tunai' ? 'success' : 'info'}`}>{t.metode_bayar}</span></td>
                    <td style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{formatDateTime(t.waktu)}</td>
                  </tr>
                )) : (
                  <tr><td colSpan={5} style={{ textAlign: 'center', padding: 24, color: 'var(--text-light)' }}>Belum ada transaksi</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </>
  );
}
