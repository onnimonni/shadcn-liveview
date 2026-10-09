import fs from "node:fs/promises"
import crypto from "node:crypto"

const sha256 = content => crypto.createHash("sha256").update(content).digest("hex")
const lock = JSON.parse(await fs.readFile("vendor/shadcn/registry.lock.json", "utf8"))
const check = (actual, expected, label) => { if (actual !== expected) throw new Error(`Upstream integrity mismatch: ${label}`) }
const remote = process.argv.includes("--remote")
check(sha256(await fs.readFile("vendor/shadcn/registry/registry.json")), lock.registrySha256, lock.registry)
let files = 0
for (const entry of [...lock.components, ...lock.templates, ...lock.support]) {
  const payload = await fs.readFile(entry.payloadPath)
  check(sha256(payload), entry.payloadSha256, entry.url)
  const item = JSON.parse(payload)
  if (remote) {
    const response = await fetch(entry.url)
    if (!response.ok) throw new Error(`${entry.url}: ${response.status}`)
    check(sha256(await response.text()), entry.payloadSha256, `live response ${entry.url}`)
  }
  check(item.name, entry.name, entry.url)
  for (const file of entry.files) {
    const source = item.files.find(candidate => candidate.path === file.registryPath)?.content
    if (source === undefined) throw new Error(`Missing original source: ${file.registryPath}`)
    check(sha256(source), file.sourceSha256, file.registryPath)
    check(await fs.readFile(file.upstreamPath, "utf8"), source, file.upstreamPath)
    check(await fs.readFile(file.path, "utf8"), source.replaceAll("@/components/ui/", "@/ui/"), file.path)
    check(sha256(await fs.readFile(file.path)), file.sha256, file.path)
    files++
  }
}
console.log(`Verified ${files} source files against exact saved registry responses: ${lock.components.length} UI entries, ${lock.templates.length} official templates, ${lock.support.length} support entries. Fetched ${lock.fetchedAt}.`)
