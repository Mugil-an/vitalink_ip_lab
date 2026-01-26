document.addEventListener('DOMContentLoaded', () => {
  const { API_BASE, ensureAuth, authFetch, showMessage, logout, setStatus } = window.common;

  if (!ensureAuth()) return;
  setStatus('Signed in');

  $('#logout').on('click', logout);

  const renderDoctors = (items = []) => {
    const list = $('#doctor-list');
    if (!items.length) {
      list.html('<div class="empty">No doctors found</div>');
      return;
    }

    list.html(
      items
        .map(
          (doc) => `
            <div class="list-item">
              <div>
                <div class="title">${doc.name || doc.login_id}</div>
                <div class="meta">${doc.login_id} • ${doc.department || 'N/A'}</div>
              </div>
              <div class="meta">${doc.contact_number || ''}</div>
            </div>
          `
        )
        .join('')
    );
  };

  const loadDoctors = async () => {
    showMessage('[data-msg="doctor"]', 'Loading...', 'info');
    try {
      const res = await authFetch(`${API_BASE}/admin/doctors`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to load doctors');
      renderDoctors(data?.data || []);
      showMessage('[data-msg="doctor"]', '');
    } catch (err) {
      showMessage('[data-msg="doctor"]', err.message, 'error');
    }
  };

  $('#refresh-doctors').on('click', loadDoctors);

  $('#create-doctor-form').on('submit', async (e) => {
    e.preventDefault();
    const payload = {
      login_id: e.target.login_id.value.trim(),
      name: e.target.name.value.trim(),
      department: e.target.department.value.trim(),
      password: e.target.password.value,
      contact_number: e.target.contact_number.value.trim(),
    };

    showMessage('[data-msg="doctor"]', 'Creating...', 'info');

    try {
      const res = await authFetch(`${API_BASE}/admin/doctors`, {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to create doctor');
      showMessage('[data-msg="doctor"]', 'Doctor created', 'success');
      e.target.reset();
      loadDoctors();
    } catch (err) {
      showMessage('[data-msg="doctor"]', err.message, 'error');
    }
  });

  loadDoctors();
});
