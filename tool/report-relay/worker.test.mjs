// Run with: node --test tool/report-relay/worker.test.mjs
// A fake GitHub stands in for the network. What is pinned here is the part that
// matters for a public repository: nothing identifying gets through, and a
// repeat of the same problem becomes a comment, not a second issue.
import test from 'node:test';
import assert from 'node:assert/strict';
import { handle, redact, validateReport, fingerprint } from './worker.js';

const env = { GITHUB_TOKEN: 't', REPORT_REPO: 'owner/repo' };

// The Pixel report that motivated this (MANUAL_TESTING.md section 4).
const good = {
  v: 1,
  app_version: '1.0.8+1',
  platform: 'android',
  os_version: '17',
  error: 'Error decoding audio.',
  container: 'avi',
  video_codec: 'mpeg4',
  audio_codec: 'ac3',
  audio_channels: 6,
  decoder: 'hardware',
  output: 'direct',
};

function request(body, { method = 'POST', path = '/report', headers = {} } = {}) {
  return new Request(`https://relay.example${path}`, {
    method,
    headers: { 'content-type': 'application/json', ...headers },
    body: method === 'GET' ? undefined : JSON.stringify(body),
  });
}

/** A fake GitHub. `open` is the issue the search will find, if any. */
function fakeGithub({
  open = null,
  comments = 0,
  recentIssues = 0,
  failCreate = false,
} = {}) {
  const calls = [];
  const fetchImpl = async (url, init = {}) => {
    calls.push({ url: String(url), init });
    if (String(url).includes('/search/issues')) {
      // The hourly-ceiling search carries a created: qualifier; the duplicate
      // search carries the fingerprint.
      if (decodeURIComponent(String(url)).includes('created:>=')) {
        return new Response(JSON.stringify({ total_count: recentIssues, items: [] }));
      }
      return new Response(
        JSON.stringify({ items: open ? [{ number: open, comments }] : [] }),
      );
    }
    if (String(url).endsWith('/comments')) return new Response('{}', { status: 201 });
    if (failCreate) return new Response('{}', { status: 500 });
    return new Response('{}', { status: 201 });
  };
  return { calls, fetchImpl };
}

test('a good report files an issue with the app-report label', async () => {
  const gh = fakeGithub();
  const res = await handle(request(good), env, gh.fetchImpl);
  assert.equal(res.status, 202);
  assert.equal((await res.json()).status, 'filed');
  const create = gh.calls.find((c) => c.url.endsWith('/issues'));
  const sent = JSON.parse(create.init.body);
  assert.deepEqual(sent.labels, ['app-report']);
  assert.match(sent.title, /Error decoding audio/);
  assert.match(sent.body, /\| Container \| avi \|/);
  assert.match(sent.body, /Fingerprint: `fp-[0-9a-f]{16}`/);
});

test('the same problem again becomes a comment, not a new issue', async () => {
  const gh = fakeGithub({ open: 42 });
  const res = await handle(request(good), env, gh.fetchImpl);
  assert.equal((await res.json()).status, 'merged');
  assert.ok(gh.calls.some((c) => c.url.endsWith('/issues/42/comments')));
  // No stray space when there is no OS version (seen on the real relay).
  const comment = gh.calls.find((c) => c.url.endsWith('/issues/42/comments'));
  assert.match(JSON.parse(comment.init.body).body, /^Another report: android 17, app 1\.0\.8\+1\.$/);
  assert.ok(!gh.calls.some((c) => c.init.method === 'POST' && c.url.endsWith('/issues')));
});

test('a flood of new problems stops at the hourly ceiling', async () => {
  const gh = fakeGithub({ recentIssues: 20 });
  const res = await handle(request(good), env, gh.fetchImpl);
  assert.equal(res.status, 429);
  assert.ok(!gh.calls.some((c) => c.init.method === 'POST'), 'nothing filed');
  // The ceiling is configurable, and one under it still files.
  const under = fakeGithub({ recentIssues: 19 });
  assert.equal((await handle(request(good), env, under.fetchImpl)).status, 202);
  const tight = fakeGithub({ recentIssues: 3 });
  const res2 = await handle(request(good), { ...env, MAX_NEW_ISSUES_PER_HOUR: '3' }, tight.fetchImpl);
  assert.equal(res2.status, 429);
});

test('an issue that already has many comments stops growing, quietly', async () => {
  const gh = fakeGithub({ open: 42, comments: 40 });
  const res = await handle(request(good), env, gh.fetchImpl);
  assert.equal(res.status, 202);
  assert.equal((await res.json()).status, 'merged', 'looks like success to a sender');
  assert.ok(!gh.calls.some((c) => c.url.endsWith('/comments')));
  const below = fakeGithub({ open: 42, comments: 39 });
  await handle(request(good), env, below.fetchImpl);
  assert.ok(below.calls.some((c) => c.url.endsWith('/comments')));
});

test('the fingerprint ignores app and OS version but not the codecs', async () => {
  const a = await fingerprint(validateReport(good).report);
  const b = await fingerprint(
    validateReport({ ...good, app_version: '1.0.9', os_version: '16' }).report,
  );
  const c = await fingerprint(validateReport({ ...good, audio_codec: 'dts' }).report);
  assert.equal(a, b);
  assert.notEqual(a, c);
});

test('addresses, links, emails and long tokens never reach the issue', async () => {
  const gh = fakeGithub();
  const dirty = {
    ...good,
    error: 'Failed to open https://panel.example:8080/movie/1.mkv?token=abc',
    note: 'my server is 192.168.1.20, mail me at a@b.co, key deadbeefdeadbeefdeadbeef',
  };
  await handle(request(dirty), env, gh.fetchImpl);
  const create = gh.calls.find((c) => c.url.endsWith('/issues'));
  const body = create.init.body;
  for (const leaked of ['panel.example', '192.168.1.20', 'a@b.co', 'deadbeef', 'token=abc']) {
    assert.ok(!body.includes(leaked), `leaked: ${leaked}`);
  }
  assert.match(body, /<url>/);
});

test('free-form values in format fields are rejected, not cleaned', () => {
  for (const field of ['container', 'video_codec', 'audio_codec', 'os_version']) {
    const r = validateReport({ ...good, [field]: 'My Movie Title (2014) at home' + 'x'.repeat(50) });
    assert.equal(r.ok, false, field);
  }
});

test('off-schema reports are refused', () => {
  assert.equal(validateReport(null).ok, false);
  assert.equal(validateReport([]).ok, false);
  assert.equal(validateReport({ ...good, v: 2 }).ok, false);
  assert.equal(validateReport({ ...good, platform: 'plan9' }).ok, false);
  assert.equal(validateReport({ ...good, app_version: 'latest' }).ok, false);
  assert.equal(validateReport({ ...good, error: '' }).ok, false);
  assert.equal(validateReport({ ...good, audio_channels: 99 }).ok, false);
});

test('unknown fields are dropped, not passed on', () => {
  const r = validateReport({ ...good, title: 'Secret Film', server: 'nas' });
  assert.equal(r.ok, true);
  assert.ok(!('title' in r.report) && !('server' in r.report));
});

test('wrong method, wrong path, bad json and big bodies', async () => {
  const gh = fakeGithub();
  assert.equal((await handle(request(good, { method: 'GET' }), env, gh.fetchImpl)).status, 405);
  assert.equal((await handle(request(good, { path: '/x' }), env, gh.fetchImpl)).status, 404);
  const bad = new Request('https://relay.example/report', { method: 'POST', body: '{nope' });
  assert.equal((await handle(bad, env, gh.fetchImpl)).status, 400);
  const big = request({ ...good, note: 'a'.repeat(9000) });
  assert.equal((await handle(big, env, gh.fetchImpl)).status, 413);
  assert.equal(gh.calls.length, 0);
});

test('a rate-limited caller is refused before anything is filed', async () => {
  const gh = fakeGithub();
  const limited = { ...env, RATE_LIMITER: { limit: async () => ({ success: false }) } };
  assert.equal((await handle(request(good), limited, gh.fetchImpl)).status, 429);
  assert.equal(gh.calls.length, 0);
});

test('an unconfigured relay says so, and a GitHub failure is a 502', async () => {
  assert.equal((await handle(request(good), {}, fakeGithub().fetchImpl)).status, 500);
  const gh = fakeGithub({ failCreate: true });
  assert.equal((await handle(request(good), env, gh.fetchImpl)).status, 502);
});

test('redact keeps format names readable', () => {
  assert.equal(redact('Error decoding audio.'), 'Error decoding audio.');
});
