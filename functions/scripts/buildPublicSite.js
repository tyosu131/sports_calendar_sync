'use strict';

const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');

function renderSite(config) {
  if (typeof config.operatorName !== 'string' || !config.operatorName.trim() ||
      typeof config.supportEmail !== 'string' || !/^[^\s<>@]+@[^\s<>@]+\.[^\s<>@]+$/.test(config.supportEmail)) {
    throw new Error('Set the human-approved public operatorName and supportEmail in hosting/site.json before publishing.');
  }
  const url = new URL(config.publicUrl);
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash || url.pathname !== '/') {
    throw new Error('publicUrl must be an HTTPS origin without credentials, query or fragment.');
  }
  const escape = value => value.replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  return new Map(['index.html', 'privacy.html', 'terms.html', 'style.css'].map(file => {
    const template = fs.readFileSync(path.join(root, 'hosting/templates', file), 'utf8');
    const rendered = template.replace(/\{\{(operatorName|supportEmail|publicUrl)\}\}/g,
      (_, key) => escape(key === 'publicUrl' ? url.origin : config[key]));
    if (/\{\{/.test(rendered)) throw new Error('Unresolved public page placeholder');
    return [file, rendered];
  }));
}

if (require.main === module) {
  const rendered = renderSite(require('../../hosting/site.json'));
  const dir = path.join(root, 'hosting/dist');
  fs.mkdirSync(dir, {recursive: true});
  for (const [file, content] of rendered) fs.writeFileSync(path.join(dir, file), content);
  console.log('Public pages built. Deployment and Google verification are separate actions.');
}
module.exports = {renderSite};
