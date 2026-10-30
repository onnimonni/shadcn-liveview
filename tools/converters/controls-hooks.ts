import { sendEventMethod } from "./hook-events"

export const thumbClass = "relative block size-3 shrink-0 rounded-full border border-ring bg-white ring-ring/50 transition-[color,box-shadow] select-none after:absolute after:-inset-2 hover:ring-3 focus-visible:ring-3 focus-visible:outline-hidden active:ring-3 disabled:pointer-events-none disabled:opacity-50"
export const indicatorClass = "grid place-content-center text-current transition-none [&>svg]:size-3.5"

export const binaryHook = `      export default {
${sendEventMethod("        ")}
        mounted() {
          this.initial = this.el.getAttribute("phx-value-initial");
          this.click = () => {
            if (this.el.disabled) return;
            this.setState(this.el.getAttribute("data-state") === "checked" ? "unchecked" : "checked", true);
          };
          this.reset = () => { this.resetFrame = requestAnimationFrame(() => this.setState(this.initial, true)); };
          // As in Radix, an external form reset restores only the native input's mounted value.
          this.nativeReset = () => {
            this.nativeFrame = requestAnimationFrame(() => { this.nativeState = this.initial; this.syncInput(); });
          };
          this.invalid = () => this.el.focus();
          // LiveView derives the native checked property from its checked attribute, including
          // when it applies cloned trees of locked forms without updating this hook.
          this.observer = new MutationObserver(() => this.syncInput());
          this.el.addEventListener("click", this.click);
          this.updated();
        },
        updated() {
          const input = this.el.nextElementSibling;
          if (input !== this.input) {
            this.input?.removeEventListener("invalid", this.invalid);
            input.addEventListener("invalid", this.invalid);
            this.observer.disconnect();
            this.observer.observe(input, {attributes: true, attributeFilter: ["checked"]});
            this.input = input;
          }
          this.serverState = this.el.getAttribute("phx-value-state");
          const controlled = this.el.getAttribute("phx-value-controlled") === "true";
          this.serverChildren = Array.from(this.el.childNodes);
          // Checkbox reset follows the trigger's form; Switch also follows form=.
          const checkbox = this.el.getAttribute("role") === "checkbox";
          const form = checkbox ? this.el.form : this.input.form;
          this.listenReset("form", form, this.reset);
          this.listenReset("nativeForm", checkbox && this.input.form !== form ? this.input.form : null, this.nativeReset);
          this.setState(controlled || this.state === undefined ? this.serverState : this.state, false);
        },
        beforeUpdate() {
          // Morph from the server-rendered trigger; updated() reapplies local state.
          this.el.replaceChildren(...this.serverChildren);
          this.paint(this.serverState);
        },
        listenReset(key, form, listener) {
          if (this[key] === form) return;
          if (this[key]) this[key].removeEventListener("reset", listener);
          this[key] = form;
          if (form) form.addEventListener("reset", listener);
        },
        setState(state, notify) {
          if (state !== this.state) this.nativeState = undefined;
          this.state = state;
          this.paint(state);
          this.syncInput();
          if (!notify) return;
          this.input.dispatchEvent(new Event("input", {bubbles:true}));
          this.input.dispatchEvent(new Event("change", {bubbles:true}));
          const event = this.el.getAttribute("phx-value-change");
          // Controlled state comes from the server, so a failed push restores it.
          if (event) this.sendEvent(event, {id:this.el.id, value:state === "checked"}).catch(() => {
            if (this.el.getAttribute("phx-value-controlled") === "true") this.setState(this.serverState, false);
          });
        },
        // The checked attribute mirrors the property so LiveView patches and clones keep it.
        syncInput() {
          const state = this.nativeState ?? this.state;
          const checked = state === "checked";
          this.input.checked = checked;
          this.input.indeterminate = state === "indeterminate";
          if (this.input.defaultChecked !== checked) this.input.defaultChecked = checked;
        },
        paint(state) {
          this.el.setAttribute("data-state", state);
          this.el.setAttribute("aria-checked", state === "indeterminate" ? "mixed" : String(state === "checked"));
          let child = this.el.firstElementChild;
          if (this.el.getAttribute("role") === "checkbox") {
            if (state === "unchecked") { if (child) child.remove(); }
            else if (!child) {
              child = document.createElement("span");
              child.setAttribute("data-slot", "checkbox-indicator");
              child.className = ${JSON.stringify(indicatorClass)};
              child.style.pointerEvents = "none";
              const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
              for (const [key, value] of Object.entries({viewBox:"0 0 24 24",width:"24",height:"24",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"})) svg.setAttribute(key,value);
              const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
              path.setAttribute("d", "M20 6 9 17l-5-5");
              svg.append(path); child.append(svg); this.el.append(child);
            }
          }
          if (child && state !== "unchecked") child.setAttribute("data-state", state);
          if (child && this.el.getAttribute("role") === "switch") child.setAttribute("data-state", state);
        },
        destroyed() {
          cancelAnimationFrame(this.resetFrame);
          cancelAnimationFrame(this.nativeFrame);
          this.observer.disconnect();
          this.el.removeEventListener("click", this.click);
          this.input.removeEventListener("invalid", this.invalid);
          this.listenReset("form", null, this.reset);
          this.listenReset("nativeForm", null, this.nativeReset);
        }
      }`

export const sliderHook = `      export default {
${sendEventMethod("        ")}
        mounted() {
          this.initial = JSON.parse(this.el.getAttribute("phx-value-initial"));
          this.keydown = event => {
            const index = this.thumbs.indexOf(event.target);
            if (index < 0 || index >= this.values.length || this.disabled) return;
            const key = event.key;
            if (!["ArrowLeft","ArrowRight","ArrowUp","ArrowDown","PageUp","PageDown","Home","End"].includes(key)) return;
            event.preventDefault();
            let next = this.values[index];
            if (key === "Home") next = this.min;
            else if (key === "End") next = this.max;
            else {
              let forward = key === "ArrowUp" || key === "ArrowRight" || key === "PageUp";
              const reverseKey = this.vertical
                ? this.inverted && ["ArrowUp","ArrowDown"].includes(key)
                : this.reverse && ["ArrowLeft","ArrowRight"].includes(key);
              if (reverseKey) forward = !forward;
              next += (forward ? 1 : -1) * this.step * (key.startsWith("Page") || event.shiftKey ? 10 : 1);
            }
            this.change(index, next);
          };
          this.pointerdown = event => {
            if (this.disabled || event.button !== 0 || !this.values.length) return;
            event.preventDefault();
            const value = this.pointerValue(event);
            const targetIndex = this.thumbs.indexOf(event.target.closest('[data-slot="slider-thumb"]'));
            this.active = targetIndex >= 0 && targetIndex < this.values.length ? targetIndex : this.values.reduce((best, item, index) => Math.abs(item-value) < Math.abs(this.values[best]-value) ? index : best, 0);
            this.el.setPointerCapture(event.pointerId);
            this.thumbs[this.active].focus();
            this.change(this.active, value);
          };
          this.pointermove = event => { if (!this.disabled && this.active < this.values.length && this.el.hasPointerCapture(event.pointerId)) this.change(this.active, this.pointerValue(event)); };
          this.pointerup = event => { if (this.el.hasPointerCapture(event.pointerId)) this.el.releasePointerCapture(event.pointerId); };
          this.reset = () => { this.resetFrame = requestAnimationFrame(() => { this.values = [...this.initial]; this.render(); this.notify(); }); };
          this.el.addEventListener("keydown", this.keydown);
          this.el.addEventListener("pointerdown", this.pointerdown);
          this.el.addEventListener("pointermove", this.pointermove);
          this.el.addEventListener("pointerup", this.pointerup);
          this.updated();
        },
        beforeUpdate() {
          this.focusedThumbIndex = this.thumbs.indexOf(this.el.ownerDocument.activeElement);
          this.el.replaceChildren(...this.serverChildren);
          for (const {element, attributes} of this.serverAttributes) {
            for (const attribute of Array.from(element.attributes)) element.removeAttribute(attribute.name);
            for (const [name, value] of attributes) element.setAttribute(name, value);
          }
        },
        updated() {
          if (this.el.getAttribute("phx-value-controlled") === "true" || this.values === undefined) {
            this.values = JSON.parse(this.el.getAttribute("phx-value-values"));
          }
          this.min = Number(this.el.getAttribute("phx-value-min"));
          this.max = Number(this.el.getAttribute("phx-value-max"));
          this.step = Number(this.el.getAttribute("phx-value-step"));
          this.distance = Number(this.el.getAttribute("phx-value-distance")) * this.step;
          this.vertical = this.el.getAttribute("data-orientation") === "vertical";
          this.inverted = this.el.getAttribute("phx-value-inverted") === "true";
          this.reverse = (this.el.getAttribute("dir") === "rtl") !== this.inverted;
          this.disabled = this.el.getAttribute("aria-disabled") === "true";
          this.thumbs = Array.from(this.el.querySelectorAll('[data-slot="slider-thumb"]'));
          this.inputs = Array.from(this.el.querySelectorAll("input"));
          // Restore the server's DOM before a patch without replacing local values.
          this.serverChildren = Array.from(this.el.childNodes);
          this.serverAttributes = [
            ...this.thumbs.flatMap(thumb => [thumb, thumb.parentElement]),
            ...this.inputs,
            this.el.querySelector('[data-slot="slider-range"]')
          ].map(element => ({element, attributes:Array.from(element.attributes, attribute => [attribute.name, attribute.value])}));
          this.render();
          const focusedThumb = this.thumbs[this.focusedThumbIndex];
          const activeElement = this.el.ownerDocument.activeElement;
          if (!this.disabled && this.focusedThumbIndex < this.values.length && focusedThumb &&
              (activeElement === this.el.ownerDocument.body || activeElement === focusedThumb)) {
            focusedThumb.focus({preventScroll:true});
          }
          this.focusedThumbIndex = -1;
          const formId = this.el.getAttribute("phx-value-form");
          const form = this.inputs[0]?.form || (formId ? document.getElementById(formId) : this.el.closest("form"));
          if (this.form !== form) {
            if (this.form) this.form.removeEventListener("reset", this.reset);
            this.form = form;
            if (this.form) this.form.addEventListener("reset", this.reset);
          }
        },
        pointerValue(event) {
          const box = this.el.getBoundingClientRect();
          let fraction = this.vertical ? (box.bottom-event.clientY)/box.height : (event.clientX-box.left)/box.width;
          if (this.vertical ? this.inverted : this.reverse) fraction = 1-fraction;
          return this.min + fraction*(this.max-this.min);
        },
        change(index, value) {
          const [digits, exponent] = String(this.step).split("e");
          const precision = Math.max(0, (digits.split(".")[1] || "").length - Number(exponent || 0));
          const snapped = Number((Math.round((value-this.min)/this.step)*this.step+this.min).toFixed(precision));
          const lower = index ? this.values[index-1]+this.distance : this.min;
          const upper = index < this.values.length-1 ? this.values[index+1]-this.distance : this.max;
          const next = Math.max(lower, Math.min(upper, snapped));
          if (next === this.values[index]) return;
          this.values[index] = next;
          this.render(); this.notify();
        },
        render() {
          // Uncontrolled values can outlive a server-side thumb-count change.
          while (this.thumbs.length < this.values.length) {
            const wrapper = document.createElement("span");
            wrapper.style.cssText = "transform:var(--radix-slider-thumb-transform);position:absolute";
            const thumb = document.createElement("span");
            thumb.setAttribute("role", "slider");
            thumb.setAttribute("data-slot", "slider-thumb");
            thumb.setAttribute("data-radix-collection-item", "");
            thumb.className = ${JSON.stringify(thumbClass)};
            const input = document.createElement("input");
            input.style.display = "none";
            wrapper.append(thumb);
            this.el.append(wrapper, input);
            this.thumbs.push(thumb);
            this.inputs.push(input);
          }
          const start = this.vertical ? (this.inverted ? "top" : "bottom") : (this.reverse ? "right" : "left");
          const end = this.vertical ? (this.inverted ? "bottom" : "top") : (this.reverse ? "left" : "right");
          const percents = this.values.map(value => Math.max(0, Math.min(100, 100/(this.max-this.min)*(value-this.min))));
          this.thumbs.forEach((thumb,index) => {
            if (this.values[index] === undefined) {
              thumb.style.display = "none";
              if (this.inputs[index]) {
                this.inputs[index].value = "";
                this.inputs[index].disabled = true;
              }
              return;
            }
            thumb.style.display = "";
            thumb.setAttribute("data-orientation", this.vertical ? "vertical" : "horizontal");
            thumb.setAttribute("aria-orientation", this.vertical ? "vertical" : "horizontal");
            if (this.disabled) {
              thumb.setAttribute("data-disabled", "");
              thumb.removeAttribute("tabindex");
            } else {
              thumb.removeAttribute("data-disabled");
              thumb.setAttribute("tabindex", "0");
            }
            thumb.setAttribute("aria-valuenow", String(this.values[index]));
            const label = this.values.length > 2 ? "Value " + (index+1) + " of " + this.values.length : this.values.length === 2 ? ["Minimum","Maximum"][index] : null;
            if (label) thumb.setAttribute("aria-label", label);
            else thumb.removeAttribute("aria-label");
            thumb.setAttribute("aria-valuemin", String(index ? this.values[index-1]+this.distance : this.min));
            thumb.setAttribute("aria-valuemax", String(index < this.values.length-1 ? this.values[index+1]-this.distance : this.max));
            thumb.parentElement.style[start] = percents[index] + "%";
            const input = this.inputs[index];
            if (input) {
              input.type = "hidden";
              // Radix disables interaction, not the submitted slider inputs.
              input.disabled = false;
              input.value = String(this.values[index]);
              const name = this.el.getAttribute("phx-value-name");
              if (name !== null) input.name = name + (this.values.length > 1 ? "[]" : "");
              else input.removeAttribute("name");
              const form = this.el.getAttribute("phx-value-form");
              if (form) input.setAttribute("form", form);
              else input.removeAttribute("form");
            }
          });
          const range = this.el.querySelector('[data-slot="slider-range"]');
          range.style[start] = (percents.length > 1 ? Math.min(...percents) : 0) + "%";
          range.style[end] = (100-Math.max(...percents)) + "%";
        },
        notify() {
          this.inputs.forEach(input => { input.dispatchEvent(new Event("input",{bubbles:true})); input.dispatchEvent(new Event("change",{bubbles:true})); });
          const event = this.el.getAttribute("phx-value-change");
          // Controlled values come from the server, so a failed push restores them.
          if (event) this.sendEvent(event,{id:this.el.id,value:this.values}).catch(() => {
            if (this.el.getAttribute("phx-value-controlled") === "true") { this.values = JSON.parse(this.el.getAttribute("phx-value-values")); this.render(); }
          });
        },
        destroyed() {
          cancelAnimationFrame(this.resetFrame);
          this.el.removeEventListener("keydown",this.keydown);
          this.el.removeEventListener("pointerdown",this.pointerdown);
          this.el.removeEventListener("pointermove",this.pointermove);
          this.el.removeEventListener("pointerup",this.pointerup);
          if (this.form) this.form.removeEventListener("reset",this.reset);
        }
      }`
