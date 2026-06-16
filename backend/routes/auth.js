const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

/**
 * POST /api/auth/login
 * Login user
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi.'
      });
    }

    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND is_active = true',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const user = result.rows[0];
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah.'
      });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, nama: user.nama, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      success: true,
      message: 'Login berhasil.',
      data: {
        token,
        user: {
          id: user.id,
          nama: user.nama,
          email: user.email,
          role: user.role
        }
      }
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * POST /api/auth/register
 * Register user baru (admin only)
 */
router.post('/register', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { nama, email, password, role } = req.body;

    if (!nama || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Nama, email, dan password wajib diisi.'
      });
    }

    // Cek apakah email sudah ada
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email sudah terdaftar.'
      });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const userRole = role === 'admin' ? 'admin' : 'kasir';

    const result = await pool.query(
      'INSERT INTO users (nama, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING id, nama, email, role, created_at',
      [nama, email, password_hash, userRole]
    );

    res.status(201).json({
      success: true,
      message: 'User berhasil didaftarkan.',
      data: result.rows[0]
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * GET /api/auth/me
 * Get current user info
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nama, email, role, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Get me error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * GET /api/auth/users
 * Get all users (admin only)
 */
router.get('/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, nama, email, role, is_active, created_at FROM users ORDER BY created_at DESC'
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Get users error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * PUT /api/auth/users/:id
 * Update user (admin only)
 */
router.put('/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, role, is_active, password } = req.body;

    let query, params;

    if (password) {
      const password_hash = await bcrypt.hash(password, 10);
      query = 'UPDATE users SET nama=$1, email=$2, role=$3, is_active=$4, password_hash=$5, updated_at=NOW() WHERE id=$6 RETURNING id, nama, email, role, is_active';
      params = [nama, email, role, is_active, password_hash, id];
    } else {
      query = 'UPDATE users SET nama=$1, email=$2, role=$3, is_active=$4, updated_at=NOW() WHERE id=$5 RETURNING id, nama, email, role, is_active';
      params = [nama, email, role, is_active, id];
    }

    const result = await pool.query(query, params);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
    }

    res.json({ success: true, message: 'User berhasil diupdate.', data: result.rows[0] });
  } catch (err) {
    console.error('Update user error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

/**
 * PUT /api/auth/profile
 * Update own profile (nama & password)
 */
router.put('/profile', authenticateToken, async (req, res) => {
  try {
    const { nama, password_lama, password_baru } = req.body;
    const userId = req.user.id;

    // If changing password, verify old password first
    if (password_baru) {
      if (!password_lama) {
        return res.status(400).json({ success: false, message: 'Password lama wajib diisi.' });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [userId]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User tidak ditemukan.' });
      }
      const isValid = await bcrypt.compare(password_lama, userResult.rows[0].password_hash);
      if (!isValid) {
        return res.status(401).json({ success: false, message: 'Password lama salah.' });
      }
      const newHash = await bcrypt.hash(password_baru, 10);
      const result = await pool.query(
        'UPDATE users SET nama=COALESCE($1, nama), password_hash=$2, updated_at=NOW() WHERE id=$3 RETURNING id, nama, email, role',
        [nama, newHash, userId]
      );
      return res.json({ success: true, message: 'Profil & password berhasil diupdate.', data: result.rows[0] });
    }

    // Only update nama
    if (nama) {
      const result = await pool.query(
        'UPDATE users SET nama=$1, updated_at=NOW() WHERE id=$2 RETURNING id, nama, email, role',
        [nama, userId]
      );
      return res.json({ success: true, message: 'Profil berhasil diupdate.', data: result.rows[0] });
    }

    res.status(400).json({ success: false, message: 'Tidak ada data untuk diupdate.' });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

module.exports = router;
