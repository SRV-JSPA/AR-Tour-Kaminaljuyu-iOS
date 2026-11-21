#!/usr/bin/env node
'use strict';
/*
 * Tour topology analyzer.
 *
 * This graph expresses dependencies as `depends_on` (import-like) and `calls`
 * edges, and its edges connect nodes at mixed granularity (file / class /
 * function). The dispatch requires tour steps to be built from FILE-LEVEL
 * nodes only (file, config, document). We therefore PROJECT every edge onto
 * the file level (each class/function node maps to the file whose filePath it
 * shares) and compute all structural metrics on that file-level graph, while
 * still indexing every node's summary.
 */

const fs = require('fs');

function main() {
  const inputPath = process.argv[2];
  const outputPath = process.argv[3];
  if (!inputPath || !outputPath) {
    console.error('Usage: ua-tour-analyze.js <input.json> <output.json>');
    process.exit(1);
  }

  const raw = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
  const nodes = raw.nodes || [];
  const edges = raw.edges || [];
  const layers = raw.layers || [];

  const byId = new Map(nodes.map((n) => [n.id, n]));
  const FILE_LEVEL = new Set(['file', 'config', 'document']);

  // --- file node lookup by filePath (to project member nodes onto files) ---
  const fileByPath = new Map();
  for (const n of nodes) {
    if (FILE_LEVEL.has(n.type) && n.filePath) fileByPath.set(n.filePath, n.id);
  }

  // container file id for any node id
  function containerFile(id) {
    const n = byId.get(id);
    if (!n) return null;
    if (FILE_LEVEL.has(n.type)) return n.id;
    if (n.filePath && fileByPath.has(n.filePath)) return fileByPath.get(n.filePath);
    return null; // orphan member with no matching file
  }

  // --- node summary index (ALL node types) ---
  const nodeSummaryIndex = {};
  for (const n of nodes) {
    nodeSummaryIndex[n.id] = { name: n.name, type: n.type, summary: n.summary || '' };
  }

  // --- build file-level projected graph ---
  // Dependency-ish edges projected to files. `contains` and `exports` are
  // structural decomposition (file -> its own members) and project to
  // self-loops, so they are skipped. We keep depends_on, calls, documents,
  // related, tested_by, configures as inter-file relations.
  const DEP_EDGE_TYPES = new Set(['depends_on', 'calls']); // forward traversal for BFS
  const KEEP_FOR_DEGREE = new Set([
    'depends_on', 'calls', 'documents', 'related', 'tested_by', 'configures',
  ]);

  const fileNodes = nodes.filter((n) => FILE_LEVEL.has(n.type));
  const fileIds = new Set(fileNodes.map((n) => n.id));

  const fanInSet = new Map();   // fileId -> Set of sources pointing to it
  const fanOutSet = new Map();  // fileId -> Set of targets it points to
  for (const id of fileIds) { fanInSet.set(id, new Set()); fanOutSet.set(id, new Set()); }

  // forward adjacency for BFS (dependency edges only)
  const depAdj = new Map();
  for (const id of fileIds) depAdj.set(id, new Set());

  // undirected edge multiplicity between file pairs (for clustering)
  const pairCount = new Map();        // "a||b" (sorted) -> count
  const directedPair = new Set();     // "src->tgt" for bidirectional detection (dep edges)

  for (const e of edges) {
    const sf = containerFile(e.source);
    const tf = containerFile(e.target);
    if (!sf || !tf || sf === tf) continue; // skip unresolved + self-loops
    if (!fileIds.has(sf) || !fileIds.has(tf)) continue;

    if (KEEP_FOR_DEGREE.has(e.type)) {
      fanOutSet.get(sf).add(tf);
      fanInSet.get(tf).add(sf);
      const key = sf < tf ? sf + '||' + tf : tf + '||' + sf;
      pairCount.set(key, (pairCount.get(key) || 0) + 1);
    }
    if (DEP_EDGE_TYPES.has(e.type)) {
      depAdj.get(sf).add(tf);
      directedPair.add(sf + '->' + tf);
    }
  }

  const nameOf = (id) => (byId.get(id) || {}).name || id;
  const sumOf = (id) => (byId.get(id) || {}).summary || '';

  // --- A. Fan-in ranking ---
  const fanInRanking = [...fileIds]
    .map((id) => ({ id, fanIn: fanInSet.get(id).size, name: nameOf(id) }))
    .sort((a, b) => b.fanIn - a.fanIn || a.id.localeCompare(b.id))
    .slice(0, 20);

  // --- B. Fan-out ranking ---
  const fanOutRanking = [...fileIds]
    .map((id) => ({ id, fanOut: fanOutSet.get(id).size, name: nameOf(id) }))
    .sort((a, b) => b.fanOut - a.fanOut || a.id.localeCompare(b.id))
    .slice(0, 20);

  // --- C. Entry point candidates ---
  const fanOutVals = [...fileIds].map((id) => fanOutSet.get(id).size).sort((a, b) => a - b);
  const fanInVals = [...fileIds].map((id) => fanInSet.get(id).size).sort((a, b) => a - b);
  const pct = (arr, p) => {
    if (!arr.length) return 0;
    const idx = Math.min(arr.length - 1, Math.floor(p * (arr.length - 1)));
    return arr[idx];
  };
  const fanOutTop10 = pct(fanOutVals, 0.9);
  const fanInBottom25 = pct(fanInVals, 0.25);

  const ENTRY_NAMES = new Set([
    'index.ts', 'index.js', 'main.ts', 'main.js', 'app.ts', 'app.js',
    'server.ts', 'server.js', 'mod.rs', 'main.go', 'main.py', 'main.rs',
    'manage.py', 'app.py', 'wsgi.py', 'asgi.py', 'run.py', '__main__.py',
    'Application.java', 'Main.java', 'Program.cs', 'config.ru', 'index.php',
    'App.swift', 'Application.kt', 'main.cpp', 'main.c',
  ]);

  function entryScore(n) {
    let score = 0;
    const fname = n.name || '';
    const fp = n.filePath || '';
    const depth = fp.split('/').length; // segments
    if (n.type === 'document') {
      if (fname === 'README.md' && depth === 1) score += 5;
      else if (/\.md$/i.test(fname) && depth === 1) score += 2;
      return score;
    }
    // code / config files
    if (ENTRY_NAMES.has(fname)) score += 3;
    // Swift SwiftUI @main entry: *App.swift
    else if (/App\.swift$/.test(fname)) score += 3;
    if (depth <= 2) score += 1; // root or one level deep
    if (fanOutSet.has(n.id) && fanOutSet.get(n.id).size >= fanOutTop10 && fanOutTop10 > 0) score += 1;
    if (fanInSet.has(n.id) && fanInSet.get(n.id).size <= fanInBottom25) score += 1;
    return score;
  }

  const entryScored = fileNodes
    .map((n) => ({ id: n.id, score: entryScore(n), name: n.name, type: n.type, summary: n.summary || '' }))
    .sort((a, b) => b.score - a.score || a.id.localeCompare(b.id));
  const entryPointCandidates = entryScored.slice(0, 5);

  // --- D. BFS from top CODE entry candidate (skip documents) ---
  const codeEntry = entryScored.find((c) => (byId.get(c.id) || {}).type !== 'document');
  const startNode = codeEntry ? codeEntry.id : (fileNodes[0] && fileNodes[0].id);

  const order = [];
  const depthMap = {};
  if (startNode) {
    const queue = [startNode];
    depthMap[startNode] = 0;
    while (queue.length) {
      const cur = queue.shift();
      order.push(cur);
      const nbrs = [...(depAdj.get(cur) || [])].sort();
      for (const nb of nbrs) {
        if (depthMap[nb] === undefined) {
          depthMap[nb] = depthMap[cur] + 1;
          queue.push(nb);
        }
      }
    }
  }
  const byDepth = {};
  for (const [id, d] of Object.entries(depthMap)) {
    (byDepth[d] = byDepth[d] || []).push(id);
  }
  for (const d of Object.keys(byDepth)) byDepth[d].sort();

  // --- E. Non-code file inventory ---
  const nonCodeFiles = { documentation: [], infrastructure: [], data: [], config: [] };
  for (const n of nodes) {
    const rec = { id: n.id, name: n.name, type: n.type, summary: n.summary || '' };
    if (n.type === 'document') nonCodeFiles.documentation.push(rec);
    else if (['service', 'pipeline', 'resource'].includes(n.type)) nonCodeFiles.infrastructure.push(rec);
    else if (['table', 'schema', 'endpoint'].includes(n.type)) nonCodeFiles.data.push(rec);
    else if (n.type === 'config') nonCodeFiles.config.push(rec);
  }

  // --- F. Tightly coupled clusters ---
  // Seed clusters from bidirectional dependency pairs, then grow by adding
  // files connected (any kept edge) to >=2 current members.
  const adjAll = new Map(); // undirected neighbor set over kept edges
  for (const id of fileIds) adjAll.set(id, new Set());
  for (const key of pairCount.keys()) {
    const [a, b] = key.split('||');
    adjAll.get(a).add(b);
    adjAll.get(b).add(a);
  }

  const seeds = [];
  const seenSeed = new Set();
  for (const key of directedPair) {
    const [a, b] = key.split('->');
    if (directedPair.has(b + '->' + a)) {
      const k = a < b ? a + '||' + b : b + '||' + a;
      if (!seenSeed.has(k)) { seenSeed.add(k); seeds.push([a, b]); }
    }
  }
  // Fallback: if no bidirectional dep pairs, seed from highest-multiplicity pairs
  if (seeds.length === 0) {
    const topPairs = [...pairCount.entries()]
      .filter(([, c]) => c >= 2)
      .sort((x, y) => y[1] - x[1])
      .slice(0, 10);
    for (const [key] of topPairs) seeds.push(key.split('||'));
  }

  const clusters = [];
  const clusterSignatures = new Set();
  for (const seed of seeds) {
    const members = new Set(seed);
    let grew = true;
    while (grew && members.size < 5) {
      grew = false;
      const candidates = new Map(); // candidate -> count of connections into members
      for (const m of members) {
        for (const nb of adjAll.get(m) || []) {
          if (members.has(nb)) continue;
          candidates.set(nb, (candidates.get(nb) || 0) + 1);
        }
      }
      // add the best candidate connected to >=2 members
      let best = null, bestC = 1;
      for (const [c, cnt] of candidates) {
        if (cnt >= 2 && cnt > bestC) { best = c; bestC = cnt; }
      }
      if (best) { members.add(best); grew = true; }
    }
    // internal edge count
    let edgeCount = 0;
    const arr = [...members];
    for (let i = 0; i < arr.length; i++) {
      for (let j = i + 1; j < arr.length; j++) {
        const k = arr[i] < arr[j] ? arr[i] + '||' + arr[j] : arr[j] + '||' + arr[i];
        edgeCount += pairCount.get(k) || 0;
      }
    }
    const sig = arr.slice().sort().join('|');
    if (members.size >= 2 && !clusterSignatures.has(sig)) {
      clusterSignatures.add(sig);
      clusters.push({ nodes: arr, edgeCount });
    }
  }
  clusters.sort((a, b) => b.edgeCount - a.edgeCount || b.nodes.length - a.nodes.length);
  const clustersOut = clusters.slice(0, 10);

  // --- G. Layer list ---
  const layerList = layers.map((l) => ({ id: l.id, name: l.name, description: l.description }));

  const result = {
    scriptCompleted: true,
    projection: 'metrics computed on file-level graph (member edges mapped to containing file via filePath; depends_on+calls used for BFS)',
    entryPointCandidates,
    fanInRanking,
    fanOutRanking,
    bfsTraversal: { startNode, order, depthMap, byDepth },
    nonCodeFiles,
    clusters: clustersOut,
    layers: { count: layers.length, list: layerList },
    nodeSummaryIndex,
    totalNodes: nodes.length,
    totalEdges: edges.length,
    fileLevelNodeCount: fileNodes.length,
  };

  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2));
  console.error('OK: wrote ' + outputPath);
  process.exit(0);
}

try {
  main();
} catch (err) {
  console.error('FATAL: ' + (err && err.stack ? err.stack : err));
  process.exit(1);
}
