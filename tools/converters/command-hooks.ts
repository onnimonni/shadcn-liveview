import { sendEventMethod } from "./hook-events"
import { topLayerMethod } from "./top-layer"

export const commandHook = String.raw`export default {
${sendEventMethod("  ")}
  mounted() {
    this.listeners = [];
    this.itemOrder = [];
    this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
    this.listen(this.el, "input", e => { if (e.target.matches("[cmdk-input]")) this.filter(); });
    this.listen(this.el, "keydown", e => {
      if (!e.target.matches("[cmdk-input]") || e.target.disabled || e.isComposing) return;
      const items = this.available();
      const current = items.findIndex(item => item.getAttribute("data-selected") === "true");
      let next;
      if (e.key === "ArrowDown") next = current + 1;
      if (e.key === "ArrowUp") next = current < 0 ? items.length - 1 : current - 1;
      if (e.key === "Home") next = 0;
      if (e.key === "End") next = items.length - 1;
      if (next !== undefined && items.length) {
        e.preventDefault();
        if (this.el.getAttribute("phx-value-loop") === "true") next = (next + items.length) % items.length;
        this.select(items[Math.max(0, Math.min(next, items.length - 1))]);
      }
      if (e.key === "Enter") {
        const item = items.find(item => item.getAttribute("data-selected") === "true");
        if (item) { e.preventDefault(); this.activate(item); }
      }
    });
    this.listen(this.el, "click", e => {
      const item = e.target.closest("[cmdk-item]");
      if (item && this.el.contains(item) && item.getAttribute("data-disabled") !== "true" && !item.hidden) this.activate(item);
    });
    this.listen(this.el, "pointermove", e => {
      const item = e.target.closest("[cmdk-item]");
      if (item && this.el.contains(item) && item.getAttribute("data-disabled") !== "true" && !item.hidden) this.select(item);
    });
    this.filter();
  },
  available() { return this.itemOrder.filter(item => !item.hidden && item.getAttribute("data-disabled") !== "true"); },
  select(item) {
    this.el.querySelectorAll("[cmdk-item]").forEach(node => {
      const selected = node === item;
      node.setAttribute("data-selected", String(selected)); node.setAttribute("aria-selected", String(selected));
    });
    const input = this.el.querySelector("[cmdk-input]");
    if (input) { if (item) input.setAttribute("aria-activedescendant", item.id); else input.removeAttribute("aria-activedescendant"); }
    if (this.el.contains(document.activeElement)) item?.scrollIntoView({block: "nearest"});
  },
  score(text, query) {
    // cmdk command-score: contiguous and word-boundary matches outrank gaps;
    // casing, skipped boundaries and transpositions receive the same penalties.
    const lower = text.toLowerCase().replace(/[\s-]/g, " ");
    const search = query.toLowerCase().replace(/[\s-]/g, " ");
    const memo = new Map();
    const recurse = (start, index) => {
      if (index === query.length) return start === text.length ? 1 : 0.99;
      const key = start + "," + index;
      if (memo.has(key)) return memo.get(key);
      let best = 0;
      for (let position = lower.indexOf(search[index], start); position >= 0; position = lower.indexOf(search[index], position + 1)) {
        let score = recurse(position + 1, index + 1);
        if (score > best) {
          if (position === start) score *= 1;
          else if (/[\\\/_+.#"@\[\(\{&]/.test(text[position - 1])) {
            score *= 0.8;
            const boundaries = text.slice(start, position - 1).match(/[\\\/_+.#"@\[\(\{&]/g);
            if (boundaries && start > 0) score *= Math.pow(0.999, boundaries.length);
          } else if (/[\s-]/.test(text[position - 1])) {
            score *= 0.9;
            const boundaries = text.slice(start, position - 1).match(/[\s-]/g);
            if (boundaries && start > 0) score *= Math.pow(0.999, boundaries.length);
          } else {
            score *= 0.17;
            if (start > 0) score *= Math.pow(0.999, position - start);
          }
          if (text[position] !== query[index]) score *= 0.9999;
        }
        if ((score < 0.1 && lower[position - 1] === search[index + 1]) || (search[index + 1] === search[index] && lower[position - 1] !== search[index])) {
          score = Math.max(score, recurse(position + 1, index + 2) * 0.1);
        }
        best = Math.max(best, score);
      }
      memo.set(key, best); return best;
    };
    return recurse(0, 0);
  },
  filter() {
    const query = (this.el.querySelector("[cmdk-input]")?.value || "").trim();
    const shouldFilter = this.el.getAttribute("phx-value-filter") !== "false";
    let count = 0;
    const scores = new Map(), parents = new Set();
    this.el.querySelectorAll("[cmdk-item]").forEach(item => {
      const keywords = JSON.parse(item.getAttribute("phx-value-keywords") || "[]");
      const text = [item.getAttribute("phx-value-value"), ...keywords].join(" ");
      const score = !shouldFilter || !query ? 1 : this.score(text, query);
      scores.set(item, score); item.hidden = score === 0; if (score > 0) count++;
      parents.add(item.parentElement);
    });
    this.el.querySelectorAll("[cmdk-group]").forEach(group => {
      const items = Array.from(group.querySelectorAll("[cmdk-item]"));
      group.hidden = !items.some(item => !item.hidden);
      scores.set(group, Math.max(0, ...items.map(item => scores.get(item) || 0)));
      parents.add(group.parentElement);
    });
    const orders = new Map();
    parents.forEach(parent => {
      const children = Array.from(parent.children);
      const ranked = children.filter(node => scores.has(node));
      if (shouldFilter && query) ranked.sort((a, b) => scores.get(b) - scores.get(a));
      const ordered = shouldFilter && query ? [...children.filter(node => !scores.has(node)), ...ranked] : children;
      parent.style.display = "flex"; parent.style.flexDirection = "column";
      ordered.forEach((node, index) => { node.style.order = String(index); });
      orders.set(parent, ordered);
    });
    this.itemOrder = [];
    const visit = node => {
      if (node.matches("[cmdk-item]")) this.itemOrder.push(node);
      else (orders.get(node) || Array.from(node.children)).forEach(visit);
    };
    visit(this.el);
    this.el.querySelectorAll("[cmdk-empty]").forEach(empty => { empty.hidden = count !== 0; });
    this.el.querySelectorAll("[cmdk-separator]").forEach(separator => { separator.hidden = query !== ""; });
    const items = this.available();
    const selected = this.el.getAttribute("phx-value-selected");
    this.select(items.find(item => item.getAttribute("phx-value-value") === selected) || items[0]);
  },
  activate(item) {
    this.select(item);
    const value = item.getAttribute("phx-value-value") || item.textContent.trim();
    const previous = this.el.getAttribute("phx-value-selected");
    this.el.setAttribute("phx-value-selected", value);
    this.el.dispatchEvent(new CustomEvent("shadcn:command-change", {bubbles: true, detail: {id: this.el.id, value}}));
    const event = this.el.getAttribute("phx-value-event");
    // The server owns the selected value, so a failed push restores it.
    if (event) this.sendEvent(event, {id: this.el.id, value}).catch(() => {
      if (this.el.getAttribute("phx-value-selected") === value) { this.el.setAttribute("phx-value-selected", previous); this.filter(); }
    });
  },
  updated() { this.filter(); },
  destroyed() { this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler)); }
}`

export const otpHook = String.raw`export default {
${sendEventMethod("  ")}
  mounted() {
    this.container = this.el.closest("[data-input-otp-container]"); this.listeners = []; this.lastValue = this.el.value;
    this.serverValue = this.el.getAttribute("phx-value-value") || ""; this.pendingValues = [];
    this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
    this.listen(document, "phx:update", () => this.repairNoScript());
    this.repairNoScript();
    this.listen(this.el, "focus", () => { const end = this.el.value.length; this.el.setSelectionRange(Math.min(end, this.el.maxLength - 1), end); this.paint(); });
    this.listen(this.el, "blur", () => this.paint());
    this.listen(this.el, "input", e => {
      if (this.lengthError && this.el.validationMessage === this.lengthError) this.el.setCustomValidity("");
      const nativeMessage = e.isTrusted && this.el.validity.tooShort ? this.el.validationMessage : "";
      this.accept(nativeMessage);
    });
    this.listen(this.el, "paste", e => {
      if (this.el.disabled || this.el.readOnly) return;
      let pasted = e.clipboardData.getData("text/plain");
      if (this.el.getAttribute("phx-value-transform") === "strip-separators") pasted = pasted.replace(/[\s-]/g, "");
      e.preventDefault();
      const start = this.el.selectionStart ?? this.el.value.length;
      const end = this.el.selectionEnd ?? start;
      this.el.value = (this.el.value.slice(0, start) + pasted + this.el.value.slice(end)).slice(0, this.el.maxLength);
      const cursor = Math.min(start + pasted.length, this.el.value.length);
      this.el.setSelectionRange(Math.min(cursor, this.el.maxLength - 1), cursor);
      this.el.dispatchEvent(new Event("input", {bubbles: true}));
    });
    this.listen(document, "selectionchange", () => {
      if (document.activeElement !== this.el) return;
      const start = this.el.selectionStart, end = this.el.selectionEnd;
      if (start === end && this.el.value.length && start < this.el.value.length) this.el.setSelectionRange(start, start + 1);
      else if (start === end && start === this.el.maxLength) this.el.setSelectionRange(start - 1, start);
      this.paint();
    });
    if (this.el.form) this.listen(this.el.form, "reset", () => queueMicrotask(() => { this.lastValue = this.el.value; this.validateLength(); this.paint(); }));
    this.resize = new ResizeObserver(() => this.container.style.setProperty("--root-height", this.el.clientHeight + "px"));
    this.resize.observe(this.el); this.validateLength(); this.paint();
  },
  repairNoScript() {
    const fallback = this.container.previousElementSibling;
    if (fallback?.localName === "noscript" && fallback.firstElementChild) fallback.textContent = fallback.innerHTML;
  },
  validateLength(nativeMessage = "") {
    if (this.el.validity.customError && this.el.validationMessage !== this.lengthError) { this.lengthError = ""; return; }
    const value = this.el.value, minimum = this.el.minLength;
    if (nativeMessage) { this.nativeLengthMessage = nativeMessage; this.nativeLengthValue = value; }
    const short = value !== "" && minimum > 0 && value.length < minimum;
    const message = short ? nativeMessage || (this.nativeLengthValue === value && this.nativeLengthMessage) || "Please enter at least " + minimum + " characters." : "";
    if (this.el.validationMessage !== message || !this.el.validity.customError) this.el.setCustomValidity(message);
    this.lengthError = message;
  },
  accept(nativeMessage = "") {
    const previous = this.lastValue;
    const value = this.el.value.slice(0, this.el.maxLength);
    const pattern = this.el.pattern;
    if (value && pattern && !new RegExp(pattern).test(value)) { this.el.value = previous; this.validateLength(); this.paint(); return; }
    if (this.el.value !== value) this.el.value = value;
    this.lastValue = value; this.validateLength(nativeMessage); this.paint();
    if (value === previous) return;
    const detail = {id: this.el.id, value};
    this.el.dispatchEvent(new CustomEvent("shadcn:otp-change", {bubbles: true, detail}));
    const event = this.el.getAttribute("phx-value-change");
    const completed = value.length === this.el.maxLength && previous.length < this.el.maxLength;
    const complete = completed && this.el.getAttribute("phx-value-complete");
    if (event) {
      this.pendingValues.push(value);
      // Complete only after the change reply releases LiveView's input lock.
      // Typed text stays local like a native input; a failed push only drops its acknowledgement.
      this.sendEvent(event, detail, () => { if (complete) this.sendEvent(complete, detail); }).catch(() => {
        const index = this.pendingValues.indexOf(value); if (index >= 0) this.pendingValues.splice(index, 1);
      });
    }
    if (completed) {
      this.el.dispatchEvent(new CustomEvent("shadcn:otp-complete", {bubbles: true, detail}));
      if (!event && complete) this.sendEvent(complete, detail);
    }
  },
  paint() {
    const focused = document.activeElement === this.el;
    const start = this.el.selectionStart ?? 0, end = this.el.selectionEnd ?? start;
    this.container.querySelectorAll("[data-slot=input-otp-slot]").forEach(slot => {
      const index = Number(slot.getAttribute("phx-value-index"));
      const char = this.el.value[index] || "";
      const active = focused && !this.el.disabled && (start === end ? index === start : index >= start && index < end);
      slot.setAttribute("data-active", String(active)); slot.replaceChildren(document.createTextNode(char));
      if (active && !char) {
        const caret = document.createElement("div"); caret.className = "pointer-events-none absolute inset-0 flex items-center justify-center";
        const bar = document.createElement("div"); bar.className = "h-4 w-px animate-caret-blink bg-foreground duration-1000"; caret.append(bar); slot.append(caret);
      }
    });
    if (!this.el.value) this.el.setAttribute("data-input-otp-placeholder-shown", "true"); else this.el.removeAttribute("data-input-otp-placeholder-shown");
    if (focused) { this.el.setAttribute("data-input-otp-mss", start); this.el.setAttribute("data-input-otp-mse", end); }
    else { this.el.removeAttribute("data-input-otp-mss"); this.el.removeAttribute("data-input-otp-mse"); }
  },
  updated() {
    const serverValue = this.el.getAttribute("phx-value-value") || "";
    if (serverValue !== this.serverValue) {
      const acknowledged = this.pendingValues.lastIndexOf(serverValue);
      if (acknowledged >= 0) this.pendingValues.splice(0, acknowledged + 1);
      else { this.pendingValues = []; if (this.el.value !== serverValue) this.el.value = serverValue; }
      if (!this.pendingValues.length && this.el.value !== serverValue) this.el.value = serverValue;
    }
    this.serverValue = serverValue; this.lastValue = this.el.value; this.validateLength(); this.paint();
  },
  destroyed() { this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler)); this.resize.disconnect(); }
}`

export const comboboxHook = String.raw`export default {
${sendEventMethod("  ")}
${topLayerMethod("  ")}
  mounted() {
    this.group = this.el.closest("[data-slot=input-group]"); this.listeners = []; this.popup = null; this.active = null; this.popupListeners = []; this.query = "";
    this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
    this.listen(document, "click", e => {
      this.group = this.el.closest("[data-slot=input-group]");
      if (!this.group.contains(e.target)) return;
      const clear = e.target.closest("[data-slot=combobox-clear]");
      if (clear && !clear.disabled) { this.commit("", ""); return; }
      const trigger = e.target.closest("[data-slot=input-group-button]");
      if (trigger && !trigger.disabled) { this.requestOpen(this.el.getAttribute("phx-value-open") !== "true"); this.el.focus(); }
    });
    this.listen(document, "phx:update", () => {
      this.group = this.el.closest("[data-slot=input-group]");
      this.syncTrigger();
      if (document.getElementById(this.el.getAttribute("phx-value-popup-id")) !== this.popup) this.bindPopup();
    });
    this.listen(this.el, "pointerdown", () => this.requestOpen(true));
    this.listen(this.el, "input", () => { if (!this.el.readOnly) { this.query = this.el.value; this.requestOpen(true); this.filter(); } });
    this.listen(this.el, "keydown", e => {
      if (this.el.disabled || this.el.readOnly || this.el.hasAttribute("data-disabled") || e.isComposing) return;
      if (["ArrowDown", "ArrowUp", "Home", "End"].includes(e.key)) {
        e.preventDefault();
        if (!this.popup) { this.pendingKey = e.key; this.requestOpen(true); }
        else this.navigate(e.key);
      }
      if (e.key === "Enter" && this.popup && this.active) { e.preventDefault(); this.choose(this.active); }
      if (e.key === "Escape" && this.popup) { e.preventDefault(); this.requestOpen(false); }
      if (e.key === "Tab") this.requestOpen(false);
    });
    this.listen(document, "pointerdown", e => {
      this.group = this.el.closest("[data-slot=input-group]");
      if (!this.group.contains(e.target) && !this.popup?.contains(e.target)) this.requestOpen(false);
    });
    this.listen(window, "resize", () => this.position());
    this.listen(window, "scroll", () => this.position());
    if (this.el.form) this.listen(this.el.form, "reset", () => queueMicrotask(() => {
      this.requestOpen(false); this.commit(this.formInput()?.value || "", this.el.value);
    }));
    this.bindPopup();
    this.syncTrigger();
  },
  syncTrigger() {
    // Base UI starts with popup-input trigger semantics during SSR, then the
    // editable input registers on mount and leaves its auxiliary trigger a button.
    const trigger = this.group.querySelector("[data-slot=input-group-button]");
    if (!trigger) return;
    trigger.removeAttribute("role");
    trigger.setAttribute("tabindex", "-1");
    trigger.setAttribute("aria-haspopup", "listbox");
    trigger.setAttribute("aria-expanded", this.el.getAttribute("aria-expanded"));
    const controls = this.el.getAttribute("aria-controls");
    if (controls) trigger.setAttribute("aria-controls", controls);
    else trigger.removeAttribute("aria-controls");
  },
  formInput() {
    let sibling = this.group.nextElementSibling;
    while (sibling && sibling.tagName !== "INPUT") sibling = sibling.nextElementSibling;
    return sibling;
  },
  requestOpen(open) {
    if (open && (this.el.disabled || this.el.readOnly || this.el.hasAttribute("data-disabled"))) return;
    if (this.requestedOpen === open || (this.requestedOpen === undefined && (this.el.getAttribute("phx-value-open") === "true") === open)) return;
    this.requestedOpen = open;
    const event = this.el.getAttribute("phx-value-open-event");
    // The server owns open state; a failed push lets the next interaction retry.
    if (event) this.sendEvent(event, {id: this.el.getAttribute("phx-value-root"), open}).catch(() => { if (this.requestedOpen === open) this.requestedOpen = undefined; });
  },
  unbindPopup() {
    if (this.popup) this.popupListeners.forEach(([type, listener]) => this.popup.removeEventListener(type, listener));
    this.popupListeners = []; this.popup = null; this.active = null;
    this.el.removeAttribute("aria-activedescendant");
  },
  bindPopup() {
    this.unbindPopup();
    this.popup = document.getElementById(this.el.getAttribute("phx-value-popup-id"));
    if (!this.popup) return;
    this.popupListeners = [
      ["pointerdown", e => e.preventDefault()],
      ["click", e => { const item = e.target.closest("[data-slot=combobox-item]"); if (item && !item.hasAttribute("data-disabled") && !item.hidden) this.choose(item); }],
      ["pointermove", e => { const item = e.target.closest("[data-slot=combobox-item]"); if (item && !item.hasAttribute("data-disabled") && !item.hidden) this.highlight(item); }]
    ];
    this.popupListeners.forEach(([type, listener]) => this.popup.addEventListener(type, listener));
    this.position(); this.filter();
    if (this.pendingKey) { this.navigate(this.pendingKey); this.pendingKey = null; }
  },
  position() {
    if (!this.popup) return;
    this.promoteToTopLayer(this.popup, false);
    const rect = this.group.getBoundingClientRect(); const available = window.innerHeight - rect.bottom - 12;
    this.popup.style.position = "fixed"; this.popup.style.zIndex = "50";
    this.popup.style.left = Math.max(4, Math.min(rect.left, window.innerWidth - rect.width - 4)) + "px";
    this.popup.style.top = (rect.bottom + 6) + "px"; this.popup.style.setProperty("--anchor-width", rect.width + "px");
    this.popup.style.setProperty("--available-width", (window.innerWidth - 8) + "px");
    this.popup.style.setProperty("--available-height", Math.max(80, available) + "px");
    this.popup.style.setProperty("--transform-origin", "top left");
  },
  available() { return this.popup ? Array.from(this.popup.querySelectorAll("[data-slot=combobox-item]")).filter(item => !item.hidden && !item.hasAttribute("data-disabled")) : []; },
  navigate(key) {
    const items = this.available(); if (!items.length) return;
    const current = items.indexOf(this.active);
    const index = key === "Home" ? 0 : key === "End" ? items.length - 1 : key === "ArrowDown" ? (current + 1) % items.length : current <= 0 ? items.length - 1 : current - 1;
    this.highlight(items[index]);
  },
  filter() {
    if (!this.popup) return;
    const query = this.query.toLocaleLowerCase().trim(); let count = 0;
    this.popup.querySelectorAll("[data-slot=combobox-item]").forEach(item => {
      item.hidden = !item.textContent.toLocaleLowerCase().includes(query); if (!item.hidden) count++;
    });
    this.popup.toggleAttribute("data-empty", count === 0);
    this.popup.querySelectorAll("[data-slot=combobox-empty]").forEach(empty => { empty.style.display = count === 0 ? "flex" : "none"; });
    this.popup.querySelectorAll("[data-slot=combobox-group]").forEach(group => { group.hidden = !Array.from(group.querySelectorAll("[data-slot=combobox-item]")).some(item => !item.hidden); });
    this.highlight(null);
  },
  highlight(item) {
    this.active = item;
    this.popup?.querySelectorAll("[data-slot=combobox-item]").forEach(node => node.toggleAttribute("data-highlighted", node === item));
    if (item) { this.el.setAttribute("aria-activedescendant", item.id); item.scrollIntoView({block: "nearest"}); }
    else this.el.removeAttribute("aria-activedescendant");
  },
  choose(item) {
    const label = Array.from(item.childNodes).filter(node => !(node.nodeType === Node.ELEMENT_NODE && node.matches("span.pointer-events-none.absolute"))).map(node => node.textContent).join("").trim();
    this.commit(item.getAttribute("phx-value-value") || "", label);
  },
  commit(value, label) {
    this.query = "";
    this.el.value = label;
    const hidden = this.formInput(); if (hidden) { hidden.value = value; hidden.dispatchEvent(new Event("input", {bubbles: true})); hidden.dispatchEvent(new Event("change", {bubbles: true})); }
    const detail = {id: this.el.getAttribute("phx-value-root"), value};
    this.el.dispatchEvent(new CustomEvent("shadcn:combobox-change", {bubbles: true, detail}));
    // The server owns the committed value, so a failed push restores the rendered input values.
    const event = this.el.getAttribute("phx-value-event"); if (event) this.sendEvent(event, detail).catch(() => {
      if (this.el.value !== label) return;
      this.el.value = this.el.defaultValue; if (hidden) hidden.value = this.el.getAttribute("phx-value-selected") || "";
    });
    this.requestOpen(false); this.el.focus();
  },
  updated() {
    this.requestedOpen = undefined;
    this.group = this.el.closest("[data-slot=input-group]");
    this.bindPopup();
    this.syncTrigger();
  },
  destroyed() {
    this.unbindPopup();
    this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler));
  }
}`
