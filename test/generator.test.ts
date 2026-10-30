import test from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { parseComponentAST } from "../tools/generate"
import { sheetOverlayClasses } from "../tools/converters/layout-hooks"

test("style metadata without a component declaration fails explicitly instead of fabricating a component", () => {
  const source = `
    import { cva } from "class-variance-authority"
    export const buttonVariants = cva("inline-flex", {
      variants: { variant: { default: "bg-primary" } },
      defaultVariants: { variant: "default" },
    })
  `
  assert.throws(() => parseComponentAST("button", source), error =>
    error instanceof Error && !(error instanceof ReferenceError),
  )
})

test("the mobile sidebar backdrop reuses the upstream Sheet overlay classes", () => {
  const sheet = readFileSync("vendor/shadcn/ui/sheet.tsx", "utf8")
  assert.ok(sheet.includes(`"${sheetOverlayClasses}"`), "sheet overlay classes drifted from vendor/shadcn/ui/sheet.tsx")
})
