#!/usr/bin/env node
'use strict';

const fs = require('fs');

function fail(msg) { process.stderr.write(String(msg) + '\n'); process.exit(1); }

const inPath = process.argv[2];
const outPath = process.argv[3];
if (!inPath || !outPath) fail('usage: ua-arch-analyze.js <input.json> <output.json>');

let data;
try { data = JSON.parse(fs.readFileSync(inPath, 'utf8')); }
catch (e) { fail('cannot read/parse input: ' + e.message); }

const fileNodes = Array.isArray(data.fileNodes) ? data.fileNodes : [];
const importEdges = Array.isArray(data.importEdges) ? data.importEdges : [];
const allEdges = Array.isArray(data.allEdges) ? data.allEdges : [];

if (fileNodes.length === 0) fail('no fileNodes provided');

// ---- helpers ------------------------------------------------------------
const nodeById = new Map();
for (const n of fileNodes) nodeById.set(n.id, n);

function filePathOf(n) { return (n.filePath || n.name || n.id || '').replace(/^[a-z]+:/i, ''); }

// A. common prefix across all file paths (segment-based)
const paths = fileNodes.map(filePathOf);
function commonPrefixSegments(ps) {
  if (ps.length === 0) return [];
  const split = ps.map(p => p.split('/').slice(0, -1)); // dir segments only (drop filename)
  let prefix = split[0] || [];
  for (let i = 1; i < split.length; i++) {
    const s = split[i];
    let j = 0;
    while (j < prefix.length && j < s.length && prefix[j] === s[j]) j++;
    prefix = prefix.slice(0, j);
    if (prefix.length === 0) break;
  }
  return prefix;
}
const prefixSegs = commonPrefixSegments(paths);
const prefixLen = prefixSegs.length;

// B. directory grouping (first segment after common prefix)
const directoryGroups = {};
const groupOfNode = new Map();
for (const n of fileNodes) {
  const segs = filePathOf(n).split('/');
  const after = segs.slice(prefixLen);
  let group;
  if (after.length <= 1) group = '(root)'; // file directly at the prefix level
  else group = after[0];
  if (!directoryGroups[group]) directoryGroups[group] = [];
  directoryGroups[group].push(n.id);
  groupOfNode.set(n.id, group);
}

// B2. node type grouping
const nodeTypeGroups = {};
for (const n of fileNodes) {
  const t = n.type || 'file';
  if (!nodeTypeGroups[t]) nodeTypeGroups[t] = [];
  nodeTypeGroups[t].push(n.id);
}

// C. import adjacency (fan-in / fan-out) from importEdges
const fanOut = {}, fanIn = {};
for (const n of fileNodes) { fanOut[n.id] = 0; fanIn[n.id] = 0; }
for (const e of importEdges) {
  if (fanOut[e.source] !== undefined) fanOut[e.source]++;
  if (fanIn[e.target] !== undefined) fanIn[e.target]++;
}

// D. cross-category dependency analysis (allEdges, by node type)
const crossMap = new Map(); // key fromType|toType|edgeType -> count
for (const e of allEdges) {
  const s = nodeById.get(e.source), t = nodeById.get(e.target);
  if (!s || !t) continue;
  const st = s.type || 'file', tt = t.type || 'file';
  if (st === tt && st === 'file') continue; // skip pure file->file here; captured elsewhere
  const key = st + '|' + tt + '|' + (e.type || 'rel');
  crossMap.set(key, (crossMap.get(key) || 0) + 1);
}
const crossCategoryEdges = [...crossMap.entries()].map(([k, count]) => {
  const [fromType, toType, edgeType] = k.split('|');
  return { fromType, toType, edgeType, count };
}).sort((a, b) => b.count - a.count);

// E. inter-group import frequency (importEdges)
const interMap = new Map();
for (const e of importEdges) {
  const g1 = groupOfNode.get(e.source), g2 = groupOfNode.get(e.target);
  if (g1 == null || g2 == null || g1 === g2) continue;
  const key = g1 + '\u0000' + g2;
  interMap.set(key, (interMap.get(key) || 0) + 1);
}
const interGroupImports = [...interMap.entries()].map(([k, count]) => {
  const [from, to] = k.split('\u0000');
  return { from, to, count };
}).sort((a, b) => b.count - a.count);

// F. intra-group import density
const intraGroupDensity = {};
const groupEdgeTotals = {};
for (const g of Object.keys(directoryGroups)) { intraGroupDensity[g] = { internalEdges: 0, totalEdges: 0, density: 0 }; groupEdgeTotals[g] = 0; }
for (const e of importEdges) {
  const g1 = groupOfNode.get(e.source), g2 = groupOfNode.get(e.target);
  if (g1 == null || g2 == null) continue;
  if (g1 === g2) intraGroupDensity[g1].internalEdges++;
  // total edges involving the group (as source or target)
  intraGroupDensity[g1].totalEdges++;
  if (g2 !== g1) intraGroupDensity[g2].totalEdges++;
}
for (const g of Object.keys(intraGroupDensity)) {
  const d = intraGroupDensity[g];
  d.density = d.totalEdges > 0 ? +(d.internalEdges / d.totalEdges).toFixed(3) : 0;
}

// G. directory + file pattern matching
const dirPatterns = [
  [/^(routes|api|controllers|endpoints|handlers|controller|routers|serializers|blueprints|api layer)$/i, 'api'],
  [/^(services|core|lib|domain|logic|signals|composables|mailers|jobs|channels|rendering)$/i, 'service'],
  [/^(models|db|data|persistence|repository|entities|entity|migrations|sql|database)$/i, 'data'],
  [/^(components|views|pages|ui|layouts|screens|uicoordinator)$/i, 'ui'],
  [/^(middleware|plugins|interceptors|guards)$/i, 'middleware'],
  [/^(utils|helpers|common|shared|tools|pkg|templatetags)$/i, 'utility'],
  [/^(config|constants|env|settings|management|commands)$/i, 'config'],
  [/^(__tests__|test|tests|spec|specs)$/i, 'test'],
  [/^(types|interfaces|schemas|contracts|dtos|dto|request|response)$/i, 'types'],
  [/^(hooks)$/i, 'hooks'],
  [/^(store|state|reducers|actions|slices)$/i, 'state'],
  [/^(assets|static|public)$/i, 'assets'],
  [/^(cmd|bin|internal)$/i, 'entry'],
  [/^(docs|documentation|wiki)$/i, 'documentation'],
  [/^(deploy|deployment|infra|infrastructure|k8s|kubernetes|helm|charts|terraform|tf|docker)$/i, 'infrastructure'],
  [/^(\.github|\.gitlab|\.circleci)$/i, 'ci-cd'],
  [/^(navigation)$/i, 'service'],
  [/^(content)$/i, 'data'],
];
function matchDir(name) {
  for (const [re, label] of dirPatterns) if (re.test(name)) return label;
  return null;
}
function matchFile(n) {
  const p = filePathOf(n);
  const base = p.split('/').pop();
  if (/(\.test\.|\.spec\.|_test\.|test_|Test\.java$|_spec\.rb$|Test\.php$|Tests\.cs$)/.test(base) || /Tests?\.swift$/.test(base)) return 'test';
  if (/\.d\.ts$/.test(base)) return 'types';
  if (/\.(md|rst)$/i.test(base)) return 'documentation';
  if (/\.(sql)$/i.test(base)) return 'data';
  if (/\.(graphql|gql|proto)$/i.test(base)) return 'types';
  if (/^(Dockerfile|docker-compose\.)/.test(base)) return 'infrastructure';
  if (/\.(tf|tfvars)$/.test(base)) return 'infrastructure';
  if (/\.(storyboard|xib)$/i.test(base)) return 'ui';
  if (/^Info\.plist$/i.test(base)) return 'config';
  if (/\.(xcconfig|xcconfig\.example)$/i.test(base) || /xcconfig/i.test(base)) return 'config';
  if (/\.(pbxproj)$/i.test(base) || /project\.pbxproj$/.test(p)) return 'config';
  if (/^Podfile/.test(base) || /^Package\.swift$/.test(base)) return 'config';
  if (/(App|Main)\.swift$/.test(base)) return 'entry';
  return null;
}

const patternMatches = {};
for (const g of Object.keys(directoryGroups)) {
  const m = matchDir(g);
  if (m) patternMatches[g] = m;
}

// per-file pattern matches (useful for semantic phase)
const filePatternMatches = {};
for (const n of fileNodes) {
  const m = matchFile(n);
  if (m) filePatternMatches[n.id] = m;
}

// H. deployment topology
const allPaths = fileNodes.map(filePathOf);
const infraFiles = [];
const hasDockerfile = allPaths.some(p => /(^|\/)Dockerfile/.test(p));
const hasCompose = allPaths.some(p => /docker-compose\./.test(p));
const hasK8s = allPaths.some(p => /(k8s|kubernetes|helm|charts)\//i.test(p));
const hasTerraform = allPaths.some(p => /\.(tf|tfvars)$/.test(p));
const hasCI = allPaths.some(p => /(\.github\/workflows\/|\.gitlab-ci\.yml|Jenkinsfile)/.test(p));
for (const p of allPaths) {
  if (/(^|\/)Dockerfile/.test(p) || /docker-compose\./.test(p) || /\.(tf|tfvars)$/.test(p) ||
      /(\.github\/workflows\/|\.gitlab-ci\.yml|Jenkinsfile)/.test(p) || /(k8s|kubernetes|helm)\//i.test(p) ||
      /(^|\/)Makefile$/.test(p)) infraFiles.push(p);
}
const deploymentTopology = { hasDockerfile, hasCompose, hasK8s, hasTerraform, hasCI, infraFiles };

// I. data pipeline
const dataPipeline = {
  schemaFiles: allPaths.filter(p => /\.(sql|graphql|gql|proto|prisma)$/i.test(p)),
  migrationFiles: allPaths.filter(p => /migrations?\//i.test(p)),
  dataModelFiles: fileNodes.filter(n => /\/Models\//.test(filePathOf(n)) || /model/i.test((n.tags || []).join(','))).map(filePathOf),
  apiHandlerFiles: fileNodes.filter(n => /API Layer\//.test(filePathOf(n)) || /(api-handler|routing|interface)/i.test((n.tags || []).join(','))).map(filePathOf),
};

// J. documentation coverage
const docNodes = fileNodes.filter(n => (n.type === 'document') || /\.(md|rst)$/i.test(filePathOf(n)));
const docGroups = new Set(docNodes.map(n => groupOfNode.get(n.id)));
const allGroups = Object.keys(directoryGroups);
const undocumentedGroups = allGroups.filter(g => !docGroups.has(g));
const docCoverage = {
  groupsWithDocs: docGroups.size,
  totalGroups: allGroups.length,
  coverageRatio: allGroups.length ? +(docGroups.size / allGroups.length).toFixed(2) : 0,
  undocumentedGroups,
};

// K. dependency direction (dominant direction between group pairs)
const pairCount = new Map();
for (const e of importEdges) {
  const g1 = groupOfNode.get(e.source), g2 = groupOfNode.get(e.target);
  if (g1 == null || g2 == null || g1 === g2) continue;
  pairCount.set(g1 + '>' + g2, (pairCount.get(g1 + '>' + g2) || 0) + 1);
}
const seenPairs = new Set();
const dependencyDirection = [];
for (const [k] of pairCount) {
  const [a, b] = k.split('>');
  const unordered = [a, b].sort().join('|');
  if (seenPairs.has(unordered)) continue;
  seenPairs.add(unordered);
  const ab = pairCount.get(a + '>' + b) || 0;
  const ba = pairCount.get(b + '>' + a) || 0;
  if (ab >= ba && ab > 0) dependencyDirection.push({ dependent: a, dependsOn: b });
  else if (ba > 0) dependencyDirection.push({ dependent: b, dependsOn: a });
}

// file stats
const filesPerGroup = {};
for (const g of Object.keys(directoryGroups)) filesPerGroup[g] = directoryGroups[g].length;
const nodeTypeCounts = {};
for (const t of Object.keys(nodeTypeGroups)) nodeTypeCounts[t] = nodeTypeGroups[t].length;

const result = {
  scriptCompleted: true,
  commonPrefix: prefixSegs.join('/'),
  directoryGroups,
  nodeTypeGroups,
  crossCategoryEdges,
  interGroupImports,
  intraGroupDensity,
  patternMatches,
  filePatternMatches,
  deploymentTopology,
  dataPipeline,
  docCoverage,
  dependencyDirection,
  fileStats: { totalFileNodes: fileNodes.length, filesPerGroup, nodeTypeCounts },
  fileFanIn: fanIn,
  fileFanOut: fanOut,
};

try { fs.writeFileSync(outPath, JSON.stringify(result, null, 2)); }
catch (e) { fail('cannot write output: ' + e.message); }
process.exit(0);
