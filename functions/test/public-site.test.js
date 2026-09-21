const test = require('node:test');
const assert = require('node:assert/strict');
const {renderSite} = require('../scripts/buildPublicSite');
const config = {operatorName: 'Test Operator', supportEmail: 'support@example.test', publicUrl: 'https://example.test'};

test('publishing requires human-approved public identity and contact', () => {
  for (const invalid of [{...config, operatorName: ''}, {...config, supportEmail: ''},
    {...config, publicUrl: 'http://example.test'}, {...config, publicUrl: 'https://user:secret@example.test'}]) {
    assert.throws(() => renderSite(invalid));
  }
});

test('public pages explain the app, link policies and disclose actual Google usage', () => {
  const pages = renderSite(config);
  assert.equal(pages.size, 4);
  for (const [file, text] of pages) {
    assert.doesNotMatch(text, /\{\{|<script|analytics/i);
    if (file.endsWith('.html')) {
      assert.match(text, /Sports Calendar/);
      assert.match(text, /href="\/privacy"/);
      assert.match(text, /href="\/terms"/);
      assert.match(text, /support@example.test/);
    }
  }
  assert.match(pages.get('index.html'), /calendar.app.created/);
  assert.match(pages.get('privacy.html'), /Limited Use/);
  assert.match(pages.get('privacy.html'), /削除依頼/);
  assert.match(pages.get('privacy.html'), /メインカレンダー/);
});

test('public configuration is escaped instead of becoming executable markup', () => {
  const pages = renderSite({...config, operatorName: '<script>alert(1)</script>'});
  assert.doesNotMatch(pages.get('index.html'), /<script>/);
  assert.match(pages.get('index.html'), /&lt;script&gt;/);
});

test('Hosting release guard and static security headers are wired', () => {
  const {hosting} = require('../../firebase.json');
  assert.equal(hosting.public, 'hosting/dist');
  assert.equal(hosting.cleanUrls, true);
  assert.equal(hosting.trailingSlash, false);
  assert.ok(hosting.predeploy.includes('node functions/scripts/buildPublicSite.js'));
  assert.ok(hosting.headers[0].headers.some(header => header.key === 'Content-Security-Policy'));
  assert.equal(hosting.rewrites, undefined); // Current production OAuth URI is preserved.
});

test('confirmed public identity renders without placeholders or staging links', () => {
  const confirmed = require('../../hosting/site.json');
  assert.deepEqual(confirmed, {
    operatorName: 'Taisei Kawakami', supportEmail: 'support@sports-calendar-sync.com',
    publicUrl: 'https://sports-calendar-sync.com',
  });
  for (const [file, html] of renderSite(confirmed)) {
    if (!file.endsWith('.html')) continue;
    assert.match(html, /Sports Calendar/);
    assert.match(html, /Taisei Kawakami/);
    assert.match(html, /mailto:support@sports-calendar-sync\.com/);
    assert.doesNotMatch(html, /\{\{|web\.app|example\.test|\/privacy\.html|\/terms\.html/);
  }
  const home = renderSite(confirmed).get('index.html');
  assert.ok(home.includes('https://sports-calendar-sync.com/privacy'));
  assert.ok(home.includes('https://sports-calendar-sync.com/terms'));
  assert.match(renderSite(confirmed).get('privacy.html'), /権利を確認できていないため表示しません/);
});
