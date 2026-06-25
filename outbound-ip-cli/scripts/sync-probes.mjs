#!/usr/bin/env node
/**
 * 从 audit-core.js 导出 PROBES → probes.packaged.json
 * 用法（在 outbound-ip-cli 目录）: node scripts/sync-probes.mjs
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const coreJs = join(root, "src", "outbound_ip", "web", "static", "audit-core.js");
const outJson = join(root, "src", "outbound_ip", "data", "probes.packaged.json");

const src = readFileSync(coreJs, "utf8");
const m = src.match(/var PROBES = (\[[\s\S]*?\]);/);
if (!m) {
  console.error("未在 audit-core.js 中找到 PROBES 数组");
  process.exit(1);
}
const probes = eval(m[1]);
writeFileSync(outJson, JSON.stringify({ probes }, null, 2) + "\n", "utf8");
console.log("wrote", outJson, `(${probes.length} probes)`);
