import fs from 'node:fs/promises';
import crypto from 'node:crypto';
const base = 'https://ui.shadcn.com/r/styles/radix-nova/';
const get = async url => { const r = await fetch(url); if (!r.ok) throw Error(`${url}: ${r.status}`); return r.json(); };
const registry = await get(base + 'registry.json');
const items = registry.items.filter(i => i.type === 'registry:ui');
const lock = { style: 'radix-nova', registry: base + 'registry.json', fetchedAt: new Date().toISOString(), components: [] };
await fs.mkdir('vendor/shadcn/ui', {recursive:true});
// Bounded batches avoid overwhelming the registry.
for (let i=0; i<items.length; i+=8) {
  const entries = await Promise.all(items.slice(i,i+8).map(async item => {
    const data = await get(base + item.name + '.json');
    const files = [];
    for (const file of data.files ?? []) {
      const path = 'vendor/shadcn/' + file.path.replace(/^.*?\/(ui|hooks|lib)\//,'$1/');
      await fs.mkdir(path.slice(0,path.lastIndexOf('/')), {recursive:true});
      // Only resolve project aliases; component markup is otherwise unchanged.
      const content = file.content.replaceAll('@/components/ui/', '@/ui/');
      await fs.writeFile(path,content);
      files.push({path,sha256:crypto.createHash('sha256').update(content).digest('hex')});
    }
    return {name:item.name,url:base+item.name+'.json',dependencies:data.dependencies ?? [],files};
  }));
  lock.components.push(...entries);
}
await fs.mkdir('vendor/shadcn/lib',{recursive:true});
await fs.writeFile('vendor/shadcn/lib/utils.ts','export { cn } from "cn"\n');
await fs.writeFile('vendor/shadcn/registry.lock.json',JSON.stringify(lock,null,2)+'\n');
console.log(`Pinned ${items.length} component families.`);
