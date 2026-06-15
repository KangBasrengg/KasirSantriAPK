/**
 * Generate nomor transaksi unik
 * Format: TRX-YYYYMMDD-XXXX
 */
const generateNomorTransaksi = () => {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `TRX-${date}-${random}`;
};

/**
 * Generate SKU otomatis
 * Format: SKU-XXXXX
 */
const generateSKU = () => {
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `SKU-${random}`;
};

/**
 * Format angka ke Rupiah
 */
const formatRupiah = (number) => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(number);
};

/**
 * Paginate query helper
 */
const paginateQuery = (page = 1, limit = 20) => {
  const offset = (page - 1) * limit;
  return { limit: Math.min(limit, 100), offset };
};

module.exports = { generateNomorTransaksi, generateSKU, formatRupiah, paginateQuery };
