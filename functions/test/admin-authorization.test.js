'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const { requireAdmin } = require('../lib/functions/adminAuthorization');

test('manual sync authorization requires authentication and admin claim', () => {
  assert.throws(() => requireAdmin({}), error => error.code === 'unauthenticated');
  assert.throws(() => requireAdmin({ auth: { token: {}, uid: 'x' } }), error => error.code === 'permission-denied');
  assert.doesNotThrow(() => requireAdmin({ auth: { token: { admin: true }, uid: 'x' } }));
});
