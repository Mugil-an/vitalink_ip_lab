document.addEventListener('DOMContentLoaded', () => {
  const { API_BASE, ensureAuth, authHeaders, showMessage, logout, setStatus } = window.common;

  if (!ensureAuth()) return;
  setStatus('Signed in');

  $('#logout').on('click', logout);

  const renderPatients = (items = []) => {
    const list = $('#patient-list');
    if (!items.length) {
      list.html('<div class="empty">No patients found</div>');
      return;
    }

    list.html(
      items
        .map(
          (p) => `
            <div class="list-item">
              <div>
                <div class="title">${p.name || p.op_num}</div>
                <div class="meta">OP: ${p.op_num} • Doctor: ${p.assigned_doctor_id || 'N/A'}</div>
              </div>
              <div class="meta">${p.contact_no || ''}</div>
            </div>
          `
        )
        .join('')
    );
  };

  const loadPatients = async () => {
    showMessage('[data-msg="patient"]', 'Loading...', 'info');
    try {
      const res = await fetch(`${API_BASE}/admin/patients`, {
        headers: authHeaders(),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to load patients');
      renderPatients(data?.data || []);
      showMessage('[data-msg="patient"]', '');
    } catch (err) {
      showMessage('[data-msg="patient"]', err.message, 'error');
    }
  };

  $('#refresh-patients').on('click', loadPatients);

  $('#create-patient-form').on('submit', async (e) => {
    e.preventDefault();
    const form = e.target;
    const payload = {
      assigned_doctor_id: form.assigned_doctor_id.value.trim(),
      op_num: form.op_num.value.trim(),
      name: form.name.value.trim(),
      password: form.password.value,
      age: form.age.value ? Number(form.age.value) : undefined,
      gender: form.gender.value,
      contact_no: form.contact_no.value.trim(),
      target_inr_min: form.target_inr_min.value ? Number(form.target_inr_min.value) : undefined,
      target_inr_max: form.target_inr_max.value ? Number(form.target_inr_max.value) : undefined,
      therapy: form.therapy.value,
      therapy_start_date: form.therapy_start_date.value.trim(),
      prescription: form.prescription.value,
      medical_history: form.medical_history.value,
      kin_name: form.kin_name.value.trim(),
      kin_relation: form.kin_relation.value.trim(),
      kin_contact_number: form.kin_contact_number.value.trim(),
    };

    showMessage('[data-msg="patient"]', 'Creating...', 'info');

    try {
      const res = await fetch(`${API_BASE}/admin/createPatient`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify(payload),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message || 'Failed to create patient');
      showMessage('[data-msg="patient"]', 'Patient created', 'success');
      form.reset();
      loadPatients();
    } catch (err) {
      showMessage('[data-msg="patient"]', err.message, 'error');
    }
  });

  loadPatients();
});
