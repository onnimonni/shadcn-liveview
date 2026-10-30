export const chartHook = String.raw`      // d3-shape 3.2 curve ports (Recharts type linear/natural/monotone/step); browser
      // Recharts builds use its line()/area() path output rounded to 3 digits.
      const pathContext = () => {
        let d = "";
        const append = (command, values) => { d += command + values.map(value => Math.round(value * 1000) / 1000).join(","); };
        return {
          moveTo: (x, y) => append("M", [x, y]),
          lineTo: (x, y) => append("L", [x, y]),
          bezierCurveTo: (x1, y1, x2, y2, x, y) => append("C", [x1, y1, x2, y2, x, y]),
          closePath: () => { d += "Z"; },
          toString: () => d
        };
      };
      const controlPoints = x => {
        let i, m;
        const n = x.length - 1, a = new Array(n), b = new Array(n), r = new Array(n);
        a[0] = 0; b[0] = 2; r[0] = x[0] + 2 * x[1];
        for (i = 1; i < n - 1; ++i) { a[i] = 1; b[i] = 4; r[i] = 4 * x[i] + 2 * x[i + 1]; }
        a[n - 1] = 2; b[n - 1] = 7; r[n - 1] = 8 * x[n - 1] + x[n];
        for (i = 1; i < n; ++i) { m = a[i] / b[i - 1]; b[i] -= m; r[i] -= m * r[i - 1]; }
        a[n - 1] = r[n - 1] / b[n - 1];
        for (i = n - 2; i >= 0; --i) a[i] = (r[i] - a[i + 1]) / b[i];
        b[n - 1] = (x[n] + a[n - 1]) / 2;
        for (i = 0; i < n - 1; ++i) b[i] = 2 * x[i + 1] - a[i + 1];
        return [a, b];
      };
      const sign = v => v < 0 ? -1 : 1;
      const curves = {
        linear: ctx => ({
          areaStart() { this.line = 0; }, areaEnd() { this.line = NaN; }, lineStart() { this.count = 0; },
          lineEnd() { if (this.line || (this.line !== 0 && this.count === 1)) ctx.closePath(); this.line = 1 - this.line; },
          point(x, y) {
            if (this.count === 0) { this.count = 1; this.line ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
            else { this.count = 2; ctx.lineTo(x, y); }
          }
        }),
        natural: ctx => ({
          areaStart() { this.line = 0; }, areaEnd() { this.line = NaN; },
          lineStart() { this.xs = []; this.ys = []; },
          lineEnd() {
            const xs = this.xs, ys = this.ys, n = xs.length;
            if (n) {
              this.line ? ctx.lineTo(xs[0], ys[0]) : ctx.moveTo(xs[0], ys[0]);
              if (n === 2) ctx.lineTo(xs[1], ys[1]);
              else {
                const px = controlPoints(xs), py = controlPoints(ys);
                for (let i0 = 0, i1 = 1; i1 < n; ++i0, ++i1) ctx.bezierCurveTo(px[0][i0], py[0][i0], px[1][i0], py[1][i0], xs[i1], ys[i1]);
              }
            }
            if (this.line || (this.line !== 0 && n === 1)) ctx.closePath();
            this.line = 1 - this.line;
          },
          point(x, y) { this.xs.push(x); this.ys.push(y); }
        }),
        monotone: ctx => ({
          areaStart() { this.line = 0; }, areaEnd() { this.line = NaN; },
          lineStart() { this.x0 = this.x1 = this.y0 = this.y1 = this.t0 = NaN; this.count = 0; },
          slope3(x2, y2) {
            const h0 = this.x1 - this.x0, h1 = x2 - this.x1;
            const s0 = (this.y1 - this.y0) / (h0 || (h1 < 0 && -0)), s1 = (y2 - this.y1) / (h1 || (h0 < 0 && -0));
            const p = (s0 * h1 + s1 * h0) / (h0 + h1);
            return (sign(s0) + sign(s1)) * Math.min(Math.abs(s0), Math.abs(s1), 0.5 * Math.abs(p)) || 0;
          },
          slope2(t) { const h = this.x1 - this.x0; return h ? (3 * (this.y1 - this.y0) / h - t) / 2 : t; },
          hermite(t0, t1) {
            const dx = (this.x1 - this.x0) / 3;
            ctx.bezierCurveTo(this.x0 + dx, this.y0 + dx * t0, this.x1 - dx, this.y1 - dx * t1, this.x1, this.y1);
          },
          lineEnd() {
            if (this.count === 2) ctx.lineTo(this.x1, this.y1);
            else if (this.count === 3) this.hermite(this.t0, this.slope2(this.t0));
            if (this.line || (this.line !== 0 && this.count === 1)) ctx.closePath();
            this.line = 1 - this.line;
          },
          point(x, y) {
            let t1 = NaN;
            if (x === this.x1 && y === this.y1) return;
            if (this.count === 0) { this.count = 1; this.line ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
            else if (this.count === 1) this.count = 2;
            else if (this.count === 2) { this.count = 3; t1 = this.slope3(x, y); this.hermite(this.slope2(t1), t1); }
            else { t1 = this.slope3(x, y); this.hermite(this.t0, t1); }
            this.x0 = this.x1; this.x1 = x; this.y0 = this.y1; this.y1 = y; this.t0 = t1;
          }
        }),
        step: ctx => ({
          t: 0.5,
          areaStart() { this.line = 0; }, areaEnd() { this.line = NaN; },
          lineStart() { this.x = this.y = NaN; this.count = 0; },
          lineEnd() {
            if (0 < this.t && this.t < 1 && this.count === 2) ctx.lineTo(this.x, this.y);
            if (this.line || (this.line !== 0 && this.count === 1)) ctx.closePath();
            if (this.line >= 0) { this.t = 1 - this.t; this.line = 1 - this.line; }
          },
          point(x, y) {
            if (this.count === 0) { this.count = 1; this.line ? ctx.lineTo(x, y) : ctx.moveTo(x, y); }
            else {
              this.count = 2;
              const x1 = this.x * (1 - this.t) + x * this.t;
              ctx.lineTo(x1, this.y);
              ctx.lineTo(x1, y);
            }
            this.x = x; this.y = y;
          }
        })
      };
      // d3 line()/area() over one defined segment; area bases are drawn reversed.
      const curvePath = (name, top, base) => {
        const ctx = pathContext(), curve = (curves[name] || curves.linear)(ctx);
        if (base) curve.areaStart();
        curve.lineStart();
        for (const p of top) curve.point(p[0], p[1]);
        curve.lineEnd();
        if (base) {
          curve.lineStart();
          for (let k = base.length - 1; k >= 0; k--) curve.point(base[k][0], base[k][1]);
          curve.lineEnd();
          curve.areaEnd();
        }
        return ctx.toString();
      };
      export default {
        mounted() {
          this.container = this.el.closest(".recharts-responsive-container");
          this.listeners = [];
          this.resize = () => this.draw();
          this.observer = new ResizeObserver(this.resize);
          this.observer.observe(this.container);
          this.draw();
          // Tick thinning measures label text; remeasure once late web fonts have loaded.
          if (document.fonts && document.fonts.status !== "loaded")
            document.fonts.ready.then(() => { if (this.el.isConnected) this.draw(); });
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
          const tickLabel = index => options.ticks ? options.ticks[index] : label(index);
          // Recharts stackId with stackOffset "none": each series sits on the running total
          // of earlier series in its stack (missing samples add 0). Lines are never stacked.
          const stacked = series.map(() => null), totals = new Map();
          if (options.kind !== "line") series.forEach((item, seriesIndex) => {
            if (item.stack == null) return;
            const running = totals.get(item.stack) || data.map(() => 0);
            const lower = running.slice();
            const upper = data.map((row, index) => { const value = number(row, item.key); return value === null ? null : lower[index] + value; });
            upper.forEach((value, index) => { if (value !== null) running[index] = value; });
            totals.set(item.stack, running);
            stacked[seriesIndex] = {lower, upper};
          });
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
          const values = data.flatMap((row, index) => series.flatMap((item, seriesIndex) => stacked[seriesIndex]
            ? [stacked[seriesIndex].lower[index], stacked[seriesIndex].upper[index]] : [number(row, item.key)])).filter(value => value !== null);
          let yTicks = [0, 1, 2, 3, 4];
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
            yTicks = Array.from({length: 5}, (_, index) => minimum + index * step);
          }
          const y = value => bottom - (value - minimum) / (maximum - minimum) * plotHeight;
          const step = data.length ? plotWidth / data.length : 0;
          const x = index => options.kind === "bar" || data.length === 1
            ? left + step * (index + 0.5) : left + plotWidth * index / (data.length - 1);
          const zero = y(0);
          const cursor = svgNode("g", {"pointer-events": "none"});
          const geometry = svgNode("g", {class: "recharts-layer"});
          const grid = options.grid && options.grid !== "none" ? svgNode("g", {class: "recharts-cartesian-grid"}) : null;
          const gridLines = (className, points, line) => {
            const lines = svgNode("g", {class: className});
            for (const point of points) lines.append(svgNode("line", {stroke: "#ccc", fill: "none", ...line(point)}));
            grid.append(lines);
          };
          // CartesianGrid lines sit at axis tick coordinates plus the plot edges when missing.
          const gridPoints = (points, start, end) => [...points, ...(points.includes(start) ? [] : [start]), ...(points.includes(end) ? [] : [end])];
          if (grid && options.grid !== "vertical")
            gridLines("recharts-cartesian-grid-horizontal", gridPoints(yTicks.map(y), bottom, top), point => ({x1: left, y1: point, x2: right, y2: point}));
          if (grid) svg.append(grid);
          svg.append(cursor, geometry);
          const fills = series.map((item, seriesIndex) => {
            if (options.fill !== "gradient") return item.color;
            const id = this.el.id + "-fill-" + seriesIndex;
            const [from, to] = item.gradientOpacity || options.gradientOpacity || [0.8, 0.1];
            const gradient = svgNode("linearGradient", {id, x1: 0, y1: 0, x2: 0, y2: 1});
            gradient.append(svgNode("stop", {offset: "5%", "stop-color": item.color, "stop-opacity": from}),
              svgNode("stop", {offset: "95%", "stop-color": item.color, "stop-opacity": to}));
            let defs = svg.querySelector("defs");
            if (!defs) { defs = svgNode("defs"); svg.prepend(defs); }
            defs.append(gradient);
            return "url(#" + id + ")";
          });
          const animations = [], nextBars = new Map();
          const signature = JSON.stringify([options.data, options.series, options.kind, width, height]);
          const animate = signature !== this.signature && !matchMedia("(prefers-reduced-motion: reduce)").matches;
          this.signature = signature;
          const round = value => Number(value.toFixed(4));
          // Bars sharing a stack ID share one category slot, like Recharts stack groups.
          const barGroups = [...new Set(series.map((item, seriesIndex) => stacked[seriesIndex] ? "stack:" + item.stack : "series:" + seriesIndex))];
          series.forEach((item, seriesIndex) => {
            const group = svgNode("g", {class: "recharts-layer recharts-" + options.kind});
            geometry.append(group);
            const stack = stacked[seriesIndex];
            if (options.kind === "bar") {
              const slots = barGroups.length;
              const slot = barGroups.indexOf(stack ? "stack:" + item.stack : "series:" + seriesIndex);
              let gap = 4;
              if (step * 0.8 - (slots - 1) * gap <= 0) gap = 0;
              let barWidth = (step * 0.8 - (slots - 1) * gap) / slots;
              if (barWidth > 1) barWidth = Math.floor(barWidth);
              const rectangles = svgNode("g", {class: "recharts-bar-rectangles"});
              group.append(rectangles);
              data.forEach((row, index) => {
                const value = number(row, item.key);
                if (value === null || value === 0 || barWidth <= 0) return;
                const base = stack ? y(stack.lower[index]) : zero, end = stack ? y(stack.upper[index]) : y(value);
                const current = {x: left + index * step + step * 0.1 + slot * (barWidth + gap),
                  y: end, width: barWidth, height: base - end};
                const key = item.key + ":" + index;
                nextBars.set(key, current);
                const rect = svgNode("path", {fill: fills[seriesIndex], radius: 0, class: "recharts-rectangle"});
                const render = shape => {
                  for (const name of ["x", "y", "width", "height"]) rect.setAttribute(name, round(shape[name]));
                  rect.setAttribute("d", "M " + round(shape.x) + "," + round(shape.y) + " h " + round(shape.width) + " v " + round(shape.height) + " h " + round(-shape.width) + " Z");
                };
                rectangles.append(rect);
                render(current);
                if (animate) {
                  const previous = this.bars?.get(key) || {...current, y: base, height: 0};
                  animations.push(t => render(Object.fromEntries(Object.keys(current).map(name => [name, previous[name] + (current[name] - previous[name]) * t]))));
                }
              });
            } else {
              const segments = [], bases = [];
              let segment = [], base = [];
              for (let index = 0; index < data.length; index++) {
                const value = stack ? stack.upper[index] : number(data[index], item.key);
                if (value === null) { if (segment.length) { segments.push(segment); bases.push(base); } segment = []; base = []; }
                else { segment.push([x(index), y(value)]); base.push([x(index), stack ? y(stack.lower[index]) : zero]); }
              }
              if (segment.length) { segments.push(segment); bases.push(base); }
              // Default linear unstacked paths keep their established compact form; other
              // curves and stacked baselines use the d3 line/area generators like Recharts.
              const shaped = stack || (options.curve && options.curve !== "linear");
              const point = p => Number(p[0].toFixed(3)) + "," + Number(p[1].toFixed(3));
              const curve = shaped ? segments.map(points => curvePath(options.curve, points)).join("")
                : segments.map(points => "M" + points.map(point).join("L") + (points.length === 1 ? "Z" : "")).join("");
              if (options.kind === "area") {
                const area = svgNode("path", {d: shaped ? segments.map((points, index) => curvePath(options.curve, points, bases[index])).join("")
                  : segments.map(points => "M" + points.map(point).join("L") + "L" + point([points[points.length - 1][0], zero]) + "L" + point([points[0][0], zero]) + "Z").join(""),
                  fill: fills[seriesIndex], "fill-opacity": item.fillOpacity ?? options.fillOpacity ?? 0.6, stroke: "none", class: "recharts-curve recharts-area-area"});
                group.append(area);
                if (animate && segments.length) {
                  const clipId = this.el.id + "-area-animation-" + seriesIndex;
                  const clip = svgNode("clipPath", {id: clipId});
                  const clipRect = svgNode("rect", {x: left, y: 0, width: 0, height: Math.floor(Math.max(zero, ...segments.flat().map(p => p[1]), ...bases.flat().map(p => p[1])) + 1)});
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
          const verticalGrid = grid && (options.grid === "vertical" || options.grid === "both");
          if ((options.axes || verticalGrid) && data.length) {
            // Default XAxis interval="preserveEnd" measures text, shifts the final tick,
            // and rejects labels that would overlap (minTickGap) or leave the axis viewport.
            const measure = htmlNode("span", "");
            Object.assign(measure.style, {position: "absolute", whiteSpace: "pre", visibility: "hidden", fontSize: getComputedStyle(this.container).fontSize, letterSpacing: getComputedStyle(this.container).letterSpacing});
            document.body.append(measure);
            let end = width;
            const ticks = [];
            for (let index = data.length - 1; index >= 0; index--) {
              measure.textContent = String(tickLabel(index));
              const size = measure.getBoundingClientRect().width;
              const coordinate = x(index);
              const tickCoordinate = index === data.length - 1 ? Math.min(coordinate, width - size / 2) : coordinate;
              if (tickCoordinate - size / 2 < 0 || tickCoordinate + size / 2 > end) continue;
              end = tickCoordinate - size / 2 - (options.minTickGap ?? 5);
              ticks.unshift({index, coordinate, tickCoordinate});
            }
            measure.remove();
            if (verticalGrid)
              gridLines("recharts-cartesian-grid-vertical", gridPoints(ticks.map(tick => tick.coordinate), left, right), point => ({x1: point, y1: top, x2: point, y2: bottom}));
            if (options.axes) {
              const axis = svgNode("g", {class: "recharts-layer recharts-cartesian-axis recharts-xAxis xAxis"});
              if (options.axisLine !== false)
                axis.append(svgNode("line", {x1: left, x2: right, y1: bottom, y2: bottom, stroke: "#666", fill: "none", class: "recharts-cartesian-axis-line"}));
              svg.append(axis);
              // Recharts places labels tickSize (6) + tickMargin below the axis even without tick lines.
              const textY = bottom + 6 + (options.tickMargin ?? 2);
              for (const tick of ticks) {
                const layer = svgNode("g", {class: "recharts-layer recharts-cartesian-axis-tick"});
                if (options.tickLine !== false)
                  layer.append(svgNode("line", {x1: tick.coordinate, x2: tick.coordinate, y1: bottom + 6, y2: bottom, stroke: "#666", class: "recharts-cartesian-axis-tick-line"}));
                const text = svgNode("text", {x: tick.tickCoordinate, y: textY, "text-anchor": "middle", fill: "#666", class: "recharts-text recharts-cartesian-axis-tick-value"});
                text.append(svgNode("tspan", {x: tick.tickCoordinate, dy: "0.71em"}, tickLabel(tick.index)));
                layer.append(text);
                axis.append(layer);
              }
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
            if (options.cursor !== false) {
              if (options.kind === "bar") cursor.append(svgNode("rect", {x: left + index * step, y: top + 0.5, width: step, height: Math.max(0, plotHeight - 1), fill: "#ccc", stroke: "none", class: "recharts-rectangle recharts-tooltip-cursor"}));
              else cursor.append(svgNode("path", {d: "M" + x(index) + "," + top + "L" + x(index) + "," + bottom, fill: "none", stroke: "#ccc", class: "recharts-curve recharts-tooltip-cursor"}));
            }
            const content = htmlNode("div", "grid min-w-32 items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl");
            content.append(htmlNode("div", "font-medium", options.tooltipLabels ? options.tooltipLabels[index] : label(index)));
            const entries = htmlNode("div", "grid gap-1.5");
            series.forEach((item, seriesIndex) => {
              const value = number(data[index], item.key);
              if (value === null) return;
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
              const dotY = y(stacked[seriesIndex] ? stacked[seriesIndex].upper[index] : value);
              if (options.kind !== "bar") activeDots.append(svgNode("circle", {cx: x(index), cy: dotY, r: 4, fill: item.color, stroke: "#fff", "stroke-width": 2, class: "recharts-dot"}));
            });
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
