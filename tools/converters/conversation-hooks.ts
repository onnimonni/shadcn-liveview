export const messageScrollerHook = `      export default {
        mounted() {
          this.initialized = false; this.following = this.el.getAttribute("phx-value-auto-scroll") === "true";
          this.frame = 0; this.timer = 0; this.snapshot = null;
          this.scroll = () => { this.following = this.atEnd(); this.capture(); this.buttons(); };
          this.intent = () => { this.following = false; };
          this.key = e => { if (["ArrowDown","ArrowUp","End","Home","PageDown","PageUp"," "].includes(e.key)) this.intent(); };
          this.click = e => {
            const button = e.target.closest('[data-slot="message-scroller-button"]');
            if (!button || !this.el.contains(button) || button.dataset.active !== "true" || !this.viewport) return;
            button.blur(); const start = button.dataset.direction === "start";
            this.following = !start && this.el.getAttribute("phx-value-auto-scroll") === "true";
            if (!start) this.clearSpacer();
            this.viewport.scrollTo({ top: start ? 0 : this.viewport.scrollHeight, behavior: button.getAttribute("phx-value-behavior") || "smooth" });
          };
          this.el.addEventListener("click", this.click);
          this.bind();
        },
        bind() {
          const viewport = this.el.querySelector('[data-slot="message-scroller-viewport"]');
          const content = this.el.querySelector('[data-slot="message-scroller-content"]');
          if (this.viewport === viewport && this.content === content) { this.schedule(); return; }
          this.unbind(); this.viewport = viewport; this.content = content;
          if (viewport) {
            viewport.addEventListener("scroll", this.scroll, { passive: true });
            viewport.addEventListener("wheel", this.intent, { passive: true });
            viewport.addEventListener("touchmove", this.intent, { passive: true });
            viewport.addEventListener("keydown", this.key);
          }
          this.resize = new ResizeObserver(() => this.schedule());
          if (viewport) this.resize.observe(viewport);
          if (content) this.resize.observe(content);
          this.mutations = new MutationObserver(() => this.schedule());
          if (content) this.mutations.observe(content, { childList: true, subtree: true, characterData: true });
          this.schedule();
        },
        atEnd() {
          if (!this.viewport) return true;
          const spacer = this.content && this.content.querySelector('[data-message-scroller-spacer]');
          const blank = spacer && !spacer.hidden ? spacer.getBoundingClientRect().height + (parseFloat(getComputedStyle(this.content).rowGap) || 0) : 0;
          return this.viewport.scrollHeight - blank - this.viewport.scrollTop - this.viewport.clientHeight <= Number(this.el.getAttribute("phx-value-threshold") || 8);
        },
        clearSpacer() {
          const spacer = this.content && this.content.querySelector('[data-message-scroller-spacer]');
          if (spacer) { spacer.hidden = true; spacer.style.height = "0px"; }
        },
        capture() {
          if (!this.viewport || !this.content) return;
          const rect = this.viewport.getBoundingClientRect();
          const first = Array.from(this.content.children).find(node => node.dataset.messageId && node.getBoundingClientRect().bottom > rect.top);
          this.snapshot = first ? { id: first.dataset.messageId, offset: first.getBoundingClientRect().top - rect.top } : null;
        },
        schedule() {
          cancelAnimationFrame(this.frame);
          this.frame = requestAnimationFrame(() => this.measure());
        },
        measure() {
          const v = this.viewport;
          if (v) {
            if (!this.initialized) {
              const position = this.el.getAttribute("phx-value-position");
              const anchors = this.content ? Array.from(this.content.children).filter(node => node.dataset.scrollAnchor === "true") : [];
              const anchor = anchors[anchors.length - 1];
              if (position === "last-anchor" && anchor) {
                const margin = Number(this.el.getAttribute("phx-value-margin") || 0) + Number(this.el.getAttribute("phx-value-peek") || 64);
                const spacer = this.content.querySelector('[data-message-scroller-spacer]');
                const target = anchor.getBoundingClientRect().top - v.getBoundingClientRect().top + v.scrollTop - margin;
                if (spacer) { const height = Math.max(0, target + v.clientHeight - v.scrollHeight); spacer.hidden = height === 0; spacer.style.height = height + "px"; }
                v.scrollTop = Math.max(0, target);
              } else v.scrollTop = position === "start" ? 0 : v.scrollHeight;
            } else if (this.following && this.el.getAttribute("phx-value-auto-scroll") === "true") {
              this.clearSpacer(); v.dataset.autoscrolling = ""; v.scrollTop = v.scrollHeight;
              clearTimeout(this.timer); this.timer = setTimeout(() => delete v.dataset.autoscrolling, 180);
            } else if (this.snapshot && v.getAttribute("phx-value-preserve-prepend") !== "false" && this.content) {
              const old = Array.from(this.content.children).find(node => node.dataset.messageId === this.snapshot.id);
              if (old) v.scrollTop += old.getBoundingClientRect().top - v.getBoundingClientRect().top - this.snapshot.offset;
            }
            delete v.dataset.pendingScroll;
          }
          this.initialized = true; delete this.el.dataset.pendingScroll; this.buttons(); this.capture();
        },
        buttons() {
          const v = this.viewport; const threshold = Number(this.el.getAttribute("phx-value-threshold") || 8);
          this.el.querySelectorAll('[data-slot="message-scroller-button"]').forEach(button => {
            const active = !!v && (button.dataset.direction === "start" ? v.scrollTop > threshold : !this.atEnd());
            button.dataset.active = String(active); button.inert = !active;
            if (!active) button.tabIndex = -1; else { const tab = button.getAttribute("phx-value-tabindex"); if (tab === null) button.removeAttribute("tabindex"); else button.tabIndex = Number(tab); }
          });
        },
        updated() { this.bind(); },
        unbind() {
          if (this.viewport) { this.viewport.removeEventListener("scroll", this.scroll); this.viewport.removeEventListener("wheel", this.intent); this.viewport.removeEventListener("touchmove", this.intent); this.viewport.removeEventListener("keydown", this.key); }
          if (this.resize) this.resize.disconnect(); if (this.mutations) this.mutations.disconnect();
        },
        destroyed() { this.unbind(); this.el.removeEventListener("click", this.click); cancelAnimationFrame(this.frame); clearTimeout(this.timer); }
      }`

export const questionnaireHook = `export default {
  sendEvent(event, payload, onReply) {
    const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
    if (target) return this.pushEventTo(target, event, payload, onReply);
    return this.pushEvent(event, payload, onReply);
  },
  mounted() {
    this.states = new Map(); this.controlDefaults = new Map(); this.initialItem = this.el.getAttribute("phx-value-item"); this.current = this.initialItem; this.serverItem = this.initialItem;
    this.change = e => {
      const fieldset = e.target.closest('[data-slot="questionnaire-item"]'); if (!fieldset) return;
      const state = this.state(fieldset); state.skipped = false;
      this.refresh();
      const event = this.items().some(item => item.hasAttribute("data-multiple")) && this.el.getAttribute("phx-change");
      if (event) {
        // Phoenix's URL-encoded form transport collapses repeated unbracketed
        // names. Keep vendor DOM/FormData names and push the typed values instead.
        e.stopPropagation();
        if (e.isComposing || e.type === "change" && this.arrayInput === e.target) return;
        if (e.type === "input") {
          const input = e.target; this.arrayInput = input;
          queueMicrotask(() => { if (this.arrayInput === input) this.arrayInput = null; });
        }
        this.sendEvent(event, { ...this.formPayload(undefined, fieldset.getAttribute("phx-value-name")), _target: [fieldset.getAttribute("phx-value-name")] });
      }
    };
    this.click = e => {
      const button = e.target.closest("button[data-slot]"); if (!button || !this.el.contains(button) || button.disabled) return;
      const slot = button.dataset.slot;
      if (slot === "questionnaire-previous") this.move(-1);
      if (slot === "questionnaire-next") this.advance();
      if (slot === "questionnaire-skip") this.skip();
    };
    this.submit = e => {
      const invalid = this.items().find(item => !this.validate(item));
      if (invalid) { e.preventDefault(); e.stopImmediatePropagation(); this.select(invalid, true); }
      else {
        const event = this.items().some(item => item.hasAttribute("data-multiple")) && this.el.getAttribute("phx-submit");
        if (event) {
          e.preventDefault(); e.stopImmediatePropagation();
          this.sendEvent(event, this.formPayload(e.submitter));
        }
      }
    };
    this.reset = e => { queueMicrotask(() => {
      if (e.defaultPrevented) return;
      this.states.clear(); this.initialize(true);
      const initial = this.items().find(item => item.getAttribute("phx-value-name") === this.initialItem) || this.items()[0];
      if (initial) this.select(initial); else this.refresh();
    }); };
    this.key = e => {
      if (e.defaultPrevented || e.isComposing || e.keyCode === 229) return;
      const active = this.active(); if (!active) return;
      const controls = this.controls(active); const target = e.target;
      const editing = target.matches('textarea,select,input:not([type=radio]):not([type=checkbox]):not([type=button]):not([type=submit])') || target.isContentEditable;
      if (e.key === "Enter" && (e.metaKey || e.ctrlKey) && !e.altKey && !e.shiftKey) { e.preventDefault(); if (!e.repeat) this.advance(); return; }
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      if (["ArrowUp", "ArrowDown"].includes(e.key) && (!editing || target.value.trim() === "")) {
        const index = controls.indexOf(target); if (index < 0 && target !== active || !controls.length) return;
        const next = index < 0 ? controls.find(control => control.checked) || (e.key === "ArrowDown" ? controls[0] : controls[controls.length - 1]) : controls[(index + (e.key === "ArrowDown" ? 1 : controls.length - 1) + controls.length) % controls.length];
        if (next === target || target.type === "radio" && next.type === "radio") return;
        e.preventDefault(); next.focus(); if (next.type === "radio") next.click(); return;
      }
      if (["ArrowLeft", "ArrowRight"].includes(e.key) && !editing && target.type !== "radio") {
        e.preventDefault(); if (!e.repeat) { if (e.key === "ArrowLeft") this.move(-1); else if (active.dataset.status !== "unanswered") this.advance(); } return;
      }
      if (e.key === "Enter" && controls.includes(target)) { e.preventDefault(); if (!e.repeat && (target.matches('input[type=radio],input[type=checkbox]') ? target.checked : target.value.trim() !== "")) this.advance(); return; }
      if (editing || e.repeat) return;
      const shortcut = this.el.dataset.shortcuts === "letters" ? e.key.toUpperCase() : e.key;
      const choice = controls.find(input => input.dataset.shortcut === shortcut);
      if (choice) { e.preventDefault(); choice.focus(); choice.click(); }
    };
    this.el.addEventListener("input", this.change); this.el.addEventListener("change", this.change);
    this.el.addEventListener("click", this.click); this.el.addEventListener("submit", this.submit, true);
    this.el.addEventListener("reset", this.reset); this.el.addEventListener("keydown", this.key);
    this.initialize(); this.refresh();
  },
  formPayload(submitter, changedName) {
    const data = submitter ? new FormData(this.el, submitter) : new FormData(this.el);
    const multiple = new Set(this.items().filter(item => item.hasAttribute("data-multiple")).map(item => item.getAttribute("phx-value-name")));
    const payload = { id: this.el.id };
    for (const name of new Set(data.keys())) payload[name] = multiple.has(name) ? data.getAll(name) : data.get(name);
    if (multiple.has(changedName) && !data.has(changedName)) payload[changedName] = [];
    return payload;
  },
  items() { return Array.from(this.el.querySelectorAll('[data-slot="questionnaire-item"]')).filter(item => !item.disabled); },
  controls(item) { return Array.from(item.querySelectorAll('[data-slot="questionnaire-choice-input"], [data-slot="questionnaire-input"]')).filter(control => !control.disabled); },
  state(item) {
    const name = item.getAttribute("phx-value-name");
    if (!this.states.has(name)) {
      const serverStatus = item.getAttribute("phx-value-server-status");
      this.states.set(name, { serverStatus, skipped: serverStatus === "skipped", attempted: false, invalid: item.getAttribute("phx-value-server-invalid") === "true" });
    }
    return this.states.get(name);
  },
  initialize(reset = false) {
    this.items().forEach(item => {
      this.state(item);
      this.controls(item).forEach(input => {
        const choice = input.dataset.slot === "questionnaire-choice-input";
        let defaults = this.controlDefaults.get(input.id);
        if (!defaults) {
          defaults = { checked: input.checked || input.getAttribute("phx-value-default-checked") === "true", value: input.defaultValue };
          this.controlDefaults.set(input.id, defaults);
          if (choice) input.checked = defaults.checked;
        }
        if (reset) { if (choice) input.checked = defaults.checked; else input.value = defaults.value; }
      });
    });
  },
  active() { return this.items().find(item => item.getAttribute("phx-value-name") === this.current); },
  answered(item) { return this.controls(item).some(input => input.matches('input[type=radio],input[type=checkbox]') ? input.checked : input.value.trim() !== ""); },
  validate(item) {
    const state = this.state(item); state.attempted = true;
    const valid = state.skipped && !item.hasAttribute("data-required") || !state.invalid && this.answered(item);
    if (!valid) { this.refresh(); return false; }
    if (!this.el.noValidate) {
      const invalid = this.controls(item).find(input => (input.checked || !input.matches('input[type=radio],input[type=checkbox]') && input.value.trim() !== "") && !input.validity.valid);
      if (invalid) { invalid.focus(); invalid.reportValidity(); return false; }
    }
    return true;
  },
  select(item, invalid = false) {
    if (!item) return;
    const name = item.getAttribute("phx-value-name"); const changed = this.current !== name; this.current = name; this.refresh();
    if (invalid) (this.controls(item)[0] || item).focus(); else item.focus();
    if (changed) {
      this.el.dispatchEvent(new CustomEvent("questionnaire:item-change", { bubbles: true, detail: { item: name } }));
      const event = this.el.getAttribute("phx-value-on-item-change"); if (event) this.sendEvent(event, { id: this.el.id, value: name });
    }
  },
  move(delta) { const items = this.items(); const index = items.indexOf(this.active()); this.select(items[index + delta]); },
  advance() { const item = this.active(); if (!item) return; if (!this.validate(item)) { this.select(item, true); return; } const items = this.items(); const next = items[items.indexOf(item) + 1]; if (next) this.select(next); else this.el.requestSubmit(); },
  skip() {
    const item = this.active(); if (!item || item.hasAttribute("data-required")) return;
    const state = this.state(item); state.skipped = true; state.attempted = false;
    this.controls(item).forEach(input => { if (input.matches('input[type=radio],input[type=checkbox]')) input.checked = false; });
    this.refresh(); const items = this.items(); const next = items[items.indexOf(item) + 1]; if (next) this.select(next); else this.el.requestSubmit();
  },
  flag(element, attribute, enabled) { if (enabled) element.setAttribute(attribute, ""); else element.removeAttribute(attribute); },
  refresh() {
    const items = this.items(); let active = this.active();
    if (!active) { active = items[0]; this.current = active ? active.getAttribute("phx-value-name") : null; }
    const current = active ? items.indexOf(active) + 1 : 0; const total = items.length;
    const first = current === 1; const last = total > 0 && current === total;
    this.el.dataset.current = current; this.el.dataset.total = total; this.flag(this.el,"data-first",first); this.flag(this.el,"data-last",last);
    this.el.querySelectorAll('[data-slot="questionnaire-item"]').forEach(item => {
      const state = this.state(item); const enabled = !item.disabled;
      const status = state.skipped ? "skipped" : this.answered(item) ? "answered" : "unanswered";
      const invalid = enabled && !state.skipped && (state.invalid || state.attempted && status !== "answered");
      const isActive = enabled && item === active; item.dataset.status = status;
      this.flag(item,"data-active",isActive); this.flag(item,"data-invalid",invalid);
      item.hidden = !isActive; item.inert = !isActive;
      if (invalid) item.setAttribute("aria-invalid","true"); else item.removeAttribute("aria-invalid");
      const controls = this.controls(item);
      const keys = isActive ? ["Meta+Enter Control+Enter", controls.length ? "ArrowUp ArrowDown" : "", !first ? "ArrowLeft" : "", !last && status !== "unanswered" ? "ArrowRight" : ""].filter(Boolean).join(" ") : "";
      if (keys) item.setAttribute("aria-keyshortcuts",keys); else item.removeAttribute("aria-keyshortcuts");
      const descriptions = Array.from(item.querySelectorAll('[data-slot="questionnaire-description"], [data-slot="questionnaire-error"]')).filter(node => node.dataset.slot !== "questionnaire-error" || invalid).map(node => node.id);
      const original = item.getAttribute("phx-value-describedby"); if (original) descriptions.push(original);
      if (!item.hasAttribute("phx-value-describedby")) item.setAttribute("phx-value-describedby", item.getAttribute("aria-describedby") || "");
      if (descriptions.length) item.setAttribute("aria-describedby", descriptions.join(" ")); else item.removeAttribute("aria-describedby");
      item.querySelectorAll('[data-slot="questionnaire-choice-input"], [data-slot="questionnaire-input"]').forEach(input => {
        const choice = input.dataset.slot === "questionnaire-choice-input";
        const selected = !state.skipped && (choice ? input.checked : input.value.trim() !== "");
        const name = item.getAttribute("phx-value-name");
        if (choice || selected) { input.removeAttribute("form"); if (!state.skipped) input.name = name; else input.removeAttribute("name"); }
        else { input.removeAttribute("name"); input.setAttribute("form", ""); }
        if (choice) {
          input.required = item.hasAttribute("data-required") && !item.hasAttribute("data-multiple") && !controls.some(control => control.dataset.slot === "questionnaire-input");
          [input, input.closest('[data-slot="questionnaire-choice"]')].forEach(node => { this.flag(node,"data-checked",input.checked); this.flag(node,"data-unchecked",!input.checked); this.flag(node,"data-invalid",invalid); });
        } else { this.flag(input,"data-filled",selected); this.flag(input,"data-empty",!selected); this.flag(input,"data-invalid",invalid); }
        if (invalid) input.setAttribute("aria-invalid","true"); else input.removeAttribute("aria-invalid");
        const shortcut = [input.dataset.shortcut, selected && !input.disabled ? "Enter" : null].filter(Boolean).join(" ");
        if (shortcut) input.setAttribute("aria-keyshortcuts",shortcut); else input.removeAttribute("aria-keyshortcuts");
      });
      item.querySelectorAll('[data-slot="questionnaire-error"]').forEach(error => { error.hidden = !invalid; this.flag(error,"data-invalid",invalid); if (invalid) error.setAttribute("role","alert"); else error.removeAttribute("role"); });
    });
    this.el.querySelectorAll('[data-slot="questionnaire-progress"]').forEach(progress => {
      progress.dataset.current = current; progress.dataset.total = total; this.flag(progress,"data-first",first); this.flag(progress,"data-last",last);
      const text = total ? "Question " + current + " of " + total : "";
      if (progress.getAttribute("phx-value-custom") !== "true") progress.textContent = text;
      ["aria-valuemin","aria-valuemax","aria-valuenow","aria-valuetext"].forEach(attr => { if (!total) progress.removeAttribute(attr); });
      if (total) { progress.setAttribute("aria-valuemin","1"); progress.setAttribute("aria-valuemax",total); progress.setAttribute("aria-valuenow",current); progress.setAttribute("aria-valuetext",text); }
    });
    ["previous","skip","next","submit"].forEach(action => this.el.querySelectorAll('[data-slot="questionnaire-' + action + '"]').forEach(button => {
      const visible = action === "previous" ? total > 1 && !first : action === "skip" ? !!active && !active.hasAttribute("data-required") : action === "next" ? total > 1 && !last : total > 0 && last;
      this.flag(button,"data-visible",visible); this.flag(button,"data-hidden",!visible); button.hidden = !visible; button.inert = !visible;
      if (!visible) { button.setAttribute("aria-hidden","true"); button.tabIndex = -1; } else { button.removeAttribute("aria-hidden"); const tab = button.getAttribute("phx-value-tabindex"); if (tab) button.tabIndex = Number(tab); else button.removeAttribute("tabindex"); }
      if (active) button.dataset.status = active.dataset.status; else button.removeAttribute("data-status");
      const shortcut = visible && !button.disabled && ["next","submit"].includes(action);
      if (shortcut) { button.dataset.shortcut = "Enter"; button.setAttribute("aria-keyshortcuts","Enter"); } else { delete button.dataset.shortcut; button.removeAttribute("aria-keyshortcuts"); }
    }));
  },
  beforeUpdate() {
    this.controlSnapshot = new Map(Array.from(this.el.querySelectorAll('input[data-slot]')).map(input => [input.id, {
      value: input.value, checked: input.checked, serverValue: input.getAttribute("value"), serverChecked: input.hasAttribute("checked")
    }]));
  },
  updated() {
    this.el.querySelectorAll('input[data-slot]').forEach(input => {
      const previous = this.controlSnapshot && this.controlSnapshot.get(input.id);
      if (!previous) return;
      const defaults = this.controlDefaults.get(input.id);
      if (input.getAttribute("value") === previous.serverValue) input.value = previous.value;
      else if (defaults) defaults.value = input.defaultValue;
      if (input.hasAttribute("checked") === previous.serverChecked) input.checked = previous.checked;
      else if (defaults) defaults.checked = input.checked;
    });
    const item = this.el.getAttribute("phx-value-item"); if (item !== this.serverItem) { this.current = item; this.serverItem = item; }
    this.el.querySelectorAll('[data-slot="questionnaire-item"]').forEach(fieldset => {
      const state = this.state(fieldset); state.invalid = fieldset.getAttribute("phx-value-server-invalid") === "true";
      const serverStatus = fieldset.getAttribute("phx-value-server-status");
      if (serverStatus !== state.serverStatus) { state.skipped = serverStatus === "skipped"; state.serverStatus = serverStatus; }
    });
    this.initialize(); this.refresh();
  },
  destroyed() {
    this.el.removeEventListener("input",this.change); this.el.removeEventListener("change",this.change); this.el.removeEventListener("click",this.click);
    this.el.removeEventListener("submit",this.submit,true); this.el.removeEventListener("reset",this.reset); this.el.removeEventListener("keydown",this.key);
  }
}`
