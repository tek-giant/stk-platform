"use strict";

const els = {
  tbody: document.getElementById("orders"),
  tableWrap: document.getElementById("table-wrap"),
  skeleton: document.getElementById("skeleton"),
  empty: document.getElementById("empty"),
  emptyText: document.getElementById("empty-text"),
  form: document.getElementById("order-form"),
  item: document.getElementById("item"),
  quantity: document.getElementById("quantity"),
  submit: document.getElementById("submit"),
  search: document.getElementById("search"),
  toasts: document.getElementById("toasts"),
  status: document.getElementById("status"),
  statusText: document.getElementById("status-text"),
  statOrders: document.getElementById("stat-orders"),
  statUnits: document.getElementById("stat-units"),
  statItems: document.getElementById("stat-items"),
};

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const openedAsFile = window.location.protocol === "file:";

// Shown only when the page is opened straight from disk, so the design can be previewed.
const DEMO_ORDERS = [
  { id: 1, item: "Mechanical keyboard", quantity: 3, status: "NEW" },
  { id: 2, item: "27-inch monitor", quantity: 1, status: "NEW" },
  { id: 3, item: "USB-C dock", quantity: 5, status: "NEW" },
];

let orders = [];
let demo = false;
let query = "";

function toast(text, kind) {
  const note = document.createElement("div");
  note.className = "toast toast-" + kind;
  note.textContent = text;
  els.toasts.appendChild(note);
  setTimeout(() => note.remove(), 3800);
}

function setStatus(kind, text) {
  els.status.className = "status status-" + kind;
  els.statusText.textContent = text;
}

function countUp(el, target) {
  const from = Number(el.dataset.value || 0);
  el.dataset.value = String(target);
  if (reduceMotion || from === target) {
    el.textContent = String(target);
    return;
  }
  const start = performance.now();
  const duration = 600;
  function frame(now) {
    const t = Math.min((now - start) / duration, 1);
    const eased = 1 - Math.pow(1 - t, 3);
    el.textContent = String(Math.round(from + (target - from) * eased));
    if (t < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

function updateStats() {
  countUp(els.statOrders, orders.length);
  countUp(els.statUnits, orders.reduce((sum, o) => sum + o.quantity, 0));
  countUp(els.statItems, new Set(orders.map((o) => o.item.toLowerCase())).size);
}

function render(freshId) {
  const visible = orders
    .filter((o) => o.item.toLowerCase().includes(query))
    .sort((a, b) => b.id - a.id);

  els.skeleton.hidden = true;
  els.tbody.replaceChildren();
  els.tableWrap.hidden = visible.length === 0;
  els.empty.hidden = visible.length > 0;
  els.emptyText.textContent =
    orders.length === 0 ? "No orders yet. Create the first one." : "No orders match your search.";

  visible.forEach((order, index) => {
    const row = document.createElement("tr");
    row.className = "row" + (order.id === freshId ? " fresh" : "");
    row.style.animationDelay = Math.min(index, 12) * 40 + "ms";

    const values = [
      "#" + order.id,
      order.item,
      String(order.quantity),
      order.status,
    ];
    values.forEach((value, column) => {
      const cell = document.createElement("td");
      if (column === 3) {
        const badge = document.createElement("span");
        badge.className = "badge badge-" + value.toLowerCase().replace(/[^a-z]/g, "");
        badge.textContent = value;
        cell.appendChild(badge);
      } else {
        cell.textContent = value;
      }
      row.appendChild(cell);
    });
    els.tbody.appendChild(row);
  });
}

async function loadOrders(freshId) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 5000);
  try {
    const response = await fetch("/api/orders", {
      signal: controller.signal,
      headers: { Accept: "application/json" },
    });
    if (!response.ok) {
      throw new Error("The API answered " + response.status);
    }
    orders = await response.json();
    demo = false;
    setStatus("ok", "API connected");
  } catch (error) {
    if (openedAsFile) {
      if (!demo) {
        orders = DEMO_ORDERS.map((o) => ({ ...o }));
      }
      demo = true;
      setStatus("demo", "Demo data, API not connected");
    } else {
      setStatus("offline", "API unreachable");
      toast("Could not load orders: " + error.message, "error");
    }
  } finally {
    clearTimeout(timer);
  }
  updateStats();
  render(freshId);
}

async function createOrder(item, quantity) {
  if (demo) {
    const id = orders.reduce((max, o) => Math.max(max, o.id), 0) + 1;
    orders.push({ id, item, quantity, status: "NEW" });
    toast("Demo order added (not saved anywhere).", "ok");
    updateStats();
    render(id);
    return;
  }
  const response = await fetch("/api/orders", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ item, quantity }),
  });
  if (!response.ok) {
    throw new Error("The API rejected the order (" + response.status + ")");
  }
  const created = await response.json();
  toast("Order #" + created.id + " created.", "ok");
  await loadOrders(created.id);
}

els.form.addEventListener("submit", async (event) => {
  event.preventDefault();
  const item = els.item.value.trim();
  const quantity = Number(els.quantity.value);
  if (!item || !Number.isInteger(quantity) || quantity < 1) {
    toast("Enter an item and a quantity of at least 1.", "error");
    return;
  }
  els.submit.disabled = true;
  els.submit.textContent = "Creating";
  try {
    await createOrder(item, quantity);
    els.form.reset();
    els.quantity.value = 1;
    els.item.focus();
  } catch (error) {
    toast(error.message, "error");
  } finally {
    els.submit.disabled = false;
    els.submit.textContent = "Create order";
  }
});

document.querySelectorAll(".step").forEach((button) => {
  button.addEventListener("click", () => {
    const next = Number(els.quantity.value || 1) + Number(button.dataset.step);
    els.quantity.value = String(Math.max(1, next));
  });
});

els.search.addEventListener("input", () => {
  query = els.search.value.trim().toLowerCase();
  render();
});

setInterval(() => {
  if (!demo && !document.hidden) loadOrders();
}, 10000);

loadOrders();
