const express = require('express');
const pool = require('../config/db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');
const { generateSKU, paginateQuery } = require('../utils/helpers');

const router = express.Router();

/**
 * GET /api/produk
 * List semua produk dengan pagination, search, filter
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, search, kategori_id, stok_kritis } = req.query;
    const { limit: lim, offset } = paginateQuery(parseInt(page), parseInt(limit));

    let whereClause = 'WHERE p.is_active = true';
    const params = [];
    let paramIndex = 1;

    if (search) {
      whereClause += ` AND (p.nama ILIKE $${paramIndex} OR p.sku ILIKE $${paramIndex})`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (kategori_id) {
      whereClause += ` AND p.kategori_id = $${paramIndex}`;
      params.push(kategori_id);
      paramIndex++;
    }

    if (stok_kritis === 'true') {
      whereClause += ` AND p.stok <= p.stok_minimum`;
    }

    // Count total
    const countResult = await pool.query(
      `SELECT COUNT(*) FROM products p ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count);

    // Get data
    params.push(lim, offset);
    const result = await pool.query(
      `SELECT p.*, c.nama as kategori_nama 
       FROM products p 
       LEFT JOIN categories c ON p.kategori_id = c.id 
       ${whereClause} 
       ORDER BY p.created_at DESC 
       LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`,
      params
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page: parseInt(page),
        limit: lim,
        total,
        totalPages: Math.ceil(total / lim)
      }
    });
  } catch (err) {
    console.error('Get produk error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * GET /api/produk/categories
 * List semua kategori
 */
router.get('/categories', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM categories ORDER BY nama ASC');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Get categories error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * GET /api/produk/:id
 * Detail produk
 */
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, c.nama as kategori_nama 
       FROM products p 
       LEFT JOIN categories c ON p.kategori_id = c.id 
       WHERE p.id = $1`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Get produk detail error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * POST /api/produk
 * Tambah produk baru
 */
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const {
      nama, sku, kategori_id, satuan, harga_beli, harga_jual,
      stok, stok_minimum, foto_url, tanggal_masuk, exp_date
    } = req.body;

    if (!nama || !harga_jual) {
      return res.status(400).json({
        success: false,
        message: 'Nama dan harga jual wajib diisi.'
      });
    }

    const productSku = sku || generateSKU();

    const result = await pool.query(
      `INSERT INTO products (sku, nama, kategori_id, satuan, harga_beli, harga_jual, stok, stok_minimum, foto_url, tanggal_masuk, exp_date) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) 
       RETURNING *`,
      [productSku, nama, kategori_id || null, satuan || 'pcs', harga_beli || 0, harga_jual, stok || 0, stok_minimum || 5, foto_url || null, tanggal_masuk || new Date(), exp_date || null]
    );

    // Log stok masuk awal
    if (stok && stok > 0) {
      await pool.query(
        `INSERT INTO stock_logs (produk_id, tipe, qty, ref_type, keterangan) 
         VALUES ($1, 'in', $2, 'initial', 'Stok awal produk')`,
        [result.rows[0].id, stok]
      );
    }

    res.status(201).json({
      success: true,
      message: 'Produk berhasil ditambahkan.',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Create produk error:', err);
    if (err.code === '23505') {
      return res.status(409).json({ success: false, message: 'SKU sudah digunakan.' });
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * PUT /api/produk/:id
 * Update produk
 */
router.put('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      nama, sku, kategori_id, satuan, harga_beli, harga_jual,
      stok_minimum, foto_url, exp_date
    } = req.body;

    const result = await pool.query(
      `UPDATE products SET 
        nama = COALESCE($1, nama),
        sku = COALESCE($2, sku),
        kategori_id = $3,
        satuan = COALESCE($4, satuan),
        harga_beli = COALESCE($5, harga_beli),
        harga_jual = COALESCE($6, harga_jual),
        stok_minimum = COALESCE($7, stok_minimum),
        foto_url = $8,
        exp_date = $9,
        updated_at = NOW()
       WHERE id = $10 
       RETURNING *`,
      [nama, sku, kategori_id || null, satuan, harga_beli, harga_jual, stok_minimum, foto_url || null, exp_date || null, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
    }

    res.json({
      success: true,
      message: 'Produk berhasil diupdate.',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Update produk error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * DELETE /api/produk/:id
 * Soft delete produk
 */
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      'UPDATE products SET is_active = false, updated_at = NOW() WHERE id = $1 RETURNING id, nama',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Produk tidak ditemukan.' });
    }

    res.json({
      success: true,
      message: `Produk "${result.rows[0].nama}" berhasil dihapus.`
    });
  } catch (err) {
    console.error('Delete produk error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * POST /api/produk/categories
 * Tambah kategori baru
 */
router.post('/categories', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { nama, deskripsi } = req.body;
    if (!nama) {
      return res.status(400).json({ success: false, message: 'Nama kategori wajib diisi.' });
    }

    const result = await pool.query(
      'INSERT INTO categories (nama, deskripsi) VALUES ($1, $2) RETURNING *',
      [nama, deskripsi || null]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ success: false, message: 'Kategori sudah ada.' });
    }
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

module.exports = router;
