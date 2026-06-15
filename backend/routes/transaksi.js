const express = require('express');
const pool = require('../config/db');
const { authenticateToken } = require('../middleware/auth');
const { generateNomorTransaksi } = require('../utils/helpers');

const router = express.Router();

// POST /api/transaksi - Buat transaksi baru
router.post('/', authenticateToken, async (req, res) => {
  const client = await pool.connect();
  try {
    const { items, metode_bayar, bayar, catatan } = req.body;
    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Minimal 1 item.' });
    }

    await client.query('BEGIN');
    let total = 0;
    const processedItems = [];

    for (const item of items) {
      const produk = await client.query(
        'SELECT id, nama, harga_jual, stok FROM products WHERE id = $1 AND is_active = true',
        [item.produk_id]
      );
      if (produk.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ success: false, message: `Produk ${item.produk_id} tidak ditemukan.` });
      }
      const p = produk.rows[0];
      if (p.stok < item.qty) {
        await client.query('ROLLBACK');
        return res.status(400).json({ success: false, message: `Stok "${p.nama}" tidak cukup. Sisa: ${p.stok}` });
      }
      const subtotal = p.harga_jual * item.qty;
      total += subtotal;
      processedItems.push({ produk_id: p.id, nama_produk: p.nama, qty: item.qty, harga_jual: p.harga_jual, subtotal });
    }

    const pembayaran = parseFloat(bayar) || total;
    if (pembayaran < total) {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, message: 'Pembayaran kurang.' });
    }

    const kembalian = pembayaran - total;
    const nomorTransaksi = generateNomorTransaksi();

    const trxResult = await client.query(
      `INSERT INTO transactions (nomor_transaksi, kasir_id, total, metode_bayar, bayar, kembalian, catatan) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [nomorTransaksi, req.user.id, total, metode_bayar || 'tunai', pembayaran, kembalian, catatan || null]
    );
    const transaksi = trxResult.rows[0];

    for (const item of processedItems) {
      await client.query(
        `INSERT INTO trx_items (transaksi_id, produk_id, nama_produk, qty, harga_jual, subtotal) VALUES ($1,$2,$3,$4,$5,$6)`,
        [transaksi.id, item.produk_id, item.nama_produk, item.qty, item.harga_jual, item.subtotal]
      );
      await client.query('UPDATE products SET stok = stok - $1, updated_at = NOW() WHERE id = $2', [item.qty, item.produk_id]);
      await client.query(
        `INSERT INTO stock_logs (produk_id, tipe, qty, ref_type, ref_id, keterangan) VALUES ($1, 'out', $2, 'transaksi', $3, $4)`,
        [item.produk_id, item.qty, transaksi.id, `Penjualan ${nomorTransaksi}`]
      );
    }

    await client.query('COMMIT');
    res.status(201).json({ success: true, message: 'Transaksi berhasil!', data: { ...transaksi, items: processedItems } });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Create transaksi error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  } finally {
    client.release();
  }
});

// GET /api/transaksi - Riwayat transaksi
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, tanggal_mulai, tanggal_akhir, metode_bayar } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    let where = 'WHERE 1=1';
    const params = [];
    let pi = 1;

    if (tanggal_mulai) { where += ` AND t.waktu >= $${pi}`; params.push(tanggal_mulai); pi++; }
    if (tanggal_akhir) { where += ` AND t.waktu <= $${pi}`; params.push(tanggal_akhir + 'T23:59:59'); pi++; }
    if (metode_bayar) { where += ` AND t.metode_bayar = $${pi}`; params.push(metode_bayar); pi++; }
    if (req.user.role !== 'admin') { where += ` AND t.kasir_id = $${pi}`; params.push(req.user.id); pi++; }

    const countResult = await pool.query(`SELECT COUNT(*) FROM transactions t ${where}`, params);
    params.push(parseInt(limit), offset);
    const result = await pool.query(
      `SELECT t.*, u.nama as kasir_nama FROM transactions t LEFT JOIN users u ON t.kasir_id = u.id ${where} ORDER BY t.waktu DESC LIMIT $${pi} OFFSET $${pi + 1}`,
      params
    );

    res.json({
      success: true, data: result.rows,
      pagination: { page: parseInt(page), limit: parseInt(limit), total: parseInt(countResult.rows[0].count), totalPages: Math.ceil(parseInt(countResult.rows[0].count) / parseInt(limit)) }
    });
  } catch (err) {
    console.error('Get transaksi error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

// GET /api/transaksi/:id - Detail transaksi
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const trx = await pool.query(`SELECT t.*, u.nama as kasir_nama FROM transactions t LEFT JOIN users u ON t.kasir_id = u.id WHERE t.id = $1`, [req.params.id]);
    if (trx.rows.length === 0) return res.status(404).json({ success: false, message: 'Transaksi tidak ditemukan.' });
    const items = await pool.query('SELECT * FROM trx_items WHERE transaksi_id = $1', [req.params.id]);
    res.json({ success: true, data: { ...trx.rows[0], items: items.rows } });
  } catch (err) {
    console.error('Get transaksi detail error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

module.exports = router;
