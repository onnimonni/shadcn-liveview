export const chartHook = String.raw`      export default {
        mounted() {
          this.container = this.el.closest(".recharts-responsive-container");
          this.listeners = [];
          this.resize = () => this.draw();
          this.observer = new ResizeObserver(this.resize);
          this.observer.observe(this.container);
          this.draw();
        },
        updated() { this.draw(); },
        destroyed() {
          this.observer.disconnect();
          this.cleanListeners();
        },
        cleanListeners() {
          cancelAnimationFrame(this.animation);
          for (const [node, event, handler] of this.listeners || []) node.removeEventListener(event, handler);
          this.listeners = [];
        },
        draw() {
          this.cleanListeners();
          const options = JSON.parse(this.el.getAttribute("phx-value-chart"));
          this.canvas = this.el.querySelector(".recharts-wrapper");
          const box = this.container.getBoundingClientRect();
          if (box.width <= 0 || box.height <= 0) { this.canvas.replaceChildren(); return; }
          const width = Math.round(box.width), height = Math.round(box.height);
          Object.assign(this.canvas.style, {width: width + "px", height: height + "px"});
          this.canvas.setAttribute("width", width);
          this.canvas.setAttribute("height", height);
          const svgNode = (tag, attrs, text) => {
            const node = document.createElementNS("http://www.w3.org/2000/svg", tag);
            for (const [key, value] of Object.entries(attrs || {})) node.setAttribute(key, String(value));
            if (text !== undefined) node.textContent = String(text);
            return node;
          };
          const htmlNode = (tag, className, text) => {
            const node = document.createElement(tag);
            node.className = className;
            if (text !== undefined) node.textContent = String(text);
            return node;
          };
          const listen = (node, event, handler) => {
            node.addEventListener(event, handler);
            this.listeners.push([node, event, handler]);
          };
          const svg = svgNode("svg", {width, height, viewBox: "0 0 " + width + " " + height,
            role: "application", tabindex: 0, "aria-label": options.label, class: "recharts-surface"});
          Object.assign(svg.style, {width: "100%", height: "100%", display: "block"});
          this.canvas.replaceChildren(svg);
          const data = options.data, series = options.series;
          const number = (row, key) => typeof row[key] === "number" && Number.isFinite(row[key]) ? row[key] : null;
          const label = index => data[index][options.xKey] ?? index;
          let legendHeight = 0;
          if (options.legend && series.length) {
            const wrapper = htmlNode("div", "recharts-legend-wrapper");
            Object.assign(wrapper.style, {position: "absolute", bottom: "5px", left: "5px", width: Math.max(0, width - 10) + "px"});
            const legend = htmlNode("div", "flex items-center justify-center gap-4 pt-3");
            for (const item of series) {
              const entry = htmlNode("div", "flex items-center gap-1.5 [&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground");
              const swatch = htmlNode("div", "h-2 w-2 shrink-0 rounded-[2px]");
              swatch.style.backgroundColor = item.color;
              entry.append(swatch, document.createTextNode(item.label));
              legend.append(entry);
            }
            wrapper.append(legend);
            this.canvas.append(wrapper);
            legendHeight = wrapper.getBoundingClientRect().height;
          }
          const left = 5, top = 5, right = Math.max(left, width - 5);
          const bottom = Math.max(top, height - 5 - (options.axes ? 30 : 0) - legendHeight);
          const plotWidth = right - left, plotHeight = bottom - top;
          const values = data.flatMap(row => series.map(item => number(row, item.key))).filter(value => value !== null);
          let minimum = Math.min(0, ...values), maximum = Math.max(0, ...values);
          // Recharts' implicit numeric axis is [0, "auto"], five adaptive nice ticks.
          // Its default allowDataOverflow=false expands the lower bound for signed data.
          if (minimum === maximum) { minimum = 0; maximum = 4; }
          else {
            const rough = (maximum - minimum) / 4;
            const digits = Math.floor(Math.log10(rough)) + 1;
            const magnitude = Math.pow(10, digits), ratio = digits === 1 ? 0.1 : 0.05;
            let correction = 0, lowCount, highCount, step;
            do {
              step = (Math.ceil(rough / magnitude / ratio - 1e-12) + correction++) * ratio * magnitude;
              lowCount = Math.ceil(-minimum / step - 1e-12);
              highCount = Math.ceil(maximum / step - 1e-12);
            } while (lowCount + highCount + 1 > 5);
            if (maximum > 0) highCount += 4 - lowCount - highCount;
            else lowCount += 4 - lowCount - highCount;
            minimum = -lowCount * step;
            maximum = highCount * step;
          }
          const y = value => bottom - (value - minimum) / (maximum - minimum) * plotHeight;
          const step = data.length ? plotWidth / data.length : 0;
          const x = index => options.kind === "bar" || data.length === 1
            ? left + step * (index + 0.5) : left + plotWidth * index / (data.length - 1);
          const zero = y(0);
          const cursor = svgNode("g", {"pointer-events": "none"});
          const geometry = svgNode("g", {class: "recharts-layer"});
          svg.append(cursor, geometry);
          const animations = [], nextBars = new Map();
          const signature = JSON.stringify([options.data, options.series, options.kind, width, height]);
          const animate = signature !== this.signature && !matchMedia("(prefers-reduced-motion: reduce)").matches;
          this.signature = signature;
          const round = value => Number(value.toFixed(4));
          series.forEach((item, seriesIndex) => {
            const group = svgNode("g", {class: "recharts-layer recharts-" + options.kind});
            geometry.append(group);
            if (options.kind === "bar") {
              let gap = 4;
              if (step * 0.8 - (series.length - 1) * gap <= 0) gap = 0;
              let barWidth = (step * 0.8 - (series.length - 1) * gap) / series.length;
              if (barWidth > 1) barWidth = Math.floor(barWidth);
              const rectangles = svgNode("g", {class: "recharts-bar-rectangles"});
              group.append(rectangles);
              data.forEach((row, index) => {
                const value = number(row, item.key);
                if (value === null || value === 0 || barWidth <= 0) return;
                const current = {x: left + index * step + step * 0.1 + seriesIndex * (barWidth + gap),
                  y: y(value), width: barWidth, height: zero - y(value)};
                const key = item.key + ":" + index;
                nextBars.set(key, current);
                const rect = svgNode("path", {fill: item.color, radius: 0, class: "recharts-rectangle"});
                const render = shape => {
                  for (const name of ["x", "y", "width", "height"]) rect.setAttribute(name, round(shape[name]));
                  rect.setAttribute("d", "M " + round(shape.x) + "," + round(shape.y) + " h " + round(shape.width) + " v " + round(shape.height) + " h " + round(-shape.width) + " Z");
                };
                rectangles.append(rect);
                render(current);
                if (animate) {
                  const previous = this.bars?.get(key) || {...current, y: zero, height: 0};
                  animations.push(t => render(Object.fromEntries(Object.keys(current).map(name => [name, previous[name] + (current[name] - previous[name]) * t]))));
                }
              });
            } else {
              const segments = [];
              let segment = [];
              for (let index = 0; index < data.length; index++) {
                const value = number(data[index], item.key);
                if (value === null) { if (segment.length) segments.push(segment); segment = []; }
                else segment.push([x(index), y(value)]);
              }
              if (segment.length) segments.push(segment);
              const point = p => Number(p[0].toFixed(3)) + "," + Number(p[1].toFixed(3));
              const curve = segments.map(points => "M" + points.map(point).join("L") + (points.length === 1 ? "Z" : "")).join("");
              if (options.kind === "area") {
                const area = svgNode("path", {d: segments.map(points => "M" + points.map(point).join("L") + "L" + point([points[points.length - 1][0], zero]) + "L" + point([points[0][0], zero]) + "Z").join(""),
                  fill: item.color, "fill-opacity": 0.6, stroke: "none", class: "recharts-curve recharts-area-area"});
                group.append(area);
                if (animate && segments.length) {
                  const clipId = this.el.id + "-area-animation-" + seriesIndex;
                  const clip = svgNode("clipPath", {id: clipId});
                  const clipRect = svgNode("rect", {x: left, y: 0, width: 0, height: Math.floor(Math.max(zero, ...segments.flat().map(p => p[1])) + 1)});
                  clip.append(clipRect);
                  svg.append(clip);
                  group.setAttribute("clip-path", "url(#" + clipId + ")");
                  animations.push(t => clipRect.setAttribute("width", t * plotWidth));
                }
              }
              if (data.length > 1) {
                const path = svgNode("path", {d: curve, fill: "none", stroke: item.color, "stroke-width": 1,
                  class: "recharts-curve recharts-" + options.kind + "-curve"});
                group.append(path);
                if (animate && options.kind === "line") {
                  const length = path.getTotalLength();
                  animations.push(t => path.setAttribute("stroke-dasharray", t * length + "px " + length + "px"));
                }
              }
              if (options.kind === "line") {
                const dots = svgNode("g", {class: "recharts-layer recharts-line-dots"});
                for (const points of segments) for (const p of points)
                  dots.append(svgNode("circle", {cx: p[0], cy: p[1], r: 3, fill: "#fff", stroke: item.color,
                    "stroke-width": 1, class: "recharts-dot recharts-line-dot"}));
                group.append(dots);
                if (animate && data.length > 1) animations.push(t => { dots.style.visibility = t === 1 ? "visible" : "hidden"; });
              }
            }
          });
          this.bars = nextBars;
          if (options.axes && data.length) {
            const axis = svgNode("g", {class: "recharts-layer recharts-cartesian-axis recharts-xAxis xAxis"});
            axis.append(svgNode("line", {x1: left, x2: right, y1: bottom, y2: bottom, stroke: "#666", fill: "none", class: "recharts-cartesian-axis-line"}));
            svg.append(axis);
            // Default XAxis interval="preserveEnd" measures text, shifts the final tick,
            // and rejects labels that would overlap or extend beyond the axis viewport.
            const measure = htmlNode("span", "");
            Object.assign(measure.style, {position: "absolute", whiteSpace: "pre", visibility: "hidden", fontSize: getComputedStyle(this.container).fontSize, letterSpacing: getComputedStyle(this.container).letterSpacing});
            document.body.append(measure);
            let end = width;
            const ticks = [];
            for (let index = data.length - 1; index >= 0; index--) {
              measure.textContent = String(label(index));
              const size = measure.getBoundingClientRect().width;
              const coordinate = x(index);
              const tickCoordinate = index === data.length - 1 ? Math.min(coordinate, width - size / 2) : coordinate;
              if (tickCoordinate - size / 2 < 0 || tickCoordinate + size / 2 > end) continue;
              end = tickCoordinate - size / 2 - 5;
              ticks.unshift({index, coordinate, tickCoordinate});
            }
            measure.remove();
            for (const tick of ticks) {
              const layer = svgNode("g", {class: "recharts-layer recharts-cartesian-axis-tick"});
              layer.append(svgNode("line", {x1: tick.coordinate, x2: tick.coordinate, y1: bottom + 6, y2: bottom, stroke: "#666", class: "recharts-cartesian-axis-tick-line"}));
              const text = svgNode("text", {x: tick.tickCoordinate, y: bottom + 8, "text-anchor": "middle", fill: "#666", class: "recharts-text recharts-cartesian-axis-tick-value"});
              text.append(svgNode("tspan", {x: tick.tickCoordinate, dy: "0.71em"}, label(tick.index)));
              layer.append(text);
              axis.append(layer);
            }
          }
          const activeDots = svgNode("g", {class: "recharts-layer recharts-active-dot"});
          svg.append(activeDots);
          const tooltip = htmlNode("div", "recharts-tooltip-wrapper");
          Object.assign(tooltip.style, {position: "absolute", top: "0", left: "0", pointerEvents: "none", visibility: "hidden", transition: "transform 400ms"});
          if (options.tooltip) this.canvas.append(tooltip);
          let keyboardIndex = 0, keyboardActive = false;
          const hide = () => { tooltip.style.visibility = "hidden"; cursor.replaceChildren(); activeDots.replaceChildren(); };
          const show = (index, pointerY) => {
            if (!options.tooltip || index < 0 || index >= data.length) return;
            tooltip.replaceChildren();
            cursor.replaceChildren();
            activeDots.replaceChildren();
            if (options.kind === "bar") cursor.append(svgNode("rect", {x: left + index * step, y: top + 0.5, width: step, height: Math.max(0, plotHeight - 1), fill: "#ccc", stroke: "none", class: "recharts-rectangle recharts-tooltip-cursor"}));
            else cursor.append(svgNode("path", {d: "M" + x(index) + "," + top + "L" + x(index) + "," + bottom, fill: "none", stroke: "#ccc", class: "recharts-curve recharts-tooltip-cursor"}));
            const content = htmlNode("div", "grid min-w-32 items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl");
            content.append(htmlNode("div", "font-medium", label(index)));
            const entries = htmlNode("div", "grid gap-1.5");
            for (const item of series) {
              const value = number(data[index], item.key);
              if (value === null) continue;
              const row = htmlNode("div", "flex w-full flex-wrap gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5 [&>svg]:text-muted-foreground items-center");
              const indicator = htmlNode("div", "shrink-0 rounded-[2px] border-(--color-border) bg-(--color-bg) h-2.5 w-2.5");
              indicator.style.setProperty("--color-bg", item.color);
              indicator.style.setProperty("--color-border", item.color);
              const valueRow = htmlNode("div", "flex flex-1 justify-between leading-none items-center");
              const name = htmlNode("div", "grid gap-1.5");
              name.append(htmlNode("span", "text-muted-foreground", item.label));
              valueRow.append(name, htmlNode("span", "font-mono font-medium text-foreground tabular-nums", value.toLocaleString()));
              row.append(indicator, valueRow);
              entries.append(row);
              if (options.kind !== "bar") activeDots.append(svgNode("circle", {cx: x(index), cy: y(value), r: 4, fill: item.color, stroke: "#fff", "stroke-width": 2, class: "recharts-dot"}));
            }
            if (!entries.childElementCount) { tooltip.style.visibility = "hidden"; return; }
            content.append(entries);
            tooltip.append(content);
            const tw = tooltip.offsetWidth, th = tooltip.offsetHeight;
            const coordinateY = pointerY ?? (top + height) / 2;
            const tx = x(index) + 10 + tw > right ? Math.max(left, x(index) - tw - 10) : Math.max(left, x(index) + 10);
            const ty = coordinateY + 10 + th > bottom ? Math.max(top, coordinateY - th - 10) : Math.max(top, coordinateY + 10);
            tooltip.style.transform = "translate(" + tx + "px, " + ty + "px)";
            tooltip.className = "recharts-tooltip-wrapper recharts-tooltip-wrapper-" + (tx >= x(index) ? "right" : "left") + " recharts-tooltip-wrapper-" + (ty >= coordinateY ? "bottom" : "top");
            tooltip.style.visibility = "visible";
          };
          listen(svg, "pointermove", event => {
            const bounds = svg.getBoundingClientRect(), px = event.clientX - bounds.left, py = event.clientY - bounds.top;
            if (px < left || px > right || py < top || py > bottom || !data.length) { hide(); return; }
            const index = options.kind === "bar" ? Math.min(data.length - 1, Math.floor((px - left) / step))
              : data.length === 1 ? 0 : Math.max(0, Math.min(data.length - 1, Math.round((px - left) / plotWidth * (data.length - 1))));
            show(index, py);
          });
          listen(svg, "pointerleave", hide);
          listen(svg, "focus", () => { keyboardActive = true; show(keyboardIndex); });
          listen(svg, "blur", () => { keyboardActive = false; hide(); });
          listen(svg, "keydown", event => {
            if (event.key === "ArrowRight" || event.key === "ArrowLeft") {
              event.preventDefault();
              keyboardIndex = Math.max(0, Math.min(data.length - 1, keyboardIndex + (event.key === "ArrowRight" ? 1 : -1)));
              keyboardActive = true;
              show(keyboardIndex);
            } else if (event.key === "Enter") {
              keyboardActive = !keyboardActive;
              if (keyboardActive) show(keyboardIndex); else hide();
            } else if (event.key === "Escape") tooltip.style.visibility = "hidden";
          });
          if (animate && animations.length) {
            // CSS ease = cubic-bezier(.25,.1,.25,1), also Recharts' default easing.
            const ease = t => {
              const bezier = (s, a, b) => 3 * (1 - s) * (1 - s) * s * a + 3 * (1 - s) * s * s * b + s * s * s;
              let low = 0, high = 1;
              for (let i = 0; i < 16; i++) { const middle = (low + high) / 2; if (bezier(middle, 0.25, 0.25) < t) low = middle; else high = middle; }
              return bezier((low + high) / 2, 0.1, 1);
            };
            const start = performance.now(), duration = options.kind === "bar" ? 400 : 1500;
            const frame = now => {
              const progress = Math.min(1, (now - start) / duration);
              for (const render of animations) render(progress === 1 ? 1 : ease(progress));
              if (progress < 1) this.animation = requestAnimationFrame(frame);
            };
            for (const render of animations) render(0);
            this.animation = requestAnimationFrame(frame);
          }
        }
      }`
