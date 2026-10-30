import assert from "node:assert/strict";
import { readdir, readFile } from "node:fs/promises";

const root = new URL("../", import.meta.url);
const css = await readFile(new URL("priv/static/shadcn.css", root), "utf8");
const js = await readFile(new URL("priv/static/shadcn-hooks.js", root), "utf8");

assert.ok(css.length > 0, "Packaged CSS must not be empty");
assert.doesNotMatch(css, /@import\s/i, "Packaged CSS must resolve all imports");
for (const match of css.matchAll(/url\(\s*(['"]?)(.*?)\1\s*\)/gi)) {
  assert.match(match[2], /^(?:data:|#)/, `Nonportable CSS URL: ${match[2]}`);
}
assert.doesNotMatch(
  js,
  /\b(?:import\s*[({*"']|from\s*["'])/,
  "Packaged hooks must bundle their dependencies",
);
assert.doesNotMatch(
  js,
  /react[-.]?(?:dom|production|development)|Symbol\.for\(["']react\./i,
  "Packaged hooks must not contain a React runtime",
);
assert.doesNotMatch(js, /class LiveSocket\b|class Socket\b/, "Consumer owns Phoenix's client");

const expected = [];
const components = new URL("lib/shadcn_liveview/components/", root);
for (const file of await readdir(components)) {
  if (!file.endsWith(".ex")) continue;
  const source = await readFile(new URL(file, components), "utf8");
  const module = source.match(/^defmodule\s+([\w.]+)\s+do/m)[1];
  for (const match of source.matchAll(
    /<script\s+:type=\{Phoenix\.LiveView\.ColocatedHook\}\s+name="([^"]+)"/g,
  )) {
    expected.push(match[1].startsWith(".") ? module + match[1] : match[1]);
  }
}
assert.ok(expected.length > 0, "Native source must declare colocated hooks");
const { hooks } = await import(new URL("priv/static/shadcn-hooks.js", root));
assert.deepEqual(Object.keys(hooks).sort(), expected.sort(), "Ship every colocated hook registration");
for (const [name, hook] of Object.entries(hooks)) {
  assert.equal(typeof hook.mounted, "function", `${name} must provide its mount lifecycle`);
}
console.log(`Packaged assets: ${expected.length} complete hooks; self-contained CSS and JavaScript.`);
