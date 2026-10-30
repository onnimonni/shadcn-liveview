import test from "node:test"
import assert from "node:assert/strict"
import fs from "node:fs/promises"
import { buildComponentIndex, componentIndexPath } from "../tools/generator/component-index"

test("usage-rules/components.md matches the generated component modules", async () => {
  const committed = await fs.readFile(componentIndexPath, "utf8")
  assert.equal(committed, await buildComponentIndex(), `${componentIndexPath} is stale; run \`bun run generate\``)
})
