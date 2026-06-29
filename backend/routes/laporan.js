const express = require('express');
const pool = require('../config/db');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/laporan/dashboard - Ringkasan dashboard
router.get('/dashboard', authenticateToken, async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10);

    // Omzet hari ini
    const omzetHariIni = await pool.query(
      `SELECT COALESCE(SUM(total), 0) as omzet, COUNT(*) as jumlah_transaksi FROM transactions WHERE waktu::date = $1`,
      [today]
    );

    // Omzet bulan ini
    const omzetBulanIni = await pool.query(
      `SELECT COALESCE(SUM(total), 0) as omzet, COUNT(*) as jumlah_transaksi FROM transactions WHERE DATE_TRUNC('month', waktu) = DATE_TRUNC('month', CURRENT_DATE)`
    );

    // Total produk aktif
    const totalProduk = await pool.query('SELECT COUNT(*) FROM products WHERE is_active = true');

    // Produk stok kritis
    const stokKritis = await pool.query(
      'SELECT COUNT(*) FROM products WHERE stok <= stok_minimum AND is_active = true'
    );

    // Produk terlaris hari ini
    const produkTerlaris = await pool.query(
      `SELECT ti.nama_produk, SUM(ti.qty) as total_qty, SUM(ti.subtotal) as total_penjualan
       FROM trx_items ti JOIN transactions t ON ti.transaksi_id = t.id
       WHERE t.waktu::date = $1
       GROUP BY ti.nama_produk ORDER BY total_qty DESC LIMIT 5`,
      [today]
    );

    // Omzet 7 hari terakhir (untuk chart)
    const omzet7Hari = await pool.query(
      `SELECT waktu::date as tanggal, COALESCE(SUM(total), 0) as omzet, COUNT(*) as jumlah
       FROM transactions WHERE waktu >= CURRENT_DATE - INTERVAL '7 days'
       GROUP BY waktu::date ORDER BY tanggal ASC`
    );

    // Transaksi terakhir
    const trxTerakhir = await pool.query(
      `SELECT t.*, u.nama as kasir_nama FROM transactions t LEFT JOIN users u ON t.kasir_id = u.id ORDER BY t.waktu DESC LIMIT 5`
    );

    res.json({
      success: true,
      data: {
        hari_ini: { omzet: parseFloat(omzetHariIni.rows[0].omzet), jumlah_transaksi: parseInt(omzetHariIni.rows[0].jumlah_transaksi) },
        bulan_ini: { omzet: parseFloat(omzetBulanIni.rows[0].omzet), jumlah_transaksi: parseInt(omzetBulanIni.rows[0].jumlah_transaksi) },
        total_produk: parseInt(totalProduk.rows[0].count),
        stok_kritis: parseInt(stokKritis.rows[0].count),
        produk_terlaris: produkTerlaris.rows,
        omzet_7_hari: omzet7Hari.rows,
        transaksi_terakhir: trxTerakhir.rows
      }
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

// GET /api/laporan/penjualan - Laporan penjualan
router.get('/penjualan', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { periode = 'harian', tanggal_mulai, tanggal_akhir } = req.query;
    let groupBy, dateFormat;

    switch (periode) {
      case 'bulanan':
        groupBy = "DATE_TRUNC('month', waktu)";
        dateFormat = "TO_CHAR(DATE_TRUNC('month', waktu), 'YYYY-MM')";
        break;
      case 'mingguan':
        groupBy = "DATE_TRUNC('week', waktu)";
        dateFormat = "TO_CHAR(DATE_TRUNC('week', waktu), 'YYYY-MM-DD')";
        break;
      default:
        groupBy = "waktu::date";
        dateFormat = "TO_CHAR(waktu::date, 'YYYY-MM-DD')";
    }

    let where = 'WHERE 1=1';
    const params = [];
    let pi = 1;
    if (tanggal_mulai) { where += ` AND waktu >= $${pi}`; params.push(tanggal_mulai); pi++; }
    if (tanggal_akhir) { where += ` AND waktu <= $${pi}`; params.push(tanggal_akhir + 'T23:59:59'); pi++; }

    const result = await pool.query(
      `SELECT ${dateFormat} as periode, COUNT(*) as jumlah_transaksi, 
       COALESCE(SUM(total), 0) as total_penjualan
       FROM transactions ${where}
       GROUP BY ${groupBy} ORDER BY ${groupBy} DESC`,
      params
    );

    // Total keseluruhan
    const totalResult = await pool.query(
      `SELECT COUNT(*) as total_transaksi, COALESCE(SUM(total), 0) as total_omzet FROM transactions ${where}`,
      params
    );

    let summaryWhere = '';
    if (periode === 'bulanan') {
      summaryWhere = "DATE_TRUNC('month', t.waktu) = DATE_TRUNC('month', CURRENT_DATE)";
    } else if (periode === 'mingguan') {
      summaryWhere = "DATE_TRUNC('week', t.waktu) = DATE_TRUNC('week', CURRENT_DATE)";
    } else { // harian
      summaryWhere = "t.waktu::date = CURRENT_DATE";
    }

    const ringkasanPeriode = await pool.query(
      `SELECT 
         COUNT(DISTINCT t.id) as total_transaksi,
         COALESCE(SUM(ti.subtotal), 0) as total_omzet,
         COALESCE(SUM(ti.subtotal) - SUM(p.harga_beli * ti.qty), 0) as total_laba
       FROM transactions t
       LEFT JOIN trx_items ti ON t.id = ti.transaksi_id
       LEFT JOIN products p ON ti.produk_id = p.id
       WHERE ${summaryWhere}`
    );

    const terlarisPeriode = await pool.query(
      `SELECT ti.nama_produk, SUM(ti.qty) as total_terjual
       FROM transactions t
       JOIN trx_items ti ON t.id = ti.transaksi_id
       WHERE ${summaryWhere}
       GROUP BY ti.nama_produk
       ORDER BY total_terjual DESC
       LIMIT 1`
    );

    const stokKritis = await pool.query(
      `SELECT COUNT(*) as jumlah FROM products WHERE stok <= stok_minimum AND is_active = true`
    );

    res.json({
      success: true,
      data: { 
        laporan: result.rows, 
        ringkasan: totalResult.rows[0],
        ringkasan_periode: {
          omzet: ringkasanPeriode.rows[0].total_omzet,
          laba: ringkasanPeriode.rows[0].total_laba,
          transaksi: ringkasanPeriode.rows[0].total_transaksi,
          terlaris: terlarisPeriode.rows.length > 0 ? terlarisPeriode.rows[0].nama_produk : '-',
          stok_kritis: stokKritis.rows[0].jumlah
        }
      }
    });
  } catch (err) {
    console.error('Laporan penjualan error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

// GET /api/laporan/stok - Laporan stok
router.get('/stok', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.id, p.sku, p.nama, p.stok, p.stok_minimum, p.harga_beli, p.harga_jual,
       c.nama as kategori, (p.stok <= p.stok_minimum) as is_kritis
       FROM products p LEFT JOIN categories c ON p.kategori_id = c.id
       WHERE p.is_active = true ORDER BY p.stok ASC`
    );

    const stokLogs = await pool.query(
      `SELECT sl.*, p.nama as produk_nama FROM stock_logs sl
       LEFT JOIN products p ON sl.produk_id = p.id
       ORDER BY sl.waktu DESC LIMIT 50`
    );

    res.json({ success: true, data: { produk: result.rows, log_stok: stokLogs.rows } });
  } catch (err) {
    console.error('Laporan stok error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

// GET /api/laporan/produk-terlaris - Produk terlaris
router.get('/produk-terlaris', authenticateToken, async (req, res) => {
  try {
    const { limit = 10, tanggal_mulai, tanggal_akhir } = req.query;
    let where = '';
    const params = [];
    let pi = 1;
    if (tanggal_mulai) { where += ` AND t.waktu >= $${pi}`; params.push(tanggal_mulai); pi++; }
    if (tanggal_akhir) { where += ` AND t.waktu <= $${pi}`; params.push(tanggal_akhir + 'T23:59:59'); pi++; }

    params.push(parseInt(limit));
    const result = await pool.query(
      `SELECT ti.produk_id, ti.nama_produk, SUM(ti.qty) as total_terjual, SUM(ti.subtotal) as total_pendapatan
       FROM trx_items ti JOIN transactions t ON ti.transaksi_id = t.id
       WHERE 1=1 ${where}
       GROUP BY ti.produk_id, ti.nama_produk ORDER BY total_terjual DESC LIMIT $${pi}`,
      params
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Produk terlaris error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

// GET /api/laporan/laba - Laporan laba (harga_jual - harga_beli)
router.get('/laba', authenticateToken, async (req, res) => {
  try {
    const { periode } = req.query;

    let result;
    if (periode) {
      let groupBy, dateFormat;
      switch (periode) {
        case 'bulanan':
          groupBy = "DATE_TRUNC('month', t.waktu)";
          dateFormat = "TO_CHAR(DATE_TRUNC('month', t.waktu), 'YYYY-MM')";
          break;
        case 'mingguan':
          groupBy = "DATE_TRUNC('week', t.waktu)";
          dateFormat = "TO_CHAR(DATE_TRUNC('week', t.waktu), 'YYYY-MM-DD')";
          break;
        default:
          groupBy = "t.waktu::date";
          dateFormat = "TO_CHAR(t.waktu::date, 'YYYY-MM-DD')";
      }
      result = await pool.query(
        `SELECT 
           ${dateFormat} as periode,
           COALESCE(SUM(ti.subtotal), 0) as total_penjualan,
           COALESCE(SUM(p.harga_beli * ti.qty), 0) as total_modal,
           COALESCE(SUM(ti.subtotal) - SUM(p.harga_beli * ti.qty), 0) as laba
         FROM trx_items ti
         JOIN transactions t ON ti.transaksi_id = t.id
         JOIN products p ON ti.produk_id = p.id
         GROUP BY ${groupBy}
         ORDER BY ${groupBy} DESC`
      );
    } else {
      result = await pool.query(
        `SELECT 
           t.waktu::date as tanggal,
           COALESCE(SUM(ti.subtotal), 0) as total_penjualan,
           COALESCE(SUM(p.harga_beli * ti.qty), 0) as total_modal,
           COALESCE(SUM(ti.subtotal) - SUM(p.harga_beli * ti.qty), 0) as laba
         FROM trx_items ti
         JOIN transactions t ON ti.transaksi_id = t.id
         JOIN products p ON ti.produk_id = p.id
         WHERE t.waktu >= CURRENT_DATE - INTERVAL '7 days'
         GROUP BY t.waktu::date
         ORDER BY tanggal ASC`
      );
    }

    // Laba hari ini
    const today = new Date().toISOString().slice(0, 10);
    const labaHariIni = await pool.query(
      `SELECT 
         COALESCE(SUM(ti.subtotal), 0) as total_penjualan,
         COALESCE(SUM(p.harga_beli * ti.qty), 0) as total_modal,
         COALESCE(SUM(ti.subtotal) - SUM(p.harga_beli * ti.qty), 0) as laba
       FROM trx_items ti
       JOIN transactions t ON ti.transaksi_id = t.id
       JOIN products p ON ti.produk_id = p.id
       WHERE t.waktu::date = $1`,
      [today]
    );

    // Laba bulan ini
    const labaBulanIni = await pool.query(
      `SELECT 
         COALESCE(SUM(ti.subtotal), 0) as total_penjualan,
         COALESCE(SUM(p.harga_beli * ti.qty), 0) as total_modal,
         COALESCE(SUM(ti.subtotal) - SUM(p.harga_beli * ti.qty), 0) as laba
       FROM trx_items ti
       JOIN transactions t ON ti.transaksi_id = t.id
       JOIN products p ON ti.produk_id = p.id
       WHERE DATE_TRUNC('month', t.waktu) = DATE_TRUNC('month', CURRENT_DATE)`
    );

    res.json({
      success: true,
      data: {
        laporan: periode ? result.rows : undefined,
        laba_7_hari: !periode ? result.rows : undefined,
        hari_ini: {
          penjualan: parseFloat(labaHariIni.rows[0].total_penjualan),
          modal: parseFloat(labaHariIni.rows[0].total_modal),
          laba: parseFloat(labaHariIni.rows[0].laba)
        },
        bulan_ini: {
          penjualan: parseFloat(labaBulanIni.rows[0].total_penjualan),
          modal: parseFloat(labaBulanIni.rows[0].total_modal),
          laba: parseFloat(labaBulanIni.rows[0].laba)
        }
      }
    });
  } catch (err) {
    console.error('Laporan laba error:', err);
    res.status(500).json({ success: false, message: 'Terjadi kesalahan server.' });
  }
});

module.exports = router;
