// Shared helpers across admin pages
const API_BASE = localStorage.getItem('api_base') || 'http://localhost:3000/api';

const getToken = () => localStorage.getItem('token');
const setToken = (token) => localStorage.setItem('token', token || '');
const clearToken = () => localStorage.removeItem('token');

const authHeaders = () => {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
};

const authFetch = (url, options = {}) => {
  const mergedHeaders = { ...authHeaders(), ...(options.headers || {}) };
  return fetch(url, { ...options, headers: mergedHeaders });
};

const setStatus = (text) => {
  const el = document.getElementById('auth-status');
  if (el) el.textContent = text;
};

const ensureAuth = () => {
  const token = getToken();
  if (!token) {
    window.location.href = './login.html';
    return false;
  }
  setStatus('Signed in');
  return true;
};

const showMessage = (selector, message, type = 'info') => {
  const el = document.querySelector(selector);
  if (!el) return;
  el.textContent = message;
  el.className = `message ${type}`;
};

const logout = () => {
  clearToken();
  window.location.href = 'login.html';
};

window.common = {
  API_BASE,
  getToken,
  setToken,
  clearToken,
  authHeaders,
  setStatus,
  ensureAuth,
  showMessage,
  logout,
  authFetch,
};
