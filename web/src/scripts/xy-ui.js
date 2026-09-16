// XyStudio UI: select custom, toast, konfirmasi, pesan error ramah.
// Tidak memakai dropdown/alert/confirm bawaan browser.

const FRIENDLY = [
  [/401|403|invalid api|api key tidak valid|unauthorized/i, 'API key Groq tidak valid. Buka Setelan, tempel key baru dari console.groq.com/keys.'],
  [/429|rate limit|quota|kuota|terlalu banyak/i, 'Kuota Groq sedang penuh. Tunggu sebentar, atau biarkan Auto pindah ke model lain.'],
  [/model_terms|orpheus|syarat pemakaian/i, 'Suara Orpheus butuh persetujuan syarat di console Groq. Terima dulu di sana, lalu coba lagi.'],
  [/failed to fetch|networkerror|koneksi|internet|offline/i, 'Tidak ada koneksi internet. Cek Wi-Fi atau data seluler kamu.'],
  [/cors|blocked|blokir/i, 'Browser memblokir baca halaman itu. Coba di aplikasi Android, atau ganti tautan.'],
  [/abort/i, 'Dihentikan.'],
  [/413|too large|terlalu panjang/i, 'Teks terlalu panjang untuk model ini. Persingkat brief-nya.'],
  [/404|not found|tidak ditemukan/i, 'Model atau alamat tidak ditemukan. Pilih model lain di Setelan.'],
  [/5\d\d|server groq|internal/i, 'Server Groq lagi bermasalah. Coba lagi beberapa saat.'],
  [/http \d+/i, 'Groq menolak permintaan. Coba model lain atau ulangi sebentar lagi.'],
];

export function xyFriendlyError(err) {
  const raw = err == null ? '' : (err.message || String(err));
  const status = err && err.status;
  if (status === 401 || status === 403) return FRIENDLY[0][1];
  if (status === 429) return FRIENDLY[1][1];
  if (status === 413) return FRIENDLY[6][1];
  if (status === 404) return FRIENDLY[7][1];
  if (status >= 500) return FRIENDLY[8][1];
  for (const [re, msg] of FRIENDLY) {
    if (re.test(raw)) return msg;
  }
  if (!raw.trim() || /[{[]/.test(raw) || /error/i.test(raw) && raw.length > 160) {
    return 'Generate gagal. Cek API key dan koneksi, lalu ulangi.';
  }
  return raw;
}

function ensureToasts() {
  let box = document.getElementById('xy-toasts');
  if (!box) {
    box = document.createElement('div');
    box.id = 'xy-toasts';
    box.className = 'xy-toasts';
    box.setAttribute('aria-live', 'polite');
    document.body.appendChild(box);
  }
  return box;
}

export function xyToast(message, kind = 'info') {
  const box = ensureToasts();
  const el = document.createElement('div');
  el.className = `xy-toast xy-toast-${kind}`;
  el.innerHTML = `<span>${escapeHtml(String(message))}</span><button type="button" class="xy-toast-x" aria-label="Tutup"></button>`;
  el.querySelector('.xy-toast-x').addEventListener('click', () => el.remove());
  box.appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 280); }, 4200);
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

export function xyConfirm({ title = 'Yakin?', body = '', ok = 'Ya', cancel = 'Batal', danger = false } = {}) {
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'xy-modal-overlay';
    overlay.innerHTML = `
      <div class="xy-modal" role="dialog" aria-modal="true">
        <strong class="xy-modal-title">${escapeHtml(title)}</strong>
        <p class="xy-modal-body">${escapeHtml(body)}</p>
        <div class="xy-modal-actions">
          <button type="button" class="btn ghost sm" data-no>${escapeHtml(cancel)}</button>
          <button type="button" class="btn sm ${danger ? 'stop' : ''}" data-yes>${escapeHtml(ok)}</button>
        </div>
      </div>`;
    const close = (val) => { overlay.remove(); resolve(val); };
    overlay.addEventListener('click', (e) => { if (e.target === overlay) close(false); });
    overlay.querySelector('[data-no]').addEventListener('click', () => close(false));
    overlay.querySelector('[data-yes]').addEventListener('click', () => close(true));
    document.body.appendChild(overlay);
    overlay.querySelector('[data-yes]').focus();
  });
}

function enhanceSelect(select) {
  if (select.dataset.xyEnhanced) return;
  select.dataset.xyEnhanced = '1';
  select.classList.add('xy-native');
  select.setAttribute('tabindex', '-1');
  select.setAttribute('aria-hidden', 'true');

  const wrap = document.createElement('div');
  wrap.className = 'xy-select';
  select.parentNode.insertBefore(wrap, select);
  wrap.appendChild(select);

  const btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'xy-select-btn';
  btn.setAttribute('aria-haspopup', 'listbox');
  btn.innerHTML = `<span class="xy-select-value"></span><span class="xy-select-caret" aria-hidden="true"></span>`;
  wrap.appendChild(btn);

  const menu = document.createElement('ul');
  menu.className = 'xy-select-menu';
  menu.hidden = true;
  menu.setAttribute('role', 'listbox');
  wrap.appendChild(menu);

  const valueEl = btn.querySelector('.xy-select-value');

  function optionLabel(opt) {
    return (opt && (opt.textContent || opt.label || opt.value)) || '';
  }

  function rebuild() {
    menu.innerHTML = '';
    Array.from(select.options).forEach((opt, i) => {
      const li = document.createElement('li');
      li.setAttribute('role', 'option');
      li.dataset.value = opt.value;
      li.textContent = optionLabel(opt);
      if (opt.disabled) li.setAttribute('aria-disabled', 'true');
      if (opt.selected || select.selectedIndex === i) li.setAttribute('aria-selected', 'true');
      li.addEventListener('click', () => {
        if (opt.disabled) return;
        select.selectedIndex = i;
        select.dispatchEvent(new Event('change', { bubbles: true }));
        sync();
        close();
      });
      menu.appendChild(li);
    });
    sync();
  }

  function sync() {
    const opt = select.options[select.selectedIndex];
    valueEl.textContent = optionLabel(opt) || 'Pilih';
    menu.querySelectorAll('[role="option"]').forEach((li) => {
      li.setAttribute('aria-selected', li.dataset.value === select.value ? 'true' : 'false');
    });
  }

  function open() {
    document.querySelectorAll('.xy-select.open').forEach((el) => {
      if (el !== wrap) {
        el.classList.remove('open');
        const m = el.querySelector('.xy-select-menu');
        if (m) m.hidden = true;
      }
    });
    wrap.classList.add('open');
    menu.hidden = false;
    btn.setAttribute('aria-expanded', 'true');
  }
  function close() {
    wrap.classList.remove('open');
    menu.hidden = true;
    btn.setAttribute('aria-expanded', 'false');
  }

  btn.addEventListener('click', (e) => {
    e.preventDefault();
    if (wrap.classList.contains('open')) close(); else open();
  });
  document.addEventListener('click', (e) => {
    if (!wrap.contains(e.target)) close();
  });
  select.addEventListener('change', sync);
  rebuild();
}

function enhanceAllSelects(root = document) {
  root.querySelectorAll('select').forEach(enhanceSelect);
}

function wireForms(root = document) {
  root.querySelectorAll('form[data-xy-form]').forEach((form) => {
    form.setAttribute('novalidate', 'novalidate');
    form.addEventListener('submit', (e) => {
      let ok = true;
      form.querySelectorAll('[data-xy-error]').forEach((n) => n.remove());
      form.querySelectorAll('input, textarea, select').forEach((field) => {
        if (!field.required) return;
        const empty = !String(field.value || '').trim();
        if (empty) {
          ok = false;
          const msg = field.getAttribute('data-error') || 'Kolom ini wajib diisi.';
          const p = document.createElement('p');
          p.className = 'xy-field-error';
          p.setAttribute('data-xy-error', '');
          p.textContent = msg;
          field.closest('label, .bug-field, .field')?.appendChild(p) || field.after(p);
          field.classList.add('xy-invalid');
        } else {
          field.classList.remove('xy-invalid');
        }
      });
      if (!ok) {
        e.preventDefault();
        e.stopImmediatePropagation();
        xyToast('Lengkapi dulu kolom yang masih kosong.', 'error');
      }
    }, true);
  });
}

function boot() {
  enhanceAllSelects();
  wireForms();
  const obs = new MutationObserver((muts) => {
    for (const m of muts) {
      m.addedNodes.forEach((n) => {
        if (n.nodeType !== 1) return;
        if (n.matches?.('select')) enhanceSelect(n);
        else if (n.querySelectorAll) n.querySelectorAll('select').forEach(enhanceSelect);
      });
    }
  });
  obs.observe(document.body, { childList: true, subtree: true });
}

window.xyFriendlyError = xyFriendlyError;
window.xyToast = xyToast;
window.xyConfirm = xyConfirm;
window.xyEnhanceSelects = enhanceAllSelects;

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', boot);
} else {
  boot();
}
