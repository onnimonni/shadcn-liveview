import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs/promises"
import path from "node:path"
import { parseComponentAST, generateElixirModule } from "../tools/generate"
import { fixtures } from "../tools/fixtures"

test("fixtures registry contains all 61 components", () => {
  assert.equal(fixtures.length, 61)
})

test("parseComponentAST extracts Button component with CVA variants", async () => {
  const code = await fs.readFile("vendor/shadcn/ui/button.tsx", "utf8")
  const spec = parseComponentAST("button", code)

  assert.equal(spec.name, "button")
  assert.equal(spec.moduleName, "Button")
  assert.ok(spec.functions.length >= 1)

  const btnFn = spec.functions.find((f) => f.name === "button")
  assert.ok(btnFn, "button function should exist")
  assert.equal(btnFn.tag, "button")
  assert.equal(btnFn.slotName, "button")
  assert.ok(btnFn.variants?.variant, "variant options should exist")
  assert.ok(btnFn.variants?.size, "size options should exist")
})

test("generateElixirModule creates valid Phoenix Component module", async () => {
  const code = await fs.readFile("vendor/shadcn/ui/button.tsx", "utf8")
  const spec = parseComponentAST("button", code)
  const elixir = generateElixirModule(spec)

  assert.match(elixir, /defmodule ShadcnLiveview\.Components\.Button do/)
  assert.match(elixir, /use Phoenix\.Component/)
  assert.match(elixir, /def button\(assigns\) do/)
  assert.match(elixir, /data-slot="button"/)
})

test("all 61 LiveView component files exist in lib/shadcn_liveview/components", async () => {
  const files = await fs.readdir("lib/shadcn_liveview/components")
  const exFiles = files.filter((f) => f.endsWith(".ex"))
  // 61 components + icon.ex + helpers.ex (or icon.ex in components)
  assert.ok(exFiles.length >= 61)
})
