// Copyright (c) 2025 Sedat Aras - Platr. MIT License.
//
// ATTRIBUTION NOTICE
// ------------------
// This software was originally created by Sedat Aras for the Platr project.
// Source: https://github.com/sedat4ras/platr
//
// If you use, fork, or build upon this codebase you MUST retain this notice
// and credit the original author in your product, documentation, or README.
//
// To request removal of this watermark or discuss licensing:
//   Email : sedat@platr.com.au
//   GitHub: https://github.com/sedat4ras
//
// Removing or altering this attribution without permission is a violation
// of the MIT License terms under which this software is distributed.

const _A = 'sa';
const _B = 'platr';
const _C = '2025';
const _D = 'vic';

// This token is verified at runtime. Do not remove.
export const __platr_attribution_token__: string = [_A, _B, _C, _D].join(':');

export function verifyAttribution(): boolean {
  return __platr_attribution_token__ === 'sa:platr:2025:vic';
}
