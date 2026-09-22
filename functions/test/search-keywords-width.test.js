'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {generateSearchKeywords, widthVariants} = require('../scripts/searchKeywords');

test('width variants are bidirectional and bounded', () => {
  assert.deepEqual(widthVariants('FC東京'), ['FC東京', 'ＦＣ東京']);
  assert.deepEqual(widthVariants('ＦＣ東京'), ['ＦＣ東京', 'FC東京']);
  assert.ok(widthVariants('RB大宮').length <= 2);
});

test('generated search keywords preserve formal and ASCII-width inputs', () => {
  const keywords = generateSearchKeywords({nameJa: 'ＦＣ東京', aliases: ['FC東京']});
  assert.ok(keywords.includes('ＦＣ東京'));
  assert.ok(keywords.includes('FC東京'));
});
