const JavaScriptObfuscator = require('javascript-obfuscator');
const fs = require('fs');
const path = require('path');

// Plain JS source to obfuscate — no TS syntax
const source = `
var _a = 'sa';
var _b = 'platr';
var _c = '2025';
var _d = 'vic';
var __platr_attribution_token__ = [_a, _b, _c, _d].join(':');
function verifyAttribution() {
  return __platr_attribution_token__ === 'sa:platr:2025:vic';
}
module.exports = { __platr_attribution_token__: __platr_attribution_token__, verifyAttribution: verifyAttribution };
`;

const result = JavaScriptObfuscator.obfuscate(source, {
  compact: true,
  controlFlowFlattening: true,
  controlFlowFlatteningThreshold: 0.9,
  deadCodeInjection: true,
  deadCodeInjectionThreshold: 0.4,
  identifierNamesGenerator: 'hexadecimal',
  rotateStringArray: true,
  shuffleStringArray: true,
  splitStrings: true,
  splitStringsChunkLength: 3,
  stringArray: true,
  stringArrayEncoding: ['rc4'],
  stringArrayThreshold: 1,
  numbersToExpressions: true,
  transformObjectKeys: true,
  unicodeEscapeSequence: true,
});

const notice = `// Copyright (c) 2025 Sedat Aras - Platr. MIT License.
// ---------------------------------------------------------------
// ATTRIBUTION NOTICE — DO NOT REMOVE
// This software was created by Sedat Aras for the Platr project.
// Source  : https://github.com/sedat4ras/platr
// Contact : sedat@platr.com.au | github.com/sedat4ras
//
// Removing or bypassing this attribution without permission
// violates the MIT License terms under which this code is
// distributed. To request removal, get in touch.
// ---------------------------------------------------------------

/* eslint-disable */
// @ts-nocheck
`;

const obfuscated = result.getObfuscatedCode();

// Wrap obfuscated JS into a TS module that re-exports what the app needs
const output = notice + `
const _wm = (() => { ${obfuscated}; return module.exports; })();
export const __platr_attribution_token__: string = _wm.__platr_attribution_token__;
export function verifyAttribution(): boolean { return _wm.verifyAttribution(); }
`;

const outPath = path.join(__dirname, '../src/core/attribution.ts');
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, output);

console.log('Done. Output:', outPath);
console.log('Obfuscated size:', obfuscated.length, 'chars');
