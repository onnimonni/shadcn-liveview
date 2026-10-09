import fs from "node:fs/promises"
import path from "node:path"
import crypto from "node:crypto"

const base = "https://ui.shadcn.com/r/styles/radix-nova/"
const sha256 = content => crypto.createHash("sha256").update(content).digest("hex")
const get = async url => {
  const response = await fetch(url)
  if (!response.ok) throw new Error(`${url}: ${response.status}`)
  return response.text()
}
const registryContent = await get(base + "registry.json")
const registry = JSON.parse(registryContent)
const types = new Set(["registry:ui", "registry:example", "registry:block", "registry:component", "registry:lib", "registry:hook"])
const items = registry.items.filter(item => types.has(item.type))
const lock = {
  style: "radix-nova", registry: base + "registry.json", fetchedAt: new Date().toISOString(),
  registrySha256: sha256(registryContent), components: [], templates: [], support: [],
}
await fs.mkdir("vendor/shadcn/registry", { recursive: true })
await fs.writeFile("vendor/shadcn/registry/registry.json", registryContent)
for (let index = 0; index < items.length; index += 8) {
  const entries = await Promise.all(items.slice(index, index + 8).map(async item => {
    const url = base + item.name + ".json"
    const payload = await get(url)
    const data = JSON.parse(payload)
    const payloadPath = `vendor/shadcn/registry/${item.name}.json`
    await fs.writeFile(payloadPath, payload)
    const files = []
    for (const file of data.files ?? []) {
      const relative = file.path.replace(/^registry\/radix-nova\//, "")
      if (relative === file.path || relative.split("/").includes("..") || path.isAbsolute(relative)) {
        throw new Error(`Unexpected registry path: ${file.path}`)
      }
      const localPath = `vendor/shadcn/${relative}`
      const upstreamPath = `vendor/shadcn/upstream/${file.path}`
      await fs.mkdir(path.dirname(localPath), { recursive: true })
      await fs.mkdir(path.dirname(upstreamPath), { recursive: true })
      // Raw source is byte-for-byte registry content; runnable copies resolve only aliases.
      await fs.writeFile(upstreamPath, file.content)
      const content = file.content.replaceAll("@/components/ui/", "@/ui/")
      await fs.writeFile(localPath, content)
      files.push({ path: localPath, upstreamPath, registryPath: file.path, sourceSha256: sha256(file.content), sha256: sha256(content) })
    }
    return { name: item.name, type: item.type, url, payloadPath, payloadSha256: sha256(payload), dependencies: data.dependencies ?? [], registryDependencies: data.registryDependencies ?? [], files }
  }))
  for (const entry of entries) {
    const target = entry.type === "registry:ui" ? lock.components : ["registry:example", "registry:block"].includes(entry.type) ? lock.templates : lock.support
    target.push(entry)
  }
}
await fs.writeFile("vendor/shadcn/registry.lock.json", JSON.stringify(lock, null, 2) + "\n")
console.log(`Fetched ${lock.components.length} UI registry entries (${lock.components.filter(item => item.files.length).length} with source), ${lock.templates.length} official examples/blocks, ${lock.support.length} support entries.`)
