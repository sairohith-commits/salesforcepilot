/* ═══════════════════════════════════════════════════════════════════════════
   SalesforcePilot — Marriott Revenue Intelligence
   Frontend application logic
   ═══════════════════════════════════════════════════════════════════════════ */

const API_BASE = window.location.origin;   
const PER_PAGE   = 10;
const MAX_HISTORY = 10;

/* Marriott blue palette for charts */
const CHART_COLORS = [
  '#0066ff', '#00b050', '#f59e0b', '#d93025',
  '#0099e6', '#6366f1', '#ec4899', '#14b8a6',
];
const CHART_ALPHA = (hex, a) =>
  hex.replace(/^#/, '').match(/.{2}/g)
     .reduce((s, c, i) => s + (i === 0 ? 'rgba(' : ',') + parseInt(c, 16), '')
  + `,${a})`;

/* ─── DOM refs ─────────────────────────────────────────────────────────────── */
const messagesEl    = document.getElementById('messages');
const inputEl       = document.getElementById('userInput');
const sendBtn       = document.getElementById('sendBtn');
const historyEl     = document.getElementById('historyList');
const clearHistBtn  = document.getElementById('clearHistoryBtn');
const chipContainer = document.getElementById('suggested-prompts');

/* ─── Init ─────────────────────────────────────────────────────────────────── */
window.addEventListener('DOMContentLoaded', () => {
  renderWelcome();
  renderHistory();
  wireInput();
  wireChips();
  clearHistBtn.addEventListener('click', clearHistory);
});

/* ═══════════════════════════════════════════════════════════════════════════
   INPUT WIRING
   ═══════════════════════════════════════════════════════════════════════════ */
function wireInput() {
  inputEl.addEventListener('input', () => {
    inputEl.style.height = 'auto';
    inputEl.style.height = Math.min(inputEl.scrollHeight, 140) + 'px';
  });
  inputEl.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });
  sendBtn.addEventListener('click', sendMessage);
}

function wireChips() {
  chipContainer.querySelectorAll('.chip').forEach(chip => {
    chip.addEventListener('click', () => {
      inputEl.value = chip.dataset.query;
      inputEl.dispatchEvent(new Event('input'));
      sendMessage();
    });
  });
}

/* ═══════════════════════════════════════════════════════════════════════════
   SEND MESSAGE
   ═══════════════════════════════════════════════════════════════════════════ */
async function sendMessage() {
  const question = inputEl.value.trim();
  if (!question) return;

  inputEl.value = '';
  inputEl.style.height = 'auto';
  setSending(true);

  document.getElementById('suggested-prompts').style.display = 'none';
  appendUserBubble(question);
  saveToHistory(question);
  const loadingEl = appendLoadingBubble();
  scrollBottom();

  const t0 = performance.now();

  try {
    const res = await fetch(`${API_BASE}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ question }),
    });

    loadingEl.remove();

    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: `HTTP ${res.status}` }));
      appendErrorBubble(err.detail || 'Request failed');
      return;
    }

    const data = await res.json();
    renderResponse(data, question);
  } catch (err) {
    loadingEl.remove();
    appendErrorBubble(`Could not reach the backend at ${API_BASE}. Is it running?`);
  } finally {
    setSending(false);
    scrollBottom();
    inputEl.focus();
  }
}

/* ═══════════════════════════════════════════════════════════════════════════
   RENDER RESPONSE  — main entry point
   ═══════════════════════════════════════════════════════════════════════════ */
function renderResponse(data, question) {
  const rows    = data.data    || [];
  const columns = data.columns || [];
  const summary = data.summary || '';

  /* ── Per-response closure state ── */
  let allRows      = [...rows];
  let filteredRows = [...rows];
  let activeFilters = {};   /* { colName: value|null } */
  let searchText   = '';
  let sortCol      = null;
  let sortDir      = 'asc';
  let page         = 1;
  let chartInst    = null;

  /* ── Wrapper ── */
  const wrap = document.createElement('div');
  wrap.className = 'agent-message';

  const bubble = document.createElement('div');
  bubble.className = 'agent-bubble ai-message';

  /* ── Avatar ── */
  const avatarEl = document.createElement('div');
  avatarEl.className = 'ai-avatar';
  avatarEl.textContent = 'SF';
  bubble.appendChild(avatarEl);

  /* ── 1. Summary ── */
  const summaryEl = document.createElement('div');
  summaryEl.className = 'summary-text message-content';
  summaryEl.innerHTML = formatResponse(summary);
  bubble.appendChild(summaryEl);

  /* ── 2. Metric cards ── */
  if (allRows.length > 0) {
    const metricsEl = buildMetricCards(allRows, columns);
    bubble.appendChild(metricsEl);
  }

  /* ── 3. Chart ── */
  const showChart = allRows.length > 0 && data.chart_data && data.chart_data.type !== 'table'
                    && data.chart_data.labels && data.chart_data.labels.length > 0;
  let canvasEl = null;
  if (showChart) {
    const chartWrap = document.createElement('div');
    chartWrap.className = 'chart-wrapper';
    canvasEl = document.createElement('canvas');
    chartWrap.appendChild(canvasEl);
    bubble.appendChild(chartWrap);
  }

  /* ── 4. Filter section ── */
  const filterSection = document.createElement('div');
  filterSection.className = 'filter-section';

  const filterableColumns = getFilterableColumns(allRows, columns);

  /* Text search row */
  if (allRows.length > 0) {
    const searchRow = document.createElement('div');
    searchRow.className = 'filter-search-row';
    const searchInput = document.createElement('input');
    searchInput.className = 'filter-input';
    searchInput.placeholder = 'Filter results…';
    searchInput.addEventListener('input', () => {
      searchText = searchInput.value.trim().toLowerCase();
      page = 1;
      applyFilters();
    });
    searchRow.appendChild(searchInput);
    filterSection.appendChild(searchRow);
  }

  /* Category chip rows */
  filterableColumns.forEach(({ col, values }) => {
    const row = document.createElement('div');
    row.className = 'filter-row';

    const colLabel = document.createElement('span');
    colLabel.className = 'filter-col-label';
    colLabel.textContent = humanise(col) + ':';
    row.appendChild(colLabel);

    /* "All" chip */
    const allChip = createFilterChip('All', true, () => {
      activeFilters[col] = null;
      row.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      allChip.classList.add('active');
      page = 1; applyFilters();
    });
    allChip.classList.add('all');
    row.appendChild(allChip);

    values.forEach(val => {
      const chip = createFilterChip(val, false, () => {
        activeFilters[col] = val;
        row.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
        chip.classList.add('active');
        page = 1; applyFilters();
      });
      row.appendChild(chip);
    });

    filterSection.appendChild(row);
  });

  if (allRows.length > 0) bubble.appendChild(filterSection);

  /* ── 5. Table section ── */
  const tableSection = document.createElement('div');
  tableSection.className = 'table-section';

  /* Toolbar: count + export */
  const toolbar = document.createElement('div');
  toolbar.className = 'table-toolbar';

  const countEl = document.createElement('span');
  countEl.className = 'table-count';

  const exportBtn = document.createElement('button');
  exportBtn.className = 'export-btn';
  exportBtn.innerHTML = `
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
         stroke="currentColor" stroke-width="2">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
      <polyline points="7 10 12 15 17 10"/>
      <line x1="12" y1="15" x2="12" y2="3"/>
    </svg>
    Export CSV`;
  exportBtn.addEventListener('click', () => exportCSV(filteredRows, columns, question));
  toolbar.appendChild(countEl);
  toolbar.appendChild(exportBtn);
  tableSection.appendChild(toolbar);

  /* Table container */
  const tableContainer = document.createElement('div');
  tableContainer.className = 'table-container';

  const table = document.createElement('table');
  const thead = document.createElement('thead');
  const tbody = document.createElement('tbody');
  table.appendChild(thead);
  table.appendChild(tbody);
  tableContainer.appendChild(table);
  tableSection.appendChild(tableContainer);

  /* Pagination */
  const paginationEl = document.createElement('div');
  paginationEl.className = 'pagination';
  tableSection.appendChild(paginationEl);

  /* Meta row */
  const metaEl = document.createElement('div');
  metaEl.className = 'meta-row';
  metaEl.innerHTML = `
    <span>Fetched in ${data.query_time_ms ?? '—'}ms</span>
    <span>Data as of ${new Date().toLocaleString('en-US', {
      month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
    })}</span>`;
  tableSection.appendChild(metaEl);

  if (allRows.length > 0) {
    bubble.appendChild(tableSection);
  } else {
    const noData = document.createElement('div');
    noData.className = 'no-data';
    noData.innerHTML = `
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="1.5">
        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
      </svg>
      No records found for this query.`;
    bubble.appendChild(noData);
  }

  wrap.appendChild(bubble);
  messagesEl.appendChild(wrap);

  /* ── Render chart now DOM is appended ── */
  if (showChart && canvasEl) {
    chartInst = renderChart(canvasEl, data.chart_data, columns);
  }

  /* ── Build thead ── */
  function buildThead() {
    thead.innerHTML = '';
    const tr = document.createElement('tr');

    /* Data columns */
    columns.forEach(col => {
      const th = document.createElement('th');
      const sortIconEl = document.createElement('i');
      sortIconEl.className = 'sort-icon';
      th.textContent = humanise(col);
      th.appendChild(sortIconEl);
      if (col === sortCol) {
        th.classList.add(sortDir === 'asc' ? 'sort-asc' : 'sort-desc');
        sortIconEl.textContent = sortDir === 'asc' ? ' ↑' : ' ↓';
      }
      th.addEventListener('click', () => {
        if (sortCol === col) { sortDir = sortDir === 'asc' ? 'desc' : 'asc'; }
        else { sortCol = col; sortDir = 'asc'; }
        page = 1; applyFilters();
      });
      tr.appendChild(th);
    });

    /* Actions column */
    const thActions = document.createElement('th');
    thActions.textContent = 'Actions';
    thActions.style.cursor = 'default';
    tr.appendChild(thActions);
    thead.appendChild(tr);
  }

  /* ── Build tbody for current page ── */
  function buildTbody() {
    tbody.innerHTML = '';
    const start = (page - 1) * PER_PAGE;
    const pageRows = filteredRows.slice(start, start + PER_PAGE);

    if (pageRows.length === 0) {
      const tr = document.createElement('tr');
      const td = document.createElement('td');
      td.colSpan = columns.length + 1;
      td.className = 'no-data';
      td.textContent = 'No matching records.';
      tr.appendChild(td);
      tbody.appendChild(tr);
      return;
    }

    pageRows.forEach(row => {
      const tr = document.createElement('tr');

      columns.forEach(col => {
        const td = document.createElement('td');
        td.innerHTML = formatCell(col, row[col]);
        tr.appendChild(td);
      });

      /* Action buttons */
      const tdActions = document.createElement('td');
      const name = row.group_name || row.company_name || row.property || row.booking || 'Record';
      const property = row.property || name;

      const btnWrap = document.createElement('div');
      btnWrap.className = 'action-btns';
      btnWrap.append(
        mkActionBtn('Site Visit',    () => alert(`Scheduling site visit for "${name}"`)),
        mkActionBtn('Send Proposal', () => alert(`Opening proposal template for "${name}"`)),
        mkActionBtn('Call Manager',  () => alert(`Calling GM at ${property}`)),
        mkActionBtn('View in SF',    () => alert(`Opening Salesforce record for "${name}"`), true),
      );
      tdActions.appendChild(btnWrap);

      tr.appendChild(tdActions);
      tbody.appendChild(tr);
    });
  }

  /* ── Pagination ── */
  function buildPagination() {
    paginationEl.innerHTML = '';
    const total  = filteredRows.length;
    const pages  = Math.max(1, Math.ceil(total / PER_PAGE));
    const start  = total === 0 ? 0 : (page - 1) * PER_PAGE + 1;
    const end    = Math.min(page * PER_PAGE, total);

    const infoEl = document.createElement('span');
    infoEl.className = 'pagination-info';
    infoEl.textContent = total === 0
      ? 'No results'
      : `Showing ${start}–${end} of ${total}`;
    paginationEl.appendChild(infoEl);

    if (pages <= 1) return;

    const btnsEl = document.createElement('div');
    btnsEl.className = 'pagination-btns';

    const prevBtn = document.createElement('button');
    prevBtn.className = 'page-btn';
    prevBtn.textContent = '← Previous';
    prevBtn.disabled = page === 1;
    prevBtn.addEventListener('click', () => { page--; renderTable(); });
    btnsEl.appendChild(prevBtn);

    /* Page number buttons (up to 5 visible) */
    const range = pageRange(page, pages);
    range.forEach(p => {
      if (p === '…') {
        const el = document.createElement('span');
        el.className = 'page-btn';
        el.style.border = 'none'; el.style.cursor = 'default';
        el.textContent = '…';
        btnsEl.appendChild(el);
        return;
      }
      const btn = document.createElement('button');
      btn.className = 'page-btn' + (p === page ? ' active' : '');
      btn.textContent = p;
      btn.addEventListener('click', () => { page = p; renderTable(); });
      btnsEl.appendChild(btn);
    });

    const nextBtn = document.createElement('button');
    nextBtn.className = 'page-btn';
    nextBtn.textContent = 'Next →';
    nextBtn.disabled = page === pages;
    nextBtn.addEventListener('click', () => { page++; renderTable(); });
    btnsEl.appendChild(nextBtn);

    paginationEl.appendChild(btnsEl);
  }

  function updateCount() {
    countEl.textContent = `${filteredRows.length} of ${allRows.length} records`;
  }

  /* ── Filter logic ── */
  function applyFilters() {
    filteredRows = allRows.filter(row => {
      /* Category filters */
      for (const [col, val] of Object.entries(activeFilters)) {
        if (val !== null && row[col] !== val) return false;
      }
      /* Text search across all visible columns */
      if (searchText) {
        const haystack = columns.map(c => String(row[c] ?? '')).join(' ').toLowerCase();
        if (!haystack.includes(searchText)) return false;
      }
      return true;
    });

    /* Sort */
    if (sortCol) {
      filteredRows.sort((a, b) => {
        const va = a[sortCol]; const vb = b[sortCol];
        if (va == null && vb == null) return 0;
        if (va == null) return 1;
        if (vb == null) return -1;
        const cmp = typeof va === 'number' && typeof vb === 'number'
          ? va - vb
          : String(va).localeCompare(String(vb));
        return sortDir === 'asc' ? cmp : -cmp;
      });
    }

    renderTable();
  }

  function renderTable() {
    buildThead();
    buildTbody();
    buildPagination();
    updateCount();
    scrollBottom();
  }

  /* ── Initial render ── */
  if (allRows.length > 0) renderTable();
}

/* ═══════════════════════════════════════════════════════════════════════════
   METRIC CARDS
   ═══════════════════════════════════════════════════════════════════════════ */
function buildMetricCards(rows, columns) {
  const wrap = document.createElement('div');
  wrap.className = 'metric-cards';

  const metrics = computeMetrics(rows, columns);
  metrics.forEach(({ label, value, sub, trend }) => {
    const card = document.createElement('div');
    card.className = 'metric-card';

    const lbl = document.createElement('div');
    lbl.className = 'metric-label';
    lbl.textContent = label;

    const val = document.createElement('div');
    val.className = 'metric-value' +
      (trend === 'up' ? ' positive' : trend === 'down' ? ' negative' : '');
    val.textContent = value;

    card.appendChild(lbl);
    card.appendChild(val);

    if (sub) {
      const subEl = document.createElement('div');
      subEl.className = 'metric-sub';
      subEl.textContent = sub;
      card.appendChild(subEl);
    }
    wrap.appendChild(card);
  });
  return wrap;
}

function computeMetrics(rows, columns) {
  const cols = new Set(columns);

  /* Group bookings / pipeline deals */
  if (cols.has('total_value') && (cols.has('group_name') || cols.has('stage'))) {
    const totalValue = sum(rows, 'total_value');
    const count      = rows.length;
    const avg        = count > 0 ? totalValue / count : 0;
    return [
      { label: 'Total Value',    value: fmtCurrency(totalValue) },
      { label: 'Deal Count',     value: count.toLocaleString() },
      { label: 'Avg Deal Size',  value: fmtCurrency(avg)       },
    ];
  }

  /* Pipeline by stage (deal_count column) */
  if (cols.has('deal_count') && cols.has('stage')) {
    const totalDeals = sum(rows, 'deal_count');
    const totalValue = sum(rows, 'total_value');
    return [
      { label: 'Total Deals',    value: totalDeals.toLocaleString() },
      { label: 'Pipeline Value', value: fmtCurrency(totalValue) },
      { label: 'Stages Tracked', value: rows.length.toString() },
    ];
  }

  /* Revenue forecast */
  if (cols.has('actual_revenue') || cols.has('forecasted_revenue')) {
    const totalActual   = sum(rows, 'actual_revenue');
    const totalBudget   = sum(rows, 'budget_revenue');
    const totalForecast = sum(rows, 'forecasted_revenue');
    const variancePct   = totalBudget > 0
      ? ((totalActual - totalBudget) / totalBudget * 100).toFixed(1)
      : '—';
    const atRisk = rows.filter(r =>
      r.variance_vs_budget_pct != null && r.variance_vs_budget_pct < -10).length;
    const trend = parseFloat(variancePct) >= 0 ? 'up' : 'down';
    return [
      { label: 'Actual Revenue',     value: fmtCurrency(totalActual),
        sub: `Budget: ${fmtCurrency(totalBudget)}` },
      { label: 'Variance vs Budget', value: variancePct !== '—' ? variancePct + '%' : '—',
        trend },
      { label: 'Properties at Risk', value: atRisk.toString(),
        trend: atRisk > 0 ? 'down' : undefined },
    ];
  }

  /* Corporate accounts */
  if (cols.has('company_name') && cols.has('annual_travel_spend')) {
    const avgSpend    = rows.length > 0 ? sum(rows, 'annual_travel_spend') / rows.length : 0;
    const minContact  = rows.reduce((m, r) =>
      r.last_contact_date && (!m || r.last_contact_date > m) ? r.last_contact_date : m, null);
    const staleCount  = rows.filter(r => (r.days_since_contact || 0) > 60).length;
    return [
      { label: 'Total Accounts',   value: rows.length.toString() },
      { label: 'Most Recent Contact',
        value: minContact ? fmtDate(minContact) : '—' },
      { label: 'Avg Annual Spend', value: fmtCurrency(avgSpend),
        sub: staleCount > 0 ? `${staleCount} need attention` : undefined },
    ];
  }

  /* Sales activities */
  if (cols.has('activity_type')) {
    const types  = new Set(rows.map(r => r.activity_type).filter(Boolean));
    const owners = new Set(rows.map(r => r.owner_id).filter(Boolean));
    return [
      { label: 'Total Activities', value: rows.length.toString() },
      { label: 'Activity Types',   value: types.size.toString() },
      { label: 'Active Reps',      value: owners.size.toString() },
    ];
  }

  /* Fallback */
  return [
    { label: 'Records Found', value: rows.length.toLocaleString() },
    { label: 'Columns',       value: columns.length.toString()    },
    { label: 'Status',        value: 'Complete'                   },
  ];
}

/* ═══════════════════════════════════════════════════════════════════════════
   RENDER CHART
   ═══════════════════════════════════════════════════════════════════════════ */
function renderChart(canvas, chartData, columns) {
  const type = resolveChartType(chartData, columns);
  if (!type) return null;

  const datasets = (chartData.datasets || []).map((ds, i) => {
    const color = CHART_COLORS[i % CHART_COLORS.length];
    if (type === 'pie' || type === 'doughnut') {
      return {
        label:           ds.label,
        data:            ds.data,
        backgroundColor: chartData.labels.map((_, j) =>
          CHART_ALPHA(CHART_COLORS[j % CHART_COLORS.length], 0.8)),
        borderColor:     '#fff',
        borderWidth:     2,
      };
    }
    return {
      label:           ds.label,
      data:            ds.data,
      backgroundColor: type === 'line' ? CHART_ALPHA(color, 0.1) : CHART_ALPHA(color, 0.85),
      borderColor:     color,
      borderWidth:     type === 'line' ? 2 : 1,
      fill:            type === 'line',
      tension:         0.35,
      pointRadius:     type === 'line' ? 3 : 0,
      pointHoverRadius: 5,
    };
  });

  return new Chart(canvas, {
    type,
    data: { labels: chartData.labels, datasets },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      plugins: {
        legend: {
          display: datasets.length > 1 || type === 'pie',
          position: 'top',
          labels: { font: { family: 'system-ui', size: 12 }, boxWidth: 12, padding: 16 },
        },
        tooltip: {
          callbacks: {
            label: ctx => {
              const v = ctx.parsed.y ?? ctx.parsed;
              return ` ${ctx.dataset.label}: ${
                typeof v === 'number' && v > 1000 ? fmtCurrency(v) : v
              }`;
            },
          },
        },
      },
      scales: (type === 'pie' || type === 'doughnut') ? {} : {
        x: {
          grid:  { display: false },
          ticks: { font: { size: 11 }, maxRotation: 35 },
        },
        y: {
          grid:  { color: '#f3f4f6' },
          ticks: {
            font: { size: 11 },
            callback: v => v >= 1000 ? '$' + (v / 1000).toFixed(v % 1000 === 0 ? 0 : 1) + 'K' : v,
          },
          beginAtZero: true,
        },
      },
    },
  });
}

function resolveChartType(chartData, columns) {
  if (!chartData || chartData.type === 'table') return null;
  if (chartData.type === 'pie') return 'pie';
  /* Revenue over time → line chart */
  if (columns && (columns.includes('month') || columns.includes('forecasted_revenue'))) {
    return 'line';
  }
  return 'bar';
}

/* ═══════════════════════════════════════════════════════════════════════════
   FILTER TABLE  (called internally via applyFilters in each closure)
   ═══════════════════════════════════════════════════════════════════════════ */
/* Filter logic lives inside the renderResponse closure above.
   This global is kept for parity with the spec signature. */
function filterTable(filterValue, rows, columns) {
  if (!filterValue) return [...rows];
  const q = filterValue.toLowerCase();
  return rows.filter(row =>
    columns.some(col => String(row[col] ?? '').toLowerCase().includes(q))
  );
}

/* ═══════════════════════════════════════════════════════════════════════════
   EXPORT CSV
   ═══════════════════════════════════════════════════════════════════════════ */
function exportCSV(rows, columns, question) {
  if (!rows || rows.length === 0) { alert('No data to export.'); return; }

  const escape = v => {
    const s = String(v ?? '');
    return s.includes(',') || s.includes('"') || s.includes('\n')
      ? `"${s.replace(/"/g, '""')}"`
      : s;
  };

  const header = columns.map(escape).join(',');
  const body   = rows.map(row => columns.map(c => escape(row[c])).join(','));
  const csv    = [header, ...body].join('\n');

  const slug    = (question || 'data').toLowerCase()
    .replace(/[^a-z0-9]+/g, '_').slice(0, 40);
  const dateStr = new Date().toISOString().slice(0, 10);
  const filename = `marriott_${slug}_${dateStr}.csv`;

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement('a');
  a.href = url; a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/* ═══════════════════════════════════════════════════════════════════════════
   HISTORY
   ═══════════════════════════════════════════════════════════════════════════ */
function saveToHistory(question) {
  const history = getHistory();
  const entry   = { question, ts: Date.now() };
  /* De-duplicate by question text */
  const filtered = history.filter(h => h.question !== question);
  const updated  = [entry, ...filtered].slice(0, MAX_HISTORY);
  localStorage.setItem('sp_history', JSON.stringify(updated));
  renderHistory();
}

function getHistory() {
  try { return JSON.parse(localStorage.getItem('sp_history') || '[]'); }
  catch { return []; }
}

function renderHistory() {
  const history = getHistory();
  historyEl.innerHTML = '';

  if (history.length === 0) {
    historyEl.innerHTML = '<div class="history-empty">No queries yet</div>';
    return;
  }

  history.forEach(({ question, ts }) => {
    const item = document.createElement('div');
    item.className = 'history-item';

    const q = document.createElement('div');
    q.className = 'history-question';
    q.textContent = question;

    const t = document.createElement('div');
    t.className = 'history-time';
    t.textContent = fmtRelativeTime(ts);

    item.appendChild(q);
    item.appendChild(t);

    item.addEventListener('click', () => {
      inputEl.value = question;
      inputEl.dispatchEvent(new Event('input'));
      inputEl.focus();
      /* Highlight active */
      historyEl.querySelectorAll('.history-item').forEach(i => i.classList.remove('active'));
      item.classList.add('active');
    });

    historyEl.appendChild(item);
  });
}

function clearHistory() {
  if (!confirm('Clear all query history?')) return;
  localStorage.removeItem('sp_history');
  renderHistory();
}

/* ═══════════════════════════════════════════════════════════════════════════
   WELCOME MESSAGE
   ═══════════════════════════════════════════════════════════════════════════ */
function renderWelcome() {
  const wrap = document.createElement('div');
  wrap.className = 'welcome-bubble';
  wrap.innerHTML = `
    <div class="welcome-title">Welcome back.</div>
    <div class="welcome-body">
      <p>Ask me about <strong>group bookings</strong>, <strong>property pipeline</strong>,
         <strong>corporate accounts</strong>, or <strong>revenue forecasts</strong>.</p>
      <p>I can surface at-risk deals, overdue follow-ups, properties below budget,
         and accounts that haven't been contacted recently.</p>
      <p>Try one of the suggested prompts below or type your own question.</p>
    </div>`;
  messagesEl.appendChild(wrap);
}

/* ═══════════════════════════════════════════════════════════════════════════
   SMALL DOM HELPERS
   ═══════════════════════════════════════════════════════════════════════════ */
function appendUserBubble(text) {
  const el = document.createElement('div');
  el.className = 'user-message';
  el.textContent = text;
  messagesEl.appendChild(el);
}

function appendLoadingBubble() {
  const el = document.createElement('div');
  el.className = 'loading-bubble';
  el.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';
  messagesEl.appendChild(el);
  return el;
}

function appendErrorBubble(msg) {
  const el = document.createElement('div');
  el.className = 'agent-message';
  el.innerHTML = `<div class="agent-bubble"><div class="summary-text" style="color:#d93025">
    ⚠ ${escHtml(msg)}</div></div>`;
  messagesEl.appendChild(el);
}

function mkActionBtn(label, onClick, primary = false) {
  const btn = document.createElement('button');
  btn.className = 'action-btn' + (primary ? ' primary' : '');
  btn.textContent = label;
  btn.addEventListener('click', onClick);
  return btn;
}

function createFilterChip(label, active, onClick) {
  const chip = document.createElement('button');
  chip.className = 'filter-chip' + (active ? ' active' : '');
  chip.textContent = label;
  chip.addEventListener('click', onClick);
  return chip;
}

function setSending(on) {
  sendBtn.disabled = on;
  inputEl.disabled = on;
}

function scrollBottom() {
  requestAnimationFrame(() => {
    messagesEl.scrollTo({ top: messagesEl.scrollHeight, behavior: 'smooth' });
  });
}

/* ═══════════════════════════════════════════════════════════════════════════
   DATA HELPERS
   ═══════════════════════════════════════════════════════════════════════════ */

/* Return filterable categorical columns with 2–10 unique values */
function getFilterableColumns(rows, columns) {
  const PREFERRED = ['stage', 'region', 'tier', 'activity_type', 'brand',
                     'segment', 'event_type', 'owner_id'];
  const result = [];
  for (const col of PREFERRED) {
    if (!columns.includes(col)) continue;
    const vals = [...new Set(rows.map(r => r[col]).filter(v => v != null && v !== ''))];
    if (vals.length >= 2 && vals.length <= 10) result.push({ col, values: vals.sort() });
  }
  return result;
}

function sum(rows, key) {
  return rows.reduce((s, r) => s + (parseFloat(r[key]) || 0), 0);
}

/* ── Cell formatting ── */
const CURRENCY_COLS = new Set(['total_value', 'annual_travel_spend', 'budget_revenue',
  'actual_revenue', 'forecasted_revenue', 'variance_vs_budget', 'variance_vs_forecast',
  'shortfall', 'open_booking_value', 'avg_deal_size', 'negotiated_rate_usd']);
const PCT_COLS = new Set(['variance_pct', 'variance_vs_budget_pct', 'variance_vs_forecast_pct',
  'occupancy_forecast', 'actual_occupancy']);
const STAGE_COLORS = { Contracted: 'green', Negotiation: 'blue', Proposal: 'orange',
                       Prospecting: 'gray',  Lost: 'red' };
const TIER_COLORS  = { platinum: 'blue', gold: 'orange', silver: 'gray' };

function formatCell(col, val) {
  if (val == null || val === '') return '<span style="color:#d1d5db">—</span>';

  if (CURRENCY_COLS.has(col)) {
    const n = parseFloat(val);
    const cls = n < 0 ? 'style="color:var(--red)"' : '';
    return `<span ${cls}>${fmtCurrency(n)}</span>`;
  }

  if (PCT_COLS.has(col)) {
    const n = parseFloat(val);
    const cls = n < 0 ? 'style="color:var(--red)"' : n > 0 ? 'style="color:var(--green)"' : '';
    return `<span ${cls}>${n.toFixed(1)}%</span>`;
  }

  if (col === 'stage') {
    const c = STAGE_COLORS[val] || 'gray';
    return `<span class="badge badge-${c}">${escHtml(val)}</span>`;
  }
  if (col === 'tier') {
    const c = TIER_COLORS[val] || 'gray';
    return `<span class="badge badge-${c}">${escHtml(val)}</span>`;
  }

  if (col.endsWith('_date') || col === 'activity_date') {
    return fmtDate(val);
  }

  if (col === 'days_stale' || col === 'days_since_activity' || col === 'days_since_contact') {
    const n = parseInt(val, 10);
    const cls = n > 30 ? 'style="color:var(--red);font-weight:600"'
              : n > 14 ? 'style="color:var(--orange)"' : '';
    return `<span ${cls}>${n}d</span>`;
  }

  if (col === 'days_until_checkin') {
    const n = parseInt(val, 10);
    const cls = n <= 30 ? 'style="color:var(--red);font-weight:600"'
              : n <= 60 ? 'style="color:var(--orange)"' : '';
    return `<span ${cls}>${n}d</span>`;
  }

  return escHtml(String(val));
}

/* ─── Formatting utils ─────────────────────────────────────────────────────── */
function fmtCurrency(n) {
  if (isNaN(n)) return '—';
  if (Math.abs(n) >= 1_000_000) return `$${(n / 1_000_000).toFixed(1)}M`;
  if (Math.abs(n) >= 1_000)     return `$${(n / 1_000).toFixed(0)}K`;
  return `$${n.toFixed(0)}`;
}

function fmtDate(val) {
  if (!val) return '—';
  try {
    return new Date(val).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  } catch { return String(val); }
}

function fmtRelativeTime(ts) {
  const diff = Date.now() - ts;
  if (diff < 60_000)  return 'Just now';
  if (diff < 3_600_000) return `${Math.floor(diff / 60_000)}m ago`;
  if (diff < 86_400_000) return `${Math.floor(diff / 3_600_000)}h ago`;
  return new Date(ts).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

function humanise(col) {
  return col.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function escHtml(str) {
  return String(str)
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function formatSummary(text) {
  return escHtml(text)
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n\n/g, '</p><p>')
    .replace(/\n/g, '<br>')
    .replace(/^/, '<p>').replace(/$/, '</p>');
}

function formatResponse(text) {
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/^- (.+)/gm, '<li>$1</li>')
    .replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>')
    .replace(/\n\n/g, '</p><p>')
    .replace(/^/, '<p>')
    .replace(/$/, '</p>');
}

/* Page range helper — e.g. [1, '…', 4, 5, 6, '…', 10] */
function pageRange(current, total) {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const pages = new Set([1, total, current, current - 1, current + 1].filter(p => p >= 1 && p <= total));
  const sorted = [...pages].sort((a, b) => a - b);
  const result = [];
  let prev = null;
  for (const p of sorted) {
    if (prev !== null && p - prev > 1) result.push('…');
    result.push(p);
    prev = p;
  }
  return result;
}
