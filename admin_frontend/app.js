'use strict';

const API_BASE = localStorage.getItem('vitalink_api_base') || 'http://localhost:3000/api';
let token = localStorage.getItem('vitalink_token') || '';

const setMessage = (selector, msg, isError = false) => {
  const el = $(selector);
  el.text(msg || '');
  el.toggleClass('error', isError);
  el.toggleClass('success', !isError && msg);
};

const authHeaders = () => (
  token
    ? { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }
    : { 'Content-Type': 'application/json' }
);

const showConsole = (email) => {
  $('#login-card').addClass('hidden');
  $('#console').removeClass('hidden');
  $('#auth-status').text(`Signed in as ${email || 'admin'}`);
};

const handleError = async (resp) => {
  let msg = 'Request failed';
  try {
    const data = await resp.json();
    msg = data.message || data.detail || JSON.stringify(data);
  } catch (_) {
    msg = resp.statusText || msg;
  }
  throw new Error(msg);
};

$(function () {
  if (token) {
    showConsole();
    refreshDoctors();
    refreshPatients();
  }

  $('#login-form').on('submit', async function (e) {
    e.preventDefault();
    setMessage('#login-message', '');
    const body = {
      login_id: this.login_id.value.trim(),
      password: this.password.value,
    };
    try {
      const resp = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!resp.ok) return handleError(resp);
      const data = await resp.json();
      token = data.data?.token || data.token;
      if (!token) throw new Error('Missing token in response');
      localStorage.setItem('vitalink_token', token);
      showConsole(body.login_id);
      setMessage('#login-message', 'Logged in', false);
      refreshDoctors();
      refreshPatients();
    } catch (err) {
      setMessage('#login-message', err.message, true);
    }
  });

  $('#create-doctor-form').on('submit', async function (e) {
    e.preventDefault();
    setMessage('[data-msg="doctor"]', '');
    const body = {
      login_id: this.login_id.value.trim(),
      name: this.name.value.trim(),
      department: this.department.value.trim(),
      password: this.password.value,
      contact_number: this.contact_number.value.trim(),
    };
    try {
      const resp = await fetch(`${API_BASE}/admin/doctors`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify(body),
      });
      if (!resp.ok) return handleError(resp);
      setMessage('[data-msg="doctor"]', 'Doctor created', false);
      this.reset();
      refreshDoctors();
    } catch (err) {
      setMessage('[data-msg="doctor"]', err.message, true);
    }
  });

  $('#create-patient-form').on('submit', async function (e) {
    e.preventDefault();
    setMessage('[data-msg="patient"]', '');
    const parseJson = (raw) => {
      if (!raw.trim()) return undefined;
      try { return JSON.parse(raw); } catch (_) { throw new Error('Invalid JSON'); }
    };

    let prescription;
    let medical_history;
    try {
      prescription = parseJson(this.prescription.value || '');
      medical_history = parseJson(this.medical_history.value || '');
    } catch (err) {
      setMessage('[data-msg="patient"]', err.message, true);
      return;
    }

    const body = {
      assigned_doctor_id: this.assigned_doctor_id.value.trim(),
      op_num: this.op_num.value.trim(),
      name: this.name.value.trim(),
      password: this.password.value,
      age: this.age.value ? Number(this.age.value) : undefined,
      gender: this.gender.value,
      contact_no: this.contact_no.value.trim() || undefined,
      target_inr_min: this.target_inr_min.value ? Number(this.target_inr_min.value) : undefined,
      target_inr_max: this.target_inr_max.value ? Number(this.target_inr_max.value) : undefined,
      therapy: this.therapy.value || undefined,
      therapy_start_date: this.therapy_start_date.value || undefined,
      prescription,
      medical_history,
      kin_name: this.kin_name.value || undefined,
      kin_relation: this.kin_relation.value || undefined,
      kin_contact_number: this.kin_contact_number.value || undefined,
    };

    try {
      const resp = await fetch(`${API_BASE}/admin/patients`, {
        method: 'POST',
        headers: authHeaders(),
        body: JSON.stringify(body),
      });
      if (!resp.ok) return handleError(resp);
      setMessage('[data-msg="patient"]', 'Patient created', false);
      this.reset();
      refreshPatients();
    } catch (err) {
      setMessage('[data-msg="patient"]', err.message, true);
    }
  });

  $('#reassign-form').on('submit', async function (e) {
    e.preventDefault();
    setMessage('[data-msg="reassign"]', '');
    const op = this.op_num.value.trim();
    const body = { new_doctor_id: this.new_doctor_id.value.trim() };
    try {
      const resp = await fetch(`${API_BASE}/admin/patients/${encodeURIComponent(op)}/reassign`, {
        method: 'PATCH',
        headers: authHeaders(),
        body: JSON.stringify(body),
      });
      if (!resp.ok) return handleError(resp);
      setMessage('[data-msg="reassign"]', 'Reassigned', false);
      this.reset();
      refreshPatients();
    } catch (err) {
      setMessage('[data-msg="reassign"]', err.message, true);
    }
  });

  $('#refresh-doctors').on('click', refreshDoctors);
  $('#refresh-patients').on('click', refreshPatients);
});

async function refreshDoctors() {
  const list = $('#doctor-list');
  list.text('Loading...');
  try {
    const resp = await fetch(`${API_BASE}/admin/doctors`, { headers: authHeaders() });
    if (!resp.ok) return handleError(resp);
    const data = await resp.json();
    const doctors = data.data?.doctors || data.doctors || [];
    if (!doctors.length) {
      list.text('No doctors yet.');
      return;
    }
    list.empty();
    doctors.forEach((d) => {
      const div = $('<div class="row"></div>');
      div.text(`${d.login_id || d._id} — ${d.profile_id?.name || d.name || 'Doctor'}`);
      if (d.profile_id?.department) div.append(`<span class="badge">${d.profile_id.department}</span>`);
      list.append(div);
    });
  } catch (err) {
    list.text(err.message);
  }
}

async function refreshPatients() {
  const list = $('#patient-list');
  list.text('Loading...');
  try {
    const resp = await fetch(`${API_BASE}/admin/patients`, { headers: authHeaders() });
    if (!resp.ok) return handleError(resp);
    const data = await resp.json();
    const patients = data.data?.patients || data.patients || [];
    if (!patients.length) {
      list.text('No patients yet.');
      return;
    }
    list.empty();
    patients.forEach((p) => {
      const name = p.profile_id?.demographics?.name || p.name || 'Patient';
      const phone = p.profile_id?.demographics?.phone || '';
      const div = $('<div class="row"></div>');
      div.text(`${p.login_id || p._id} — ${name}${phone ? ' · ' + phone : ''}`);
      list.append(div);
    });
  } catch (err) {
    list.text(err.message);
  }
}
