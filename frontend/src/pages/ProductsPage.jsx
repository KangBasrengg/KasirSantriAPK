import { useState, useEffect } from 'react';
import { getProducts, getCategories, createProduct, updateProduct, deleteProduct } from '../api';
import { formatRupiah } from '../utils/format';
import { Plus, Search, Edit2, Trash2, X, Package } from 'lucide-react';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterCat, setFilterCat] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editItem, setEditItem] = useState(null);
  const [form, setForm] = useState({ nama: '', sku: '', kategori_id: '', satuan: 'pcs', harga_beli: '', harga_jual: '', stok: '', stok_minimum: '5' });
  const [saving, setSaving] = useState(false);
  const [pagination, setPagination] = useState({ page: 1, totalPages: 1 });

  const fetchProducts = async (page = 1) => {
    try {
      setLoading(true);
      const params = { page, limit: 20 };
      if (search) params.search = search;
      if (filterCat) params.kategori_id = filterCat;
      const res = await getProducts(params);
      setProducts(res.data);
      setPagination(res.pagination);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchProducts(); }, []);
  useEffect(() => { getCategories().then(r => setCategories(r.data)).catch(console.error); }, []);
  useEffect(() => { const t = setTimeout(() => fetchProducts(), 300); return () => clearTimeout(t); }, [search, filterCat]);

  const openAdd = () => { setEditItem(null); setForm({ nama: '', sku: '', kategori_id: '', satuan: 'pcs', harga_beli: '', harga_jual: '', stok: '', stok_minimum: '5' }); setShowModal(true); };
  const openEdit = (p) => { setEditItem(p); setForm({ nama: p.nama, sku: p.sku || '', kategori_id: p.kategori_id || '', satuan: p.satuan, harga_beli: p.harga_beli || '', harga_jual: p.harga_jual, stok: p.stok, stok_minimum: p.stok_minimum }); setShowModal(true); };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = { ...form, harga_beli: parseFloat(form.harga_beli) || 0, harga_jual: parseFloat(form.harga_jual), stok: parseInt(form.stok) || 0, stok_minimum: parseInt(form.stok_minimum) || 5 };
      if (editItem) await updateProduct(editItem.id, payload);
      else await createProduct(payload);
      setShowModal(false);
      fetchProducts(pagination.page);
    } catch (e) { alert(e.message); }
    finally { setSaving(false); }
  };

  const handleDelete = async (id, nama) => {
    if (!confirm(`Hapus produk "${nama}"?`)) return;
    try { await deleteProduct(id); fetchProducts(pagination.page); } catch (e) { alert(e.message); }
  };

  return (
    <>
      <div className="page-header">
        <div><h2>Manajemen Produk</h2><p className="subtitle">{pagination.total || 0} produk terdaftar</p></div>
        <button className="btn btn-primary" onClick={openAdd}><Plus size={18} /> Tambah Produk</button>
      </div>
      <div className="page-body">
        <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <div className="search-box" style={{ flex: 1 }}>
            <Search size={18} className="search-icon" />
            <input placeholder="Cari nama atau SKU..." value={search} onChange={e => setSearch(e.target.value)} />
          </div>
          <select className="form-control" style={{ width: 200 }} value={filterCat} onChange={e => setFilterCat(e.target.value)}>
            <option value="">Semua Kategori</option>
            {categories.map(c => <option key={c.id} value={c.id}>{c.nama}</option>)}
          </select>
        </div>

        <div className="card">
          <div className="table-container">
            <table>
              <thead><tr><th>Produk</th><th>SKU</th><th>Kategori</th><th>Harga Beli</th><th>Harga Jual</th><th>Stok</th><th>Aksi</th></tr></thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan={7} style={{ textAlign: 'center', padding: 32 }}>Memuat...</td></tr>
                ) : products.length === 0 ? (
                  <tr><td colSpan={7}><div className="empty-state"><Package size={40} /><h4>Belum ada produk</h4><p>Klik tombol "Tambah Produk" untuk mulai</p></div></td></tr>
                ) : products.map(p => (
                  <tr key={p.id}>
                    <td style={{ fontWeight: 600 }}>{p.nama}</td>
                    <td style={{ fontFamily: 'monospace', fontSize: 13 }}>{p.sku}</td>
                    <td>{p.kategori_nama || '-'}</td>
                    <td>{formatRupiah(p.harga_beli)}</td>
                    <td style={{ fontWeight: 600, color: 'var(--primary)' }}>{formatRupiah(p.harga_jual)}</td>
                    <td><span className={`badge-status ${p.stok <= p.stok_minimum ? 'danger' : 'success'}`}>{p.stok} {p.satuan}</span></td>
                    <td>
                      <div style={{ display: 'flex', gap: 4 }}>
                        <button className="btn btn-ghost btn-sm" onClick={() => openEdit(p)}><Edit2 size={15} /></button>
                        <button className="btn btn-ghost btn-sm" style={{ color: 'var(--danger)' }} onClick={() => handleDelete(p.id, p.nama)}><Trash2 size={15} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {pagination.totalPages > 1 && (
          <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 16 }}>
            {Array.from({ length: pagination.totalPages }, (_, i) => (
              <button key={i} className={`btn btn-sm ${pagination.page === i + 1 ? 'btn-primary' : 'btn-outline'}`} onClick={() => fetchProducts(i + 1)}>{i + 1}</button>
            ))}
          </div>
        )}
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 560 }}>
            <div className="modal-header">
              <h3>{editItem ? 'Edit Produk' : 'Tambah Produk Baru'}</h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setShowModal(false)}><X size={18} /></button>
            </div>
            <form onSubmit={handleSave}>
              <div className="modal-body">
                <div className="form-group"><label>Nama Produk *</label><input className="form-control" value={form.nama} onChange={e => setForm({ ...form, nama: e.target.value })} required /></div>
                <div className="form-row">
                  <div className="form-group"><label>SKU</label><input className="form-control" value={form.sku} onChange={e => setForm({ ...form, sku: e.target.value })} placeholder="Auto-generate" /></div>
                  <div className="form-group"><label>Satuan</label><input className="form-control" value={form.satuan} onChange={e => setForm({ ...form, satuan: e.target.value })} /></div>
                </div>
                <div className="form-group"><label>Kategori</label>
                  <select className="form-control" value={form.kategori_id} onChange={e => setForm({ ...form, kategori_id: e.target.value })}>
                    <option value="">Pilih kategori</option>
                    {categories.map(c => <option key={c.id} value={c.id}>{c.nama}</option>)}
                  </select>
                </div>
                <div className="form-row">
                  <div className="form-group"><label>Harga Beli</label><input className="form-control" type="number" value={form.harga_beli} onChange={e => setForm({ ...form, harga_beli: e.target.value })} /></div>
                  <div className="form-group"><label>Harga Jual *</label><input className="form-control" type="number" value={form.harga_jual} onChange={e => setForm({ ...form, harga_jual: e.target.value })} required /></div>
                </div>
                <div className="form-row">
                  <div className="form-group"><label>Stok</label><input className="form-control" type="number" value={form.stok} onChange={e => setForm({ ...form, stok: e.target.value })} /></div>
                  <div className="form-group"><label>Stok Minimum</label><input className="form-control" type="number" value={form.stok_minimum} onChange={e => setForm({ ...form, stok_minimum: e.target.value })} /></div>
                </div>
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-outline" onClick={() => setShowModal(false)}>Batal</button>
                <button type="submit" className="btn btn-primary" disabled={saving}>{saving ? 'Menyimpan...' : 'Simpan'}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
