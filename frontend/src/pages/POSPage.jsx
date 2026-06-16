import { useState, useEffect } from 'react';
import { getProducts, createTransaction } from '../api';
import { formatRupiah, formatDateTime } from '../utils/format';
import { Search, Plus, Minus, Trash2, ShoppingCart, Check, X, Printer } from 'lucide-react';

export default function POSPage() {
  const [products, setProducts] = useState([]);
  const [search, setSearch] = useState('');
  const [cart, setCart] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showPayment, setShowPayment] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState('tunai');
  const [paymentAmount, setPaymentAmount] = useState('');
  const [saving, setSaving] = useState(false);
  const [successTrx, setSuccessTrx] = useState(null);

  useEffect(() => {
    const t = setTimeout(() => {
      getProducts({ limit: 50, search }).then(r => setProducts(r.data)).catch(console.error);
    }, 300);
    return () => clearTimeout(t);
  }, [search]);

  const addToCart = (product) => {
    if (product.stok <= 0) return alert('Stok habis!');
    
    setCart(prev => {
      const existing = prev.find(item => item.id === product.id);
      if (existing) {
        if (existing.qty >= product.stok) {
          alert('Melebihi stok yang ada!');
          return prev;
        }
        return prev.map(item => item.id === product.id ? { ...item, qty: item.qty + 1 } : item);
      }
      return [...prev, { ...product, qty: 1 }];
    });
  };

  const updateQty = (id, delta) => {
    setCart(prev => prev.map(item => {
      if (item.id === id) {
        const newQty = item.qty + delta;
        if (newQty <= 0) return null; // Akan difilter
        if (newQty > item.stok) {
          alert('Melebihi stok yang ada!');
          return item;
        }
        return { ...item, qty: newQty };
      }
      return item;
    }).filter(Boolean));
  };

  const total = cart.reduce((sum, item) => sum + (item.harga_jual * item.qty), 0);
  const change = (parseFloat(paymentAmount) || 0) - total;

  const handleCheckout = async () => {
    if (paymentMethod === 'tunai' && change < 0) {
      return alert('Jumlah bayar kurang dari total belanja!');
    }

    setSaving(true);
    try {
      const payload = {
        items: cart.map(i => ({ produk_id: i.id, qty: i.qty })),
        metode_bayar: paymentMethod,
        bayar: paymentMethod === 'tunai' ? parseFloat(paymentAmount) : total,
      };

      const res = await createTransaction(payload);
      setSuccessTrx(res.data);
      setCart([]);
      setShowPayment(false);
      setPaymentAmount('');
      
      // Refresh produk stok
      getProducts({ limit: 50, search }).then(r => setProducts(r.data)).catch(console.error);
    } catch (e) {
      alert(e.message);
    } finally {
      setSaving(false);
    }
  };

  const handlePrintReceipt = (trx) => {
    const items = trx.items || [];
    const now = new Date(trx.waktu || Date.now());
    const tanggal = now.toLocaleString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });

    const receiptHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Struk - ${trx.nomor_transaksi}</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: 'Courier New', monospace; width: 80mm; margin: 0 auto; padding: 8mm 4mm; font-size: 12px; color: #000; }
          .center { text-align: center; }
          .bold { font-weight: bold; }
          .divider { border-top: 1px dashed #000; margin: 6px 0; }
          .row { display: flex; justify-content: space-between; margin: 2px 0; }
          .item-name { margin: 4px 0 2px; font-weight: bold; }
          .item-detail { display: flex; justify-content: space-between; color: #333; font-size: 11px; }
          h2 { font-size: 16px; margin-bottom: 2px; }
          .footer { margin-top: 12px; text-align: center; font-size: 11px; color: #666; }
        </style>
      </head>
      <body>
        <div class="center">
          <h2>TokoKas</h2>
          <p style="font-size:11px;color:#666;">Sistem POS Toko Pribadi</p>
        </div>
        <div class="divider"></div>
        <div class="row"><span>No:</span><span class="bold">${trx.nomor_transaksi}</span></div>
        <div class="row"><span>Waktu:</span><span>${tanggal}</span></div>
        <div class="row"><span>Metode:</span><span style="text-transform:capitalize">${trx.metode_bayar}</span></div>
        <div class="divider"></div>
        ${items.map(item => `
          <div class="item-name">${item.nama_produk}</div>
          <div class="item-detail">
            <span>${item.qty} x ${Number(item.harga_jual).toLocaleString('id-ID')}</span>
            <span>${Number(item.subtotal).toLocaleString('id-ID')}</span>
          </div>
        `).join('')}
        <div class="divider"></div>
        <div class="row bold"><span>TOTAL</span><span>Rp ${Number(trx.total).toLocaleString('id-ID')}</span></div>
        <div class="row"><span>Bayar</span><span>Rp ${Number(trx.bayar).toLocaleString('id-ID')}</span></div>
        ${Number(trx.kembalian) > 0 ? `<div class="row"><span>Kembalian</span><span>Rp ${Number(trx.kembalian).toLocaleString('id-ID')}</span></div>` : ''}
        <div class="divider"></div>
        <div class="footer">
          <p>Terima kasih!</p>
          <p>Barang yang sudah dibeli</p>
          <p>tidak dapat dikembalikan.</p>
        </div>
        <script>window.onload = function() { window.print(); }</script>
      </body>
      </html>
    `;

    const printWindow = window.open('', '_blank', 'width=320,height=600');
    printWindow.document.write(receiptHtml);
    printWindow.document.close();
  };

  if (successTrx) {
    return (
      <div className="page-body" style={{ minHeight: 'calc(100vh - 64px)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div className="card" style={{ maxWidth: 400, width: '100%', textAlign: 'center', padding: 32 }}>
          <div style={{ width: 64, height: 64, background: '#d1fae5', color: '#059669', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px' }}>
            <Check size={32} />
          </div>
          <h2 style={{ marginBottom: 8 }}>Transaksi Berhasil!</h2>
          <p style={{ color: 'var(--text-secondary)', marginBottom: 24 }}>No: {successTrx.nomor_transaksi}</p>
          
          <div style={{ background: 'var(--bg-main)', padding: 16, borderRadius: 8, textAlign: 'left', marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span>Total:</span> <span style={{ fontWeight: 700 }}>{formatRupiah(successTrx.total)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
              <span>Bayar ({successTrx.metode_bayar}):</span> <span style={{ fontWeight: 700 }}>{formatRupiah(successTrx.bayar)}</span>
            </div>
            {successTrx.kembalian > 0 && (
              <div style={{ display: 'flex', justifyContent: 'space-between', paddingTop: 8, borderTop: '1px solid var(--border)' }}>
                <span>Kembalian:</span> <span style={{ fontWeight: 700, color: 'var(--primary)' }}>{formatRupiah(successTrx.kembalian)}</span>
              </div>
            )}
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <button className="btn btn-outline" style={{ flex: 1 }} onClick={() => handlePrintReceipt(successTrx)}>
              <Printer size={16} /> Cetak Struk
            </button>
            <button className="btn btn-primary" style={{ flex: 1 }} onClick={() => setSuccessTrx(null)}>Trx Baru</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="page-body" style={{ padding: 16 }}>
      <div className="pos-layout">
        <div className="pos-products">
          <div className="search-box" style={{ marginBottom: 20 }}>
            <Search size={18} className="search-icon" />
            <input 
              placeholder="Cari produk (Nama atau SKU)..." 
              value={search} 
              onChange={e => setSearch(e.target.value)}
              style={{ fontSize: 16, padding: '12px 14px 12px 40px' }}
            />
          </div>

          <div className="product-grid">
            {products.map(p => (
              <div 
                key={p.id} 
                className="product-card" 
                onClick={() => addToCart(p)}
                style={{ opacity: p.stok <= 0 ? 0.5 : 1 }}
              >
                {p.stok <= 0 && <div style={{ position: 'absolute', top: 8, right: 8, background: 'var(--danger)', color: 'white', fontSize: 10, padding: '2px 6px', borderRadius: 4, fontWeight: 600 }}>Habis</div>}
                <div style={{ height: 80, background: 'var(--bg-main)', borderRadius: 8, marginBottom: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--text-light)' }}>
                  {p.foto_url ? <img src={p.foto_url} alt={p.nama} style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: 8 }} /> : <ShoppingCart size={24} />}
                </div>
                <div className="name">{p.nama}</div>
                <div className="price">{formatRupiah(p.harga_jual)}</div>
                <div className="stock">Stok: {p.stok}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="pos-cart">
          <div className="cart-header">
            <span>Pesanan Saat Ini</span>
            {cart.length > 0 && <span style={{ background: 'var(--primary)', color: 'white', padding: '2px 8px', borderRadius: 12, fontSize: 12 }}>{cart.length} item</span>}
          </div>
          
          <div className="cart-items">
            {cart.length === 0 ? (
              <div className="empty-state" style={{ padding: '60px 20px' }}>
                <ShoppingCart size={40} />
                <p>Belum ada produk di keranjang</p>
              </div>
            ) : (
              cart.map(item => (
                <div key={item.id} className="cart-item">
                  <div className="item-info">
                    <div className="item-name">{item.nama}</div>
                    <div className="item-price">{formatRupiah(item.harga_jual)} <span style={{ color: 'var(--text-light)', fontSize: 12 }}>x {item.qty}</span></div>
                  </div>
                  <div className="qty-control">
                    <button className="qty-btn" onClick={() => updateQty(item.id, -1)}><Minus size={14} /></button>
                    <span style={{ width: 24, textAlign: 'center', fontWeight: 600 }}>{item.qty}</span>
                    <button className="qty-btn" onClick={() => updateQty(item.id, 1)}><Plus size={14} /></button>
                  </div>
                  <div style={{ fontWeight: 700, width: 80, textAlign: 'right' }}>
                    {formatRupiah(item.harga_jual * item.qty)}
                  </div>
                </div>
              ))
            )}
          </div>

          <div className="cart-footer">
            <div className="cart-total">
              <span>Total:</span>
              <span style={{ color: 'var(--primary)' }}>{formatRupiah(total)}</span>
            </div>
            <button 
              className="btn btn-primary" 
              style={{ width: '100%', justifyContent: 'center', padding: '16px 20px', fontSize: 18 }}
              disabled={cart.length === 0}
              onClick={() => setShowPayment(true)}
            >
              Bayar Sekarang
            </button>
          </div>
        </div>
      </div>

      {showPayment && (
        <div className="modal-overlay" onClick={() => setShowPayment(false)}>
          <div className="modal" onClick={e => e.stopPropagation()} style={{ maxWidth: 450 }}>
            <div className="modal-header">
              <h3>Pembayaran</h3>
              <button className="btn btn-ghost btn-sm" onClick={() => setShowPayment(false)}><X size={18} /></button>
            </div>
            <div className="modal-body">
              <div style={{ textAlign: 'center', marginBottom: 24 }}>
                <div style={{ fontSize: 14, color: 'var(--text-secondary)', marginBottom: 4 }}>Total Tagihan</div>
                <div style={{ fontSize: 32, fontWeight: 800, color: 'var(--primary)' }}>{formatRupiah(total)}</div>
              </div>

              <div className="form-group">
                <label>Metode Pembayaran</label>
                <div className="payment-methods">
                  <div className={`payment-method ${paymentMethod === 'tunai' ? 'active' : ''}`} onClick={() => setPaymentMethod('tunai')}>Tunai</div>
                  <div className={`payment-method ${paymentMethod === 'transfer' ? 'active' : ''}`} onClick={() => setPaymentMethod('transfer')}>Transfer</div>
                  <div className={`payment-method ${paymentMethod === 'qris' ? 'active' : ''}`} onClick={() => setPaymentMethod('qris')}>QRIS</div>
                </div>
              </div>

              {paymentMethod === 'tunai' && (
                <>
                  <div className="form-group">
                    <label>Jumlah Bayar (Rp)</label>
                    <input 
                      type="number" 
                      className="form-control" 
                      style={{ fontSize: 20, padding: 16, fontWeight: 700 }}
                      value={paymentAmount}
                      onChange={e => setPaymentAmount(e.target.value)}
                      placeholder="0"
                      autoFocus
                    />
                    <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                      <button type="button" className="btn btn-outline btn-sm" onClick={() => setPaymentAmount(total)}>Uang Pas</button>
                      <button type="button" className="btn btn-outline btn-sm" onClick={() => setPaymentAmount(50000)}>50K</button>
                      <button type="button" className="btn btn-outline btn-sm" onClick={() => setPaymentAmount(100000)}>100K</button>
                    </div>
                  </div>

                  {change >= 0 && paymentAmount && (
                    <div className="change-display">
                      <div className="label">Kembalian</div>
                      <div className="amount">{formatRupiah(change)}</div>
                    </div>
                  )}
                </>
              )}
            </div>
            <div className="modal-footer">
              <button className="btn btn-outline" onClick={() => setShowPayment(false)}>Batal</button>
              <button 
                className="btn btn-primary" 
                onClick={handleCheckout}
                disabled={saving || (paymentMethod === 'tunai' && change < 0)}
              >
                {saving ? 'Memproses...' : 'Selesaikan Transaksi'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
