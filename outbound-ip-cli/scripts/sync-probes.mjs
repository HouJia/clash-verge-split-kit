#!/usr/bin/env node
/**
 * 从 audit-core.js 导出 PROBES 为 probes.packaged.json，供 Python load_default() 校验。
 * 用法（在 hjs-egress-ip-cli 目录）: node scripts/sync-probes.mjs
 */
import { readFileSync, writeFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const coreJs = join(root, "src", "hjs_egress_ip", "web", "static", "audit-core.js");
const outJson = join(root, "src", "hjs_egress_ip", "data", "probes.packaged.json");

/** audit-core.js 为普通脚本（非 ES 模块），在 Node 中用 Function 执行并读回 globalThis。 */
const code = readFileSync(coreJs, "utf8");
const hadCore = Object.prototype.hasOwnProperty.call(globalThis, "HjsEgressAuditCore");
const prevCore = globalThis.HjsEgressAuditCore;
let probes;
try {
  new Function(code)();
  const mod = globalThis.HjsEgressAuditCore;
  if (!mod || !Array.isArray(mod.PROBES)) {
    console.error("sync-probes: 未得到 HjsEgressAuditCore.PROBES");
    process.exit(1);
  }
  probes = mod.PROBES;
} finally {
  if (hadCore) globalThis.HjsEgressAuditCore = prevCore;
  else delete globalThis.HjsEgressAuditCore;
}
if (!Array.isArray(probes) || !probes.length) {
  console.error("sync-probes: PROBES 为空或非法");
  process.exit(1);
}
for (const [i, p] of probes.entries()) {
  for (const k of ["category", "name", "url", "parser"]) {
    if (!(k in p)) {
      console.error(`sync-probes: probes[${i}] 缺少字段 ${k}`);
      process.exit(1);
    }
  }
}
writeFileSync(outJson, JSON.stringify({ probes }, null, 2) + "\n");
console.log("已写入:", outJson);
