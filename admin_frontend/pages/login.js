document.addEventListener('DOMContentLoaded', () => {
  const { API_BASE, setToken, setStatus, showMessage } = window.common;

  setStatus('Please sign in');

  $('#login-form').on('submit', async (e) => {
    e.preventDefault();
    showMessage('#login-message', 'Signing in...', 'info');

    const payload = {
      login_id: e.target.login_id.value.trim(),
      password: e.target.password.value,
    };

    try {
      const res = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data?.message || 'Login failed');
      }

      const token = data?.data?.token || data?.data?.accessToken;
      if (!token) {
        throw new Error('Missing token in response');
      }

      setToken(token);
      setStatus('Signed in');
      showMessage('#login-message', 'Success! Redirecting...', 'success');
      setTimeout(() => {
        window.location.href = './doctors.html';
      }, 600);
    } catch (err) {
      showMessage('#login-message', err.message, 'error');
    }
  });
});
