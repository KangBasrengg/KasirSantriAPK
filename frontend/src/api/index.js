const API_BASE = import.meta.env.VITE_API_URL || '/api';

const getToken = () => localStorage.getItem('tokokas_token');

const headers = () => ({
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${getToken()}`
});

const handleResponse = async (res) => {
  const data = await res.json();
  if (!res.ok) throw new Error(data.message || 'Terjadi kesalahan');
  return data;
};

// Auth
export const login = (email, password) =>
  fetch(`${API_BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) }).then(handleResponse);

export const getMe = () =>
  fetch(`${API_BASE}/auth/me`, { headers: headers() }).then(handleResponse);

export const getUsers = () =>
  fetch(`${API_BASE}/auth/users`, { headers: headers() }).then(handleResponse);

export const registerUser = (data) =>
  fetch(`${API_BASE}/auth/register`, { method: 'POST', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

export const updateUser = (id, data) =>
  fetch(`${API_BASE}/auth/users/${id}`, { method: 'PUT', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

// Products
export const getProducts = (params = {}) => {
  const q = new URLSearchParams(params).toString();
  return fetch(`${API_BASE}/produk?${q}`, { headers: headers() }).then(handleResponse);
};

export const getProduct = (id) =>
  fetch(`${API_BASE}/produk/${id}`, { headers: headers() }).then(handleResponse);

export const createProduct = (data) =>
  fetch(`${API_BASE}/produk`, { method: 'POST', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

export const updateProduct = (id, data) =>
  fetch(`${API_BASE}/produk/${id}`, { method: 'PUT', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

export const deleteProduct = (id) =>
  fetch(`${API_BASE}/produk/${id}`, { method: 'DELETE', headers: headers() }).then(handleResponse);

export const getCategories = () =>
  fetch(`${API_BASE}/produk/categories`, { headers: headers() }).then(handleResponse);

export const createCategory = (data) =>
  fetch(`${API_BASE}/produk/categories`, { method: 'POST', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

// Transactions
export const createTransaction = (data) =>
  fetch(`${API_BASE}/transaksi`, { method: 'POST', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

export const getTransactions = (params = {}) => {
  const q = new URLSearchParams(params).toString();
  return fetch(`${API_BASE}/transaksi?${q}`, { headers: headers() }).then(handleResponse);
};

export const getTransaction = (id) =>
  fetch(`${API_BASE}/transaksi/${id}`, { headers: headers() }).then(handleResponse);

// Purchases
export const createPurchase = (data) =>
  fetch(`${API_BASE}/pembelian`, { method: 'POST', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);

export const getPurchases = (params = {}) => {
  const q = new URLSearchParams(params).toString();
  return fetch(`${API_BASE}/pembelian?${q}`, { headers: headers() }).then(handleResponse);
};

// Reports
export const getDashboard = () =>
  fetch(`${API_BASE}/laporan/dashboard`, { headers: headers() }).then(handleResponse);

export const getSalesReport = (params = {}) => {
  const q = new URLSearchParams(params).toString();
  return fetch(`${API_BASE}/laporan/penjualan?${q}`, { headers: headers() }).then(handleResponse);
};

export const getStockReport = () =>
  fetch(`${API_BASE}/laporan/stok`, { headers: headers() }).then(handleResponse);

export const getTopProducts = (params = {}) => {
  const q = new URLSearchParams(params).toString();
  return fetch(`${API_BASE}/laporan/produk-terlaris?${q}`, { headers: headers() }).then(handleResponse);
};

export const getProfitReport = () =>
  fetch(`${API_BASE}/laporan/laba`, { headers: headers() }).then(handleResponse);

export const updateProfile = (data) =>
  fetch(`${API_BASE}/auth/profile`, { method: 'PUT', headers: headers(), body: JSON.stringify(data) }).then(handleResponse);
