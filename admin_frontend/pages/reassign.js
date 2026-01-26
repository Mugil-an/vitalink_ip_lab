document.addEventListener('DOMContentLoaded', () => {
  const { API_BASE, ensureAuth, authFetch, showMessage, logout, setStatus } = window.common;

  if (!ensureAuth()) return;
  setStatus('Signed in');

  $('#logout').on('click', logout);

  $('#reassign-form').on('submit', async (e) => {
    e.preventDefault();
    const payload = {
      op_num: e.target.op_num.value.trim(),
      new_doctor_id: e.target.new_doctor_id.value.trim(),
    };

    showMessage('#reassign-message', 'Submitting...', 'info');

    try {
      const res = await authFetch(`${API_BASE}/admin/reassignPatient`, {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to reassign');
      showMessage('#reassign-message', 'Patient reassigned', 'success');
      e.target.reset();
    } catch (err) {
      showMessage('#reassign-message', err.message, 'error');
    }
  });
});
