/**
 * 探测表与摘要解析逻辑的单一数据源（静态页与 probes.packaged.json 均由此导出）。
 * 以普通脚本挂载到 globalThis，避免 file:// 下 ES 模块子资源被浏览器拦截导致整页无交互。
 * 修改探测点后请在本包根目录执行: node scripts/sync-probes.mjs
 */
(function (g) {
  "use strict";

  var GROUP_ORDER = ["domestic", "intl_plain", "cdn_trace", "meta"];

  var GROUP_LABELS = {
    domestic: "国内 / 中文语境站点",
    intl_plain: "国际通用回显",
    cdn_trace: "CDN 侧观测",
    meta: "接口元数据（JSON）",
  };

  /** 表格「类别」列展示（中文）。*/
  var CATEGORY_UI_LABEL = {
    domestic: "国内",
    intl_plain: "国际通用",
    cdn_trace: "CDN 观测",
    meta: "元数据接口",
  };

  function formatUiCategory(cat) {
    var k = String(cat || "").trim();
    return CATEGORY_UI_LABEL[k] || k;
  }

  /** @type {{ category: string, name: string, url: string, parser: string }[]} */
  var PROBES = [
    { category: "domestic", name: "ipip.net", url: "https://myip.ipip.net", parser: "plain" },
    { category: "domestic", name: "cip.cc", url: "https://cip.cc", parser: "cip_cc_ip", noBrowserCors: true },
    { category: "intl_plain", name: "ipecho.net", url: "https://ipecho.net/plain", parser: "plain" },
    { category: "intl_plain", name: "ipify", url: "https://api.ipify.org", parser: "plain" },
    { category: "intl_plain", name: "ipify_v6_hint", url: "https://api64.ipify.org", parser: "plain" },
    { category: "intl_plain", name: "icanhazip", url: "https://icanhazip.com", parser: "plain" },
    { category: "intl_plain", name: "ifconfig.me", url: "https://ifconfig.me/ip", parser: "plain" },
    { category: "intl_plain", name: "ipinfo.io", url: "https://ipinfo.io/ip", parser: "plain" },
    { category: "intl_plain", name: "aws_checkip", url: "https://checkip.amazonaws.com", parser: "plain" },
    { category: "intl_plain", name: "ident.me", url: "https://ident.me", parser: "plain" },
    { category: "cdn_trace", name: "cloudflare_trace", url: "https://1.1.1.1/cdn-cgi/trace", parser: "cloudflare_trace", noBrowserCors: true },
    { category: "meta", name: "httpbin_ip", url: "https://httpbin.org/ip", parser: "httpbin_ip" },
  ];

  /**
   * 与 egress-ip-audit.sh 中各 parser 分支对齐的摘要提取。
   * @param {string} parser
   * @param {string} text
   */
  function snippetFromBody(parser, text) {
    var body = text ?? "";
    switch (parser) {
      case "plain": {
        var flat = body.replace(/\r/g, " ").replace(/\n/g, " ").replace(/^\s+|\s+$/g, "");
        return flat.slice(0, 160);
      }
      case "cip_cc_ip": {
        var raw = String(body ?? "");
        var block = raw.replace(/\r\n/g, "\n");
        var ipM = block.match(/^\s*IP\s*:\s*([0-9a-fA-F:.]+)\s*$/im);
        if (!ipM) ipM = block.match(/\bIP\s*:\s*([0-9a-fA-F:.]+)/i);
        var ip = ipM ? ipM[1].trim() : "";
        var addrM = block.match(/(?:^|\n)\s*地址\s*[:：]\s*([^\n]+)/im);
        var opM = block.match(/(?:^|\n)\s*运营商\s*[:：]\s*([^\n]+)/im);
        var addr = addrM ? addrM[1].replace(/\s+$/g, "").trim() : "";
        var op = opM ? opM[1].replace(/\s+$/g, "").trim() : "";
        if (ip && (addr || op)) {
          var loc = [addr, op].filter(Boolean).join(" ");
          return ("当前 IP: " + ip + " 来自于：" + loc).slice(0, 280);
        }
        if (ip) return ip;
        var line = block.replace(/\n/g, " ").replace(/^\s+|\s+$/g, "");
        return line.slice(0, 160);
      }
      case "httpbin_ip": {
        var s = body.trim();
        if (!s) return "";
        try {
          var d = JSON.parse(s);
          return String(d.origin ?? "").slice(0, 160);
        } catch (_) {
          return "";
        }
      }
      case "cloudflare_trace": {
        var lines = body.split(/\r?\n/);
        var hit = lines.find(function (l) {
          return l.startsWith("ip=");
        });
        return (hit || "").trim().slice(0, 160);
      }
      default: {
        var df = body.replace(/\r/g, " ").replace(/\n/g, " ").trim();
        return df.slice(0, 160);
      }
    }
  }

  function rowFromResult(probe, scenario, httpCode, snippet) {
    var esc = snippet.replace(/\t/g, " ");
    return {
      scenario: scenario,
      category: probe.category,
      probe_name: probe.name,
      url: probe.url,
      http_code: httpCode,
      snippet: esc,
    };
  }

  /** 摘要是否已有「来自于」且含中文字符（避免英文地名占位导致跳过 /__geo / ipip 对齐）。 */
  function hasZhGeoTail(snippet) {
    var s = String(snippet || "");
    if (s.indexOf("来自于") < 0) return false;
    return /[\u4e00-\u9fff]/.test(s);
  }

  /** 单次探测超时（毫秒）；默认 fetch 会一直挂起，任一站点卡住会导致整页长期停在「检测中」。*/
  var PROBE_FETCH_MS = 20000;

  /** 与浏览器访问一致，降低 cip 等站返回英文简版的概率；代取端也会带同名头。 */
  var PROBE_ACCEPT_LANG = "zh-CN,zh;q=0.9,en;q=0.7";

  function fetchWithDeadline(url, init) {
    init = init || {};
    if (typeof AbortController === "undefined") {
      return fetch(url, init);
    }
    var ac = new AbortController();
    var tid = setTimeout(function () {
      ac.abort();
    }, PROBE_FETCH_MS);
    var merged = Object.assign({}, init, { signal: ac.signal });
    return fetch(url, merged).finally(function () {
      clearTimeout(tid);
    });
  }

  function sameOriginRelayBase() {
    if (typeof location === "undefined") return "";
    var p = location.protocol;
    if (p !== "http:" && p !== "https:") return "";
    return location.origin;
  }

  /**
   * 同源宿主（hjs-egress-ip serve）上的代取入口，跳过目标站缺失的 Access-Control-Allow-Origin。
   * @param {string} base location.origin，须为 http(s)
   */
  function fetchViaRelay(base, probe, scenario) {
    var relayUrl = base + "/__probe?url=" + encodeURIComponent(probe.url);
    return fetchWithDeadline(relayUrl, {
      method: "GET",
      cache: "no-store",
      credentials: "omit",
      headers: { "Accept-Language": PROBE_ACCEPT_LANG },
    }).then(function (res) {
      return res.text().then(function (text) {
        var snippet = snippetFromBody(probe.parser, text);
        snippet = snippet.replace(/\t/g, " ");
        return rowFromResult(probe, scenario, String(res.status), snippet);
      });
    });
  }

  /**
   * @param {{ category: string, name: string, url: string, parser: string, noBrowserCors?: boolean }} probe
   * @param {string} scenario
   */
  function fetchOneProbe(probe, scenario) {
    var base = sameOriginRelayBase();

    /** 无 CORS/或 file→IP 等资源在脚本 fetch 常失败：无同源宿主时无法 /__probe，不必白等直连超时。 */
    if (probe.noBrowserCors && !base) {
      return Promise.resolve(
        rowFromResult(
          probe,
          scenario,
          "000",
          "file 打开无法脚本读取；请 hjs-egress-ip serve 后打开本页，或地址栏直接访问本条 URL"
        )
      );
    }

    function direct() {
      return fetchWithDeadline(probe.url, {
        method: "GET",
        cache: "no-store",
        mode: "cors",
        credentials: "omit",
        headers: { "Accept-Language": PROBE_ACCEPT_LANG },
      }).then(function (res) {
        return res.text().then(function (text) {
          var snippet = snippetFromBody(probe.parser, text);
          snippet = snippet.replace(/\t/g, " ");
          return rowFromResult(probe, scenario, String(res.status), snippet);
        });
      });
    }

    function relayOrThrow(err) {
      if (!base) throw err;
      return fetchViaRelay(base, probe, scenario);
    }

    function localizeErrSnippet(msg) {
      var s = String(msg || "").trim();
      if (!s.length) return s;
      if (/NetworkError|Failed to fetch|fetch resource|The operation was insecure|blocked by CORS|CORS|NS_ERROR_DOM/i.test(s)) {
        return "请求失败（网络异常、跨域限制或浏览器拦截）";
      }
      if (/Load failed|The network connection was lost|ENOTFOUND|EAI_AGAIN|timeout/i.test(s)) {
        return "请求失败（网络不可用或超时）";
      }
      return s.slice(0, 160);
    }

    function failRow(e) {
      if (e && e.name === "AbortError") {
        return rowFromResult(
          probe,
          scenario,
          "000",
          "超时（前端单站 " + String(PROBE_FETCH_MS / 1000) + "s）"
        );
      }
      var msg = e instanceof Error ? e.message : String(e);
      return rowFromResult(probe, scenario, "000", localizeErrSnippet(msg));
    }

    if (base && probe.noBrowserCors) {
      return fetchViaRelay(base, probe, scenario).catch(failRow);
    }

    return direct().catch(relayOrThrow).catch(failRow);
  }

  /**
   * 解析 ipip 典型一行：当前 IP: x.x.x.x 来自于：中国 …
   * @returns {{ ipKey: string, full: string } | null}
   */
  function parseIpipRef(snippet) {
    var s = String(snippet || "").trim();
    if (!s || s.indexOf("来自于") < 0) return null;
    var m = s.match(/当前\s*IP\s*:\s*(\S+)/i);
    if (!m) return null;
    return {
      ipKey: normalizeIpPaletteKey(m[1].trim()),
      full: s,
    };
  }

  /**
   * 从摘要中提取用于匹配归属地的 IP（与 findIpSpansInText 逻辑对齐，并处理 trace 的 ip= 行）。
   * @param {{ snippet: string, probe_name: string }} row
   * @returns {string | null}
   */
  function extractPrimaryIpFromRow(row) {
    var s = String(row.snippet || "");
    if (row.probe_name === "cloudflare_trace") {
      var tm = s.match(/ip=([0-9a-fA-F:.]+)/i);
      return tm ? tm[1].trim() : null;
    }
    var spans = findIpSpansInText(s);
    return spans.length ? spans[0].raw : null;
  }

  /**
   * 从已 finalize 的行中推导顶栏每条出口 IP 的展示文案：优先带中文「来自于」的摘要。
   * @param {ReturnType<rowFromResult>[]} rows
   * @param {Map<string,string>} chipMap key 与 buildIpChipClassMap 一致
   * @returns {{ displayIp: string, paletteKey: string, chipClass: string, tailZh: string }[]}
   */
  function buildEgressLegendLines(rows, chipMap) {
    if (!rows || !rows.length || !chipMap.size) return [];
    var parts = [...chipMap.entries()].sort(function (a, b) {
      return String(a[0]).localeCompare(String(b[0]), undefined, { numeric: true });
    });
    return parts.map(function (ent) {
      var paletteKey = ent[0];
      var chipClass = ent[1];
      var displayIp = paletteKey;
      var tailZh = "";
      var i;
      for (i = 0; i < rows.length; i++) {
        if (String(rows[i].http_code) !== "200") continue;
        var sip = extractPrimaryIpFromRow(rows[i]);
        if (!sip) continue;
        if (normalizeIpPaletteKey(sip) !== paletteKey) continue;
        displayIp = sip;
        var sn = String(rows[i].snippet || "");
        var idx = sn.indexOf("来自于");
        if (idx >= 0 && /[\u4e00-\u9fff]/.test(sn.slice(idx))) {
          tailZh = sn.slice(idx).trim();
          break;
        }
      }
      return { displayIp: displayIp, paletteKey: paletteKey, chipClass: chipClass, tailZh: tailZh };
    });
  }

  /** 将 ipip 的完整「当前 IP…来自于…」行复制到其它仅含同 IP 的成功探测行。*/
  function applyIpipRef(rows) {
    var ref = null;
    var ri;
    for (ri = 0; ri < rows.length; ri++) {
      if (rows[ri].probe_name === "ipip.net" && String(rows[ri].http_code) === "200") {
        ref = parseIpipRef(rows[ri].snippet);
        break;
      }
    }
    if (!ref) {
      return rows.map(function (r) {
        return Object.assign({}, r);
      });
    }
    return rows.map(function (r) {
      var copy = Object.assign({}, r);
      if (String(copy.http_code) !== "200") return copy;
      var sn = String(copy.snippet || "");
      if (hasZhGeoTail(sn)) return copy;
      var ip = extractPrimaryIpFromRow(copy);
      if (!ip) return copy;
      if (normalizeIpPaletteKey(ip) === ref.ipKey) {
        copy.snippet = ref.full;
      }
      return copy;
    });
  }

  /**
   * 补全「来自于：…」。仅在有同源宿主（hjs-egress-ip serve）时调用 /__geo（中文行政区划，无英文数据源）。
   * file:// 等场景不发起任何归属查询，避免出现英文地名。
   */
  function fetchGeoTail(ip) {
    var relay = sameOriginRelayBase();
    if (!relay) return Promise.resolve("");
    var u = relay + "/__geo?ip=" + encodeURIComponent(ip);
    return fetchWithDeadline(u, {
      method: "GET",
      cache: "no-store",
      mode: "cors",
      credentials: "omit",
    })
      .then(function (res) {
        return res.json();
      })
      .then(function (j) {
        if (!j || typeof j.tail !== "string") return "";
        return j.tail.indexOf("来自于") >= 0 ? j.tail : "";
      })
      .catch(function () {
        return "";
      });
  }

  function applyRemoteGeo(rows) {
    var out = rows.map(function (r) {
      return Object.assign({}, r);
    });
    var needIdx = [];
    var i;
    for (i = 0; i < out.length; i++) {
      var r0 = out[i];
      if (String(r0.http_code) !== "200") continue;
      var sn0 = String(r0.snippet || "");
      if (hasZhGeoTail(sn0)) continue;
      if (sn0.indexOf("file 打开") >= 0 || sn0.indexOf("超时") >= 0) continue;
      var ip0 = extractPrimaryIpFromRow(r0);
      if (!ip0) continue;
      needIdx.push(i);
    }
    var uniq = [];
    var seenK = new Set();
    for (i = 0; i < needIdx.length; i++) {
      var ipx = extractPrimaryIpFromRow(out[needIdx[i]]);
      if (!ipx) continue;
      var k = normalizeIpPaletteKey(ipx);
      if (seenK.has(k)) continue;
      seenK.add(k);
      uniq.push(ipx);
    }
    if (!uniq.length) return Promise.resolve(out);

    return Promise.all(
      uniq.map(function (ip) {
        return fetchGeoTail(ip).then(function (tail) {
          return { ip: ip, key: normalizeIpPaletteKey(ip), tail: tail };
        });
      })
    ).then(function (pairs) {
      var tailByKey = {};
      for (i = 0; i < pairs.length; i++) {
        if (pairs[i].tail) tailByKey[pairs[i].key] = pairs[i].tail;
      }
      for (i = 0; i < out.length; i++) {
        if (String(out[i].http_code) !== "200") continue;
        if (hasZhGeoTail(String(out[i].snippet))) continue;
        var ip2 = extractPrimaryIpFromRow(out[i]);
        if (!ip2) continue;
        var tk = normalizeIpPaletteKey(ip2);
        var tail = tailByKey[tk];
        if (!tail) continue;
        var combined = "当前 IP: " + ip2 + " " + tail;
        out[i] = Object.assign({}, out[i], { snippet: combined.slice(0, 280) });
      }
      return out;
    });
  }

  /**
   * 远程补全后再次对齐：凡与 ipip 当前出口 IP 相同的成功行（非 ipip 自身），摘要强制为 ipip 原文，
   * 避免出现同一 IP 一条中文、一条英文。
   */
  function applyIpipRefPost(rows) {
    var ref = null;
    var ri;
    for (ri = 0; ri < rows.length; ri++) {
      if (rows[ri].probe_name === "ipip.net" && String(rows[ri].http_code) === "200") {
        ref = parseIpipRef(rows[ri].snippet);
        break;
      }
    }
    if (!ref) return rows;
    return rows.map(function (r) {
      if (String(r.http_code) !== "200") return r;
      if (r.probe_name === "ipip.net") return r;
      var ip = extractPrimaryIpFromRow(r);
      if (!ip || normalizeIpPaletteKey(ip) !== ref.ipKey) return r;
      return Object.assign({}, r, { snippet: ref.full });
    });
  }

  function finalizeProbeRowsForDisplay(rows) {
    return applyRemoteGeo(applyIpipRef(rows)).then(function (enriched) {
      return applyIpipRefPost(enriched);
    });
  }

  function runBrowserProbes(scenarioLabel) {
    var lab = scenarioLabel === undefined ? "浏览器" : scenarioLabel;
    return Promise.all(PROBES.map(function (p) {
      return fetchOneProbe(p, lab);
    }))
      .then(finalizeProbeRowsForDisplay)
      .then(function (rows) {
        return { rows: rows, scenario: lab };
      });
  }

  function buildGroups(rows) {
    /** @type {Record<string, object[]>} */
    var buckets = {};
    var i;
    for (i = 0; i < GROUP_ORDER.length; i++) buckets[GROUP_ORDER[i]] = [];
    for (i = 0; i < rows.length; i++) {
      var r = rows[i];
      var cat = r.category || "";
      if (buckets[cat]) buckets[cat].push(r);
    }
    var out = [];
    for (i = 0; i < GROUP_ORDER.length; i++) {
      var key = GROUP_ORDER[i];
      var list = buckets[key];
      if (list.length) out.push({ key: key, title: GROUP_LABELS[key], rows: list });
    }
    return out;
  }

  var IP_CHIP_VARIANTS = 10;

  /** @param {string} raw */
  function normalizeIpPaletteKey(raw) {
    if (/[.]/.test(raw)) return raw;
    return raw.toLowerCase();
  }

  function findIpSpansInText(s) {
    if (!s || typeof s !== "string") return [];

    var spans = [];
    var m;

    var reV4 =
      /\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\b/g;
    while ((m = reV4.exec(s))) spans.push({ start: m.index, end: m.index + m[0].length, raw: m[0] });

    var reV6full = /\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b/g;
    while ((m = reV6full.exec(s))) spans.push({ start: m.index, end: m.index + m[0].length, raw: m[0] });

    var reV6zip =
      /\b(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F:.]{3,}|::(?:[fF]{4}:)?(?:(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)\.){3}(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)|\b(?:[0-9a-fA-F]{1,4}:){1,5}:[0-9a-fA-F:.]{4,}\b/g;
    while ((m = reV6zip.exec(s))) spans.push({ start: m.index, end: m.index + m[0].length, raw: m[0] });

    spans.sort(function (a, b) {
      return a.start - b.start || b.end - a.end - (a.end - a.start);
    });
    var merged = [];
    for (var j = 0; j < spans.length; j++) {
      var sp = spans[j];
      var clashes = merged.some(function (o) {
        return !(sp.end <= o.start || sp.start >= o.end);
      });
      if (!clashes) merged.push(sp);
    }
    merged.sort(function (a, b) {
      return a.start - b.start;
    });
    return merged;
  }

  function buildIpChipClassMap(rows) {
    var keys = [];
    var seen = new Set();
    var i;
    for (i = 0; i < rows.length; i++) {
      var r = rows[i];
      var snip = String(r.snippet ?? "");
      var spansList = findIpSpansInText(snip);
      for (var t = 0; t < spansList.length; t++) {
        var span = spansList[t];
        var k = normalizeIpPaletteKey(span.raw);
        if (!seen.has(k)) {
          seen.add(k);
          keys.push(k);
        }
      }
    }
    keys.sort();
    var map = new Map();
    keys.forEach(function (k2, idx) {
      map.set(k2, "ip-c" + (idx % IP_CHIP_VARIANTS));
    });
    return map;
  }

  function escapeHtmlForSnippet(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function formatSnippetHtmlWithIpChips(snippet, classByKey) {
    var spans = findIpSpansInText(snippet);
    if (!spans.length || !classByKey || classByKey.size === 0) {
      return escapeHtmlForSnippet(snippet);
    }
    var ii = 0;
    var result = "";
    for (var sx = 0; sx < spans.length; sx++) {
      var sp = spans[sx];
      result += escapeHtmlForSnippet(snippet.slice(ii, sp.start));
      var cls = classByKey.get(normalizeIpPaletteKey(sp.raw));
      var inner = escapeHtmlForSnippet(snippet.slice(sp.start, sp.end));
      result += cls
        ? '<span class="ip-chip ' + cls + '" title="' + inner + '">' + inner + "</span>"
        : inner;
      ii = sp.end;
    }
    result += escapeHtmlForSnippet(snippet.slice(ii));
    return result;
  }

  g.HjsEgressAuditCore = {
    GROUP_ORDER: GROUP_ORDER,
    GROUP_LABELS: GROUP_LABELS,
    CATEGORY_UI_LABEL: CATEGORY_UI_LABEL,
    formatUiCategory: formatUiCategory,
    PROBES: PROBES,
    snippetFromBody: snippetFromBody,
    fetchOneProbe: fetchOneProbe,
    finalizeProbeRowsForDisplay: finalizeProbeRowsForDisplay,
    runBrowserProbes: runBrowserProbes,
    buildGroups: buildGroups,
    IP_CHIP_VARIANTS: IP_CHIP_VARIANTS,
    normalizeIpPaletteKey: normalizeIpPaletteKey,
    findIpSpansInText: findIpSpansInText,
    buildIpChipClassMap: buildIpChipClassMap,
    buildEgressLegendLines: buildEgressLegendLines,
    escapeHtmlForSnippet: escapeHtmlForSnippet,
    formatSnippetHtmlWithIpChips: formatSnippetHtmlWithIpChips,
  };
})(typeof globalThis !== "undefined" ? globalThis : typeof window !== "undefined" ? window : this);
