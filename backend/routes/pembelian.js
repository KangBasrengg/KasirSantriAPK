const express = require('express');
const pool = require('../config/db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// POST /api/pembelian - Catat stok masuk
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    const { produk_id, qty, harga_beli, supplier, catatan } = req.body;
    if (!produk_id || !qty || !harga_beli) {
      return res.status(400).json({ success: false, message: 'Produk, qty, dan harga beli wajib diisi.' });
    }

    await client.query('BEGIN');
    const total = qty * harga_beli;

    const result = await client.query(
      `INSERT INTO purchases (produk_id, qty, harga_beli, total, supplier, catatan, created_by) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [produk_id, qty, harga_beli, total, supplier || null, catatan || null, req.user.id]
    );

    // Update stok & harga beli produk
    await client.query(
      'UPDATE products SET stok = stok + $1, harga_beli = $2, updated_at = NOW() WHERE id = $3',
      [qty, harga_beli, produk_id]
    );

    // Log stok masuk
    await client.query(
      `INSERT INTO stock_logs (produk_id, tipe, qty, ref_type, ref_id, keterangan) VALUES ($1, 'in', $2, 'pembelian', $3, $4)`,
      [produk_id, qty, result.rows[0].id, `Pembelian dari ${supplier || 'supplier'}`]
    );

    await client.query('COMMIT');
    res.status(201).json({ success: true, message: 'Pembelian berhasil dicatat.', data: result.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Create pembelian error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  } finally {
    client.release();
  }
});

// GET /api/pembelian - Riwayat pembelian
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    const countResult = await pool.query('SELECT COUNT(*) FROM purchases');
    const result = await pool.query(
      `SELECT p.*, pr.nama as produk_nama, pr.sku, u.nama as created_by_nama 
       FROM purchases p 
       LEFT JOIN products pr ON p.produk_id = pr.id 
       LEFT JOIN users u ON p.created_by = u.id 
       ORDER BY p.tanggal DESC LIMIT $1 OFFSET $2`,
      [parseInt(limit), offset]
    );

    res.json({
      success: true, data: result.rows,
      pagination: { page: parseInt(page), limit: parseInt(limit), total: parseInt(countResult.rows[0].count), totalPages: Math.ceil(parseInt(countResult.rows[0].count) / parseInt(limit)) }
    });
  } catch (err) {
    console.error('Get pembelian error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

module.exports = router;
