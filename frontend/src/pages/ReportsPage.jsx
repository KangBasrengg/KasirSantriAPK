import { useState, useEffect } from 'react';
import { getSalesReport, getStockReport } from '../api';
import { formatRupiah, formatDate, formatDateTime } from '../utils/format';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState('penjualan'); // penjualan, stok
  const [loading, setLoading] = useState(true);
  
  // Data Penjualan
  const [salesData, setSalesData] = useState(null);
  const [periode, setPeriode] = useState('harian'); // harian, mingguan, bulanan
  
  // Data Stok
  const [stockData, setStockData] = useState(null);

  useEffect(() => {
    fetchData();
  }, [activeTab, periode]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'penjualan') {
        const res = await getSalesReport({ periode });
        setSalesData(res.data);
      } else {
        const res = await getStockReport();
        setStockData(res.data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="page-header">
        <div>
          <h2>Laporan & Analitik</h2>
          <p className="subtitle">Pantau performa penjualan dan stok barang</p>
        </div>
      </div>
      
      <div className="page-body">
        <div style={{ display: 'flex', gap: 16, marginBottom: 24, borderBottom: '1px solid var(--border)' }}>
          <button 
            className={`btn btn-ghost ${activeTab === 'penjualan' ? 'active' : ''}`}
            style={{ borderRadius: 0, borderBottom: activeTab === 'penjualan' ? '2px solid var(--primary)' : '2px solid transparent', color: activeTab === 'penjualan' ? 'var(--primary)' : 'inherit' }}
            onClick={() => setActiveTab('penjualan')}
          >
            Laporan Penjualan
          </button>
          <button 
            className={`btn btn-ghost ${activeTab === 'stok' ? 'active' : ''}`}
            style={{ borderRadius: 0, borderBottom: activeTab === 'stok' ? '2px solid var(--primary)' : '2px solid transparent', color: activeTab === 'stok' ? 'var(--primary)' : 'inherit' }}
            onClick={() => setActiveTab('stok')}
          >
            Laporan Stok
          </button>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: 48 }}><div className="spinner" style={{ margin: '0 auto', borderColor: 'rgba(37,99,235,0.2)', borderTopColor: '#2563eb' }}></div></div>
        ) : (
          <>
            {activeTab === 'penjualan' && salesData && (
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 20 }}>
                  <div style={{ display: 'flex', gap: 20 }}>
                    <div className="card" style={{ padding: '16px 24px' }}>
                      <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Total Omzet</div>
                      <div style={{ fontSize: 24, fontWeight: 800 }}>{formatRupiah(salesData.ringkasan.total_omzet)}</div>
                    </div>
                    <div className="card" style={{ padding: '16px 24px' }}>
                      <div style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Total Transaksi</div>
                      <div style={{ fontSize: 24, fontWeight: 800 }}>{salesData.ringkasan.total_transaksi}</div>
                    </div>
                  </div>
                  <div>
                    <select className="form-control" value={periode} onChange={e => setPeriode(e.target.value)}>
                      <option value="harian">Harian</option>
                      <option value="mingguan">Mingguan</option>
                      <option value="bulanan">Bulanan</option>
                    </select>
                  </div>
                </div>

                <div className="card" style={{ marginBottom: 24 }}>
                  <div className="card-header"><h3>Grafik Penjualan</h3></div>
                  <div className="card-body">
                    {salesData.laporan.length > 0 ? (
                      <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={salesData.laporan.map(i => ({ ...i, total_penjualan: parseFloat(i.total_penjualan) })).reverse()}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                          <XAxis dataKey="periode" tick={{ fontSize: 12 }} />
                          <YAxis tick={{ fontSize: 12 }} tickFormatter={v => `${(v/1000).toFixed(0)}k`} />
                          <Tooltip formatter={v => formatRupiah(v)} />
                          <Bar dataKey="total_penjualan" name="Omzet" fill="#2563eb" radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="empty-state">Belum ada data</div>
                    )}
                  </div>
                </div>

                <div className="card">
                  <div className="card-header"><h3>Tabel Data</h3></div>
                  <div className="table-container">
                    <table>
                      <thead><tr><th>Periode</th><th>Jml Transaksi</th><th>Omzet</th></tr></thead>
                      <tbody>
                        {salesData.laporan.map((row, i) => (
                          <tr key={i}>
                            <td style={{ fontWeight: 600 }}>{row.periode}</td>
                            <td>{row.jumlah_transaksi}</td>
                            <td style={{ fontWeight: 600, color: 'var(--primary)' }}>{formatRupiah(row.total_penjualan)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'stok' && stockData && (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
                <div className="card" style={{ gridColumn: '1 / -1' }}>
                  <div className="card-header"><h3>Status Stok Produk</h3></div>
                  <div className="table-container" style={{ maxHeight: 400 }}>
                    <table>
                      <thead style={{ position: 'sticky', top: 0, zIndex: 10 }}><tr><th>SKU</th><th>Produk</th><th>Kategori</th><th>Stok</th><th>Status</th></tr></thead>
                      <tbody>
                        {stockData.produk.map(p => (
                          <tr key={p.id}>
                            <td style={{ fontSize: 12, fontFamily: 'monospace' }}>{p.sku}</td>
                            <td style={{ fontWeight: 600 }}>{p.nama}</td>
                            <td>{p.kategori || '-'}</td>
                            <td style={{ fontWeight: 700 }}>{p.stok}</td>
                            <td>
                              {p.is_kritis ? (
                                <span className="badge-status danger">Kritis (&le; {p.stok_minimum})</span>
                              ) : (
                                <span className="badge-status success">Aman</span>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                <div className="card" style={{ gridColumn: '1 / -1' }}>
                  <div className="card-header"><h3>Log Pergerakan Stok Terbaru</h3></div>
                  <div className="table-container" style={{ maxHeight: 400 }}>
                    <table>
                      <thead style={{ position: 'sticky', top: 0, zIndex: 10 }}><tr><th>Waktu</th><th>Produk</th><th>Tipe</th><th>Qty</th><th>Keterangan</th></tr></thead>
                      <tbody>
                        {stockData.log_stok.map(log => (
                          <tr key={log.id}>
                            <td style={{ fontSize: 13, color: 'var(--text-secondary)' }}>{formatDateTime(log.waktu)}</td>
                            <td style={{ fontWeight: 600 }}>{log.produk_nama}</td>
                            <td>
                              <span className={`badge-status ${log.tipe === 'in' ? 'success' : 'danger'}`}>
                                {log.tipe === 'in' ? 'Masuk' : 'Keluar'}
                              </span>
                            </td>
                            <td style={{ fontWeight: 700, color: log.tipe === 'in' ? 'var(--accent)' : 'var(--danger)' }}>
                              {log.tipe === 'in' ? '+' : '-'}{log.qty}
                            </td>
                            <td style={{ fontSize: 13 }}>{log.keterangan}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </>
  );
}
