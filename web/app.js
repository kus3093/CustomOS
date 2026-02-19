'use strict';

// ── Mock data ──────────────────────────────────────────────────────────────

const STORE = {
  kpis: {
    revenue:  { value: 4837.50, delta: 12.4,  dir: 'positive' },
    txns:     { value: 137,     delta: 8.2,   dir: 'positive' },
    aov:      { value: 35.31,   delta: 0.0,   dir: 'neutral'  },
    items:    { value: 412,     delta: -3.1,  dir: 'negative' },
  },

  // Hourly revenue ($) for hours 08–20
  hourly: [210, 390, 480, 550, 620, 700, 830, 760, 890, 940, 680, 540, 250],
  hours:  ['8','9','10','11','12','13','14','15','16','17','18','19','20'],

  staff: [
    { name: 'Maya Chen',    role: 'Store Manager',   status: 'online',  color: '#7c3aed' },
    { name: 'James Rivera', role: 'Cashier',          status: 'online',  color: '#0891b2' },
    { name: 'Sofia Park',   role: 'Sales Associate',  status: 'break',   color: '#be185d' },
    { name: 'Liam Torres',  role: 'Stock Handler',    status: 'online',  color: '#047857' },
    { name: 'Ava Nguyen',   role: 'Cashier',          status: 'online',  color: '#b45309' },
  ],

  transactions: [
    { id: '#10392', time: '17:44', items: 3,  cashier: 'James R.', total: 47.20,  status: 'complete' },
    { id: '#10391', time: '17:41', items: 1,  cashier: 'Ava N.',   total: 12.99,  status: 'complete' },
    { id: '#10390', time: '17:38', items: 6,  cashier: 'James R.', total: 88.50,  status: 'pending'  },
    { id: '#10389', time: '17:30', items: 2,  cashier: 'Ava N.',   total: 24.00,  status: 'refunded' },
    { id: '#10388', time: '17:25', items: 4,  cashier: 'James R.', total: 63.75,  status: 'complete' },
    { id: '#10387', time: '17:19', items: 1,  cashier: 'Ava N.',   total: 9.99,   status: 'complete' },
    { id: '#10386', time: '17:10', items: 8,  cashier: 'James R.', total: 114.40, status: 'complete' },
  ],

  inventory: [
    { name: 'Organic Milk 1L',       sku: 'DRY-001', stock: 4,   threshold: 10, status: 'critical' },
    { name: 'Sourdough Bread',        sku: 'BAK-014', stock: 7,   threshold: 15, status: 'low'      },
    { name: 'Sparkling Water 6pk',    sku: 'DRK-022', stock: 9,   threshold: 12, status: 'low'      },
    { name: 'Cheddar Cheese 250g',    sku: 'DRY-009', stock: 12,  threshold: 10, status: 'ok'       },
    { name: 'Free-Range Eggs 12pk',   sku: 'DRY-003', stock: 2,   threshold: 8,  status: 'critical' },
    { name: 'Extra Virgin Olive Oil', sku: 'PNT-007', stock: 18,  threshold: 10, status: 'ok'       },
  ],
};

// ── Clock ──────────────────────────────────────────────────────────────────

function updateClock() {
  const now = new Date();
  const clock = document.getElementById('clock');
  const dateEl = document.getElementById('date-display');

  clock.textContent = now.toLocaleTimeString('en-US', {
    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false,
  });

  dateEl.textContent = now.toLocaleDateString('en-US', {
    weekday: 'short', year: 'numeric', month: 'short', day: 'numeric',
  });
}

// ── KPI Cards ──────────────────────────────────────────────────────────────

function renderKPIs() {
  const { revenue, txns, aov, items } = STORE.kpis;

  const fmt = (v, money = true) =>
    money ? '$' + v.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',') : v.toLocaleString();

  const delta = (d, dir) => {
    const arrow = dir === 'positive' ? '↑' : dir === 'negative' ? '↓' : '→';
    return `${arrow} ${Math.abs(d).toFixed(1)}%`;
  };

  document.getElementById('kpi-revenue').textContent      = fmt(revenue.value);
  document.getElementById('kpi-revenue-delta').textContent = delta(revenue.delta, revenue.dir);
  document.getElementById('kpi-revenue-delta').className  = `kpi-delta ${revenue.dir}`;

  document.getElementById('kpi-txns').textContent         = fmt(txns.value, false);
  document.getElementById('kpi-txns-delta').textContent   = delta(txns.delta, txns.dir);
  document.getElementById('kpi-txns-delta').className     = `kpi-delta ${txns.dir}`;

  document.getElementById('kpi-aov').textContent          = fmt(aov.value);
  document.getElementById('kpi-aov-delta').textContent    = delta(aov.delta, aov.dir);
  document.getElementById('kpi-aov-delta').className      = `kpi-delta ${aov.dir}`;

  document.getElementById('kpi-items').textContent        = fmt(items.value, false);
  document.getElementById('kpi-items-delta').textContent  = delta(items.delta, items.dir);
  document.getElementById('kpi-items-delta').className    = `kpi-delta ${items.dir}`;
}

// ── Hourly Chart ───────────────────────────────────────────────────────────

function renderChart() {
  const chart  = document.getElementById('hourly-chart');
  const labels = document.getElementById('chart-labels');
  const max    = Math.max(...STORE.hourly);

  chart.innerHTML  = '';
  labels.innerHTML = '';

  STORE.hourly.forEach((val, i) => {
    const pct = (val / max) * 100;

    const wrap = document.createElement('div');
    wrap.className = 'bar-wrap';

    const tip = document.createElement('div');
    tip.className = 'bar-tip';
    tip.textContent = '$' + val;

    const bar = document.createElement('div');
    bar.className = 'bar';
    bar.style.height = pct + '%';
    bar.title = `${STORE.hours[i]}:00 — $${val}`;

    wrap.appendChild(tip);
    wrap.appendChild(bar);
    chart.appendChild(wrap);

    const label = document.createElement('span');
    label.textContent = STORE.hours[i];
    labels.appendChild(label);
  });
}

// ── Staff ──────────────────────────────────────────────────────────────────

function renderStaff() {
  const list    = document.getElementById('staff-list');
  const countEl = document.getElementById('staff-count');

  list.innerHTML = '';

  const active = STORE.staff.filter(s => s.status === 'online').length;
  countEl.textContent = `${active} active`;

  STORE.staff.forEach(member => {
    const initials = member.name.split(' ').map(n => n[0]).join('');

    const li = document.createElement('li');
    li.className = 'staff-item';
    li.innerHTML = `
      <div class="staff-avatar" style="background:${member.color}20;color:${member.color};border:1px solid ${member.color}40">
        ${initials}
      </div>
      <div>
        <div class="staff-name">${member.name}</div>
        <div class="staff-role">${member.role}</div>
      </div>
      <div class="dot ${member.status}" title="${member.status}"></div>
    `;
    list.appendChild(li);
  });
}

// ── Transactions ───────────────────────────────────────────────────────────

function renderTransactions() {
  const tbody = document.getElementById('txn-body');
  tbody.innerHTML = '';

  STORE.transactions.forEach(t => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><span class="order-num">${t.id}</span></td>
      <td>${t.time}</td>
      <td>${t.items}</td>
      <td>${t.cashier}</td>
      <td>$${t.total.toFixed(2)}</td>
      <td><span class="pill ${t.status}">${t.status}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// Refresh simulates new data arriving at the top
function refreshTransactions() {
  const id     = '#' + (10393 + Math.floor(Math.random() * 10));
  const items  = Math.floor(Math.random() * 8) + 1;
  const total  = (items * (5 + Math.random() * 25)).toFixed(2);
  const cashiers = ['James R.', 'Ava N.'];
  const now    = new Date();
  const time   = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`;

  STORE.transactions.unshift({
    id, time, items, cashier: cashiers[Math.floor(Math.random() * 2)],
    total: parseFloat(total), status: 'complete',
  });

  if (STORE.transactions.length > 10) STORE.transactions.pop();
  renderTransactions();
}

// ── Inventory ──────────────────────────────────────────────────────────────

function renderInventory() {
  const tbody    = document.getElementById('inv-body');
  const alertEl  = document.getElementById('alert-count');
  tbody.innerHTML = '';

  const alerts = STORE.inventory.filter(i => i.status !== 'ok').length;
  alertEl.textContent = `${alerts} low`;

  STORE.inventory.forEach(item => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${item.name}</td>
      <td style="color:var(--muted);font-size:11px">${item.sku}</td>
      <td style="font-weight:600;color:${item.status === 'critical' ? 'var(--red)' : item.status === 'low' ? 'var(--yellow)' : 'var(--green)'}">${item.stock}</td>
      <td style="color:var(--muted)">${item.threshold}</td>
      <td><span class="pill ${item.status}">${item.status}</span></td>
    `;
    tbody.appendChild(tr);
  });
}

// ── Init ───────────────────────────────────────────────────────────────────

function init() {
  updateClock();
  setInterval(updateClock, 1000);

  renderKPIs();
  renderChart();
  renderStaff();
  renderTransactions();
  renderInventory();
}

document.addEventListener('DOMContentLoaded', init);
