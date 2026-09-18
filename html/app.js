/* LXR-LOVE — the consent card | © 2026 iBoss21 / LXRCore */
(function () {
  const $ = (id) => document.getElementById(id);
  const card = $('card');
  let L = {}, left = 0, total = 1, timer = null;
  const t = (k, vars) => { let s = L[k] || k.split('.').pop().replace(/_/g, ' '); if (vars) for (const v in vars) s = s.replace('%{' + v + '}', vars[v]); return s; };
  function applyLocale() { document.querySelectorAll('[data-l]').forEach(el => { const k = 'ui.' + el.dataset.l; if (L[k]) el.textContent = L[k]; }); }
  function tick() { $('clock').textContent = Math.max(0, Math.ceil(left / 1000)) + 's'; $('meter').style.width = Math.round(Math.max(0, left) / total * 100) + '%'; left -= 250; if (left < 0) clearInterval(timer); }
  window.addEventListener('message', e => {
    const m = e.data || {};
    if (m.brand && m.brand.theme) document.documentElement.dataset.theme = m.brand.theme;
    if (m.locale) { L = m.locale; applyLocale(); }
    if (m.lang) document.body.classList.toggle('lang-ka', m.lang === 'ka');
    if (m.action === 'ask') { const p = m.payload || {}; $('name').textContent = p.name || ''; $('what').textContent = t('ask.' + p.id); total = Number(p.timeout) || 15000; left = total; tick(); clearInterval(timer); timer = setInterval(tick, 250); card.classList.remove('lxr-hidden'); }
    if (m.action === 'hide') { card.classList.add('lxr-hidden'); clearInterval(timer); }
  });
  if (window.__LXR_MOCK__) window.postMessage(window.__LXR_MOCK__, '*');
})();
