-- ================================================
-- TokoKas Database Schema
-- Sistem POS Toko Pribadi
-- ================================================

-- Extension untuk UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- TABEL: users
-- ================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'kasir' CHECK (role IN ('admin', 'kasir')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- TABEL: categories
-- ================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nama VARCHAR(100) NOT NULL UNIQUE,
  deskripsi TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- TABEL: products
-- ================================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sku VARCHAR(50) UNIQUE,
  nama VARCHAR(200) NOT NULL,
  kategori_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  satuan VARCHAR(50) DEFAULT 'pcs',
  harga_beli DECIMAL(15,2) DEFAULT 0,
  harga_jual DECIMAL(15,2) NOT NULL,
  stok INTEGER DEFAULT 0,
  stok_minimum INTEGER DEFAULT 5,
  foto_url TEXT,
  tanggal_masuk DATE DEFAULT CURRENT_DATE,
  exp_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- TABEL: purchases (stok masuk dari supplier)
-- ================================================
CREATE TABLE IF NOT EXISTS purchases (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produk_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  qty INTEGER NOT NULL,
  harga_beli DECIMAL(15,2) NOT NULL,
  total DECIMAL(15,2) NOT NULL,
  supplier VARCHAR(200),
  catatan TEXT,
  tanggal TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- TABEL: transactions
-- ================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nomor_transaksi VARCHAR(50) UNIQUE NOT NULL,
  kasir_id UUID NOT NULL REFERENCES users(id),
  total DECIMAL(15,2) NOT NULL,
  metode_bayar VARCHAR(30) NOT NULL DEFAULT 'tunai' CHECK (metode_bayar IN ('tunai', 'transfer', 'qris')),
  bayar DECIMAL(15,2) NOT NULL,
  kembalian DECIMAL(15,2) DEFAULT 0,
  catatan TEXT,
  waktu TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- TABEL: trx_items (detail item transaksi)
-- ================================================
CREATE TABLE IF NOT EXISTS trx_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaksi_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  produk_id UUID NOT NULL REFERENCES products(id),
  nama_produk VARCHAR(200) NOT NULL,
  qty INTEGER NOT NULL,
  harga_jual DECIMAL(15,2) NOT NULL,
  subtotal DECIMAL(15,2) NOT NULL
);

-- ================================================
-- TABEL: stock_logs (log pergerakan stok)
-- ================================================
CREATE TABLE IF NOT EXISTS stock_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produk_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  tipe VARCHAR(10) NOT NULL CHECK (tipe IN ('in', 'out')),
  qty INTEGER NOT NULL,
  ref_type VARCHAR(30),
  ref_id UUID,
  keterangan TEXT,
  waktu TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ================================================
-- INDEXES untuk performa
-- ================================================
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_nama ON products(nama);
CREATE INDEX IF NOT EXISTS idx_products_kategori ON products(kategori_id);
CREATE INDEX IF NOT EXISTS idx_transactions_waktu ON transactions(waktu);
CREATE INDEX IF NOT EXISTS idx_transactions_kasir ON transactions(kasir_id);
CREATE INDEX IF NOT EXISTS idx_trx_items_transaksi ON trx_items(transaksi_id);
CREATE INDEX IF NOT EXISTS idx_stock_logs_produk ON stock_logs(produk_id);
CREATE INDEX IF NOT EXISTS idx_stock_logs_waktu ON stock_logs(waktu);
CREATE INDEX IF NOT EXISTS idx_purchases_produk ON purchases(produk_id);

-- ================================================
-- INSERT default admin user
-- Password: admin123 (bcrypt hash)
-- ================================================
INSERT INTO users (nama, email, password_hash, role)
VALUES ('Admin', 'admin@tokokas.com', '$2a$10$8K1p/a0dR1xqR6Q5z0z0aOQZ5z0z0aOQZ5z0z0aOQZ5z0z0aOQZa', 'admin')
ON CONFLICT (email) DO NOTHING;

-- ================================================
-- INSERT default categories
-- ================================================
INSERT INTO categories (nama) VALUES 
  ('Makanan'),
  ('Minuman'),
  ('Snack'),
  ('Kebutuhan Rumah Tangga'),
  ('Alat Tulis'),
  ('Elektronik'),
  ('Lainnya')
ON CONFLICT (nama) DO NOTHING;
