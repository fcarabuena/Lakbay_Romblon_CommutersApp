'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { qualifies, shouldNotify, topicsFor, buildMessages } = require('../alerts');

const now = Date.parse('2026-11-01T00:00:00Z');
const base = {
  severity: 'suspended',
  title: { en: 'Trips suspended', fil: 'Suspendido ang biyahe' },
  message: { en: 'Gale warning.' },
};

test('only live caution and suspension advisories qualify', () => {
  assert.equal(qualifies(base, now), true);
  assert.equal(qualifies({ ...base, severity: 'caution' }, now), true);
  assert.equal(qualifies({ ...base, severity: 'info' }, now), false);
  assert.equal(qualifies({ ...base, deleted: true }, now), false);
  assert.equal(qualifies({ ...base, validUntil: '2026-10-31T00:00:00Z' }, now), false);
  assert.equal(qualifies(undefined, now), false);
});

test('alerts on publish and escalation, not on plain edits', () => {
  assert.equal(shouldNotify(undefined, base, now), true);
  assert.equal(shouldNotify({ ...base, severity: 'info' }, base, now), true);
  assert.equal(shouldNotify({ ...base, severity: 'caution' }, base, now), true);
  assert.equal(shouldNotify(base, { ...base, message: { en: 'Updated' } }, now), false);
  assert.equal(shouldNotify(base, { ...base, severity: 'caution' }, now), false);
  assert.equal(shouldNotify(base, { ...base, deleted: true }, now), false);
  assert.equal(shouldNotify({ ...base, deleted: true }, base, now), true);
});

test('province-wide advisories go to all and general topics', () => {
  assert.deepEqual(topicsFor([]), [
    'adv_all_en', 'adv_general_en', 'adv_all_fil', 'adv_general_fil',
  ]);
});

test('port advisories go to all and each port, deduplicated', () => {
  assert.deepEqual(topicsFor(['b port', 'a', 'a']), [
    'adv_all_en', 'adv_port_a_en', 'adv_port_b-port_en',
    'adv_all_fil', 'adv_port_a_fil', 'adv_port_b-port_fil',
  ]);
});

test('messages are localized, tagged and carry the advisory id', () => {
  const messages = buildMessages('adv1', base, ['odiongan_port']);
  const fil = messages.find((m) => m.topic === 'adv_port_odiongan_port_fil');
  assert.equal(fil.notification.title, 'Suspendido: Suspendido ang biyahe');
  // No Tagalog message: falls back to English.
  assert.equal(fil.notification.body, 'Gale warning.');
  assert.deepEqual(fil.data, { advisoryId: 'adv1' });
  assert.equal(fil.android.notification.tag, 'advisory-adv1');
  const en = messages.find((m) => m.topic === 'adv_all_en');
  assert.equal(en.notification.title, 'Suspended: Trips suspended');
});

test('long text is truncated to notification limits', () => {
  const long = { ...base, message: { en: 'x'.repeat(500) } };
  const [m] = buildMessages('a', long, []);
  assert.equal(m.notification.body.length, 200);
});
