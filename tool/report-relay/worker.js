// Problem-report relay (architecture.md section 16.4, proposed 2026-11-12).
//
// Receives a diagnostics-only report from the app and files it as a GitHub
// issue, so a person can report a failure with one tap and no account. It
// stores nothing and never logs the request body. The repository and its
// issues are public, so everything that reaches here is treated as about to
// be published: the app redacts first, and this checks again.
//
// Deployed by hand to a Cloudflare Worker; it is not part of the app build.
// Secrets live in the Worker's settings (GITHUB_TOKEN), never in this repo.

const MAX_BODY_BYTES = 4096;

// Ceilings that need no state of ours: GitHub is asked how many there already
// are. They bound the damage from a flood; they do not tell one sender from
// another (a per-caller limit is the RATE_LIMITER binding, below).
const DEFAULT_MAX_NEW_ISSUES_PER_HOUR = 20;
const MAX_COMMENTS_PER_ISSUE = 40;

const PLATFORMS = ['android', 'ios', 'macos', 'windows', 'linux', 'other'];
const DECODERS = ['hardware', 'software', 'unknown'];
const OUTPUTS = ['direct', 'compatible', 'unknown'];

// Codec, container and version-ish fields: short, boring characters only.
// Anything else is a sign the field holds something that is not a format name.
const TOKEN = /^[A-Za-z0-9 ._+\-\/()]{1,40}$/;
const VERSION = /^\d+\.\d+\.\d+(\+\d+)?$/;

/** Removes what must never be published, in free text. */
export function redact(text) {
  return String(text)
    .replace(/[\u0000-\u001f\u007f]/g, ' ')
    .replace(/https?:\/\/\S+/gi, '<url>')
    .replace(/\b[\w.+-]+@[\w-]+\.[\w.-]+\b/g, '<email>')
    .replace(/\b\d{1,3}(?:\.\d{1,3}){3}\b/g, '<ip>')
    .replace(/\b[0-9a-f]{20,}\b/gi, '<redacted>')
    .replace(/\s+/g, ' ')
    .trim();
}

function text(value, max) {
  if (typeof value !== 'string') return null;
  const cleaned = redact(value).slice(0, max);
  return cleaned.length ? cleaned : null;
}

/**
 * Checks a report against the fixed schema. Returns `{ok: true, report}` with a
 * cleaned copy, or `{ok: false, error}`. Unknown fields are dropped, not
 * passed on.
 */
export function validateReport(input) {
  if (input === null || typeof input !== 'object' || Array.isArray(input)) {
    return { ok: false, error: 'body must be an object' };
  }
  if (input.v !== 1) return { ok: false, error: 'unsupported version' };
  if (typeof input.app_version !== 'string' || !VERSION.test(input.app_version)) {
    return { ok: false, error: 'bad app_version' };
  }
  if (!PLATFORMS.includes(input.platform)) {
    return { ok: false, error: 'bad platform' };
  }
  const error = text(input.error, 300);
  if (!error) return { ok: false, error: 'missing error' };

  const report = {
    v: 1,
    app_version: input.app_version,
    platform: input.platform,
    error,
    decoder: DECODERS.includes(input.decoder) ? input.decoder : 'unknown',
    output: OUTPUTS.includes(input.output) ? input.output : 'unknown',
  };
  for (const key of ['os_version', 'container', 'video_codec', 'audio_codec']) {
    const value = input[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== 'string' || !TOKEN.test(value)) {
      return { ok: false, error: `bad ${key}` };
    }
    report[key] = value;
  }
  if (input.audio_channels !== undefined && input.audio_channels !== null) {
    const n = input.audio_channels;
    if (!Number.isInteger(n) || n < 0 || n > 16) {
      return { ok: false, error: 'bad audio_channels' };
    }
    report.audio_channels = n;
  }
  const note = text(input.note, 500);
  if (note) report.note = note;
  return { ok: true, report };
}

/**
 * A short hash of what makes two reports "the same problem": the error, the
 * formats, the platform and the decoder. App and OS versions are left out so
 * the same failure on two releases still counts as one issue.
 */
export async function fingerprint(report) {
  const parts = [
    report.error,
    report.container,
    report.video_codec,
    report.audio_codec,
    report.platform,
    report.decoder,
    report.output,
  ].map((p) => String(p ?? '').toLowerCase());
  const bytes = new TextEncoder().encode(parts.join('|'));
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return [...new Uint8Array(digest)]
    .slice(0, 8)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function row(label, value) {
  return value === undefined || value === null ? '' : `| ${label} | ${value} |\n`;
}

export function issueBody(report, fp) {
  return (
    '| | |\n|---|---|\n' +
    row('Error', report.error) +
    row('Container', report.container) +
    row('Video codec', report.video_codec) +
    row('Audio codec', report.audio_codec) +
    row('Audio channels', report.audio_channels) +
    row('Decoder', report.decoder) +
    row('Output path', report.output) +
    row('Platform', `${report.platform} ${report.os_version ?? ''}`.trim()) +
    row('App version', report.app_version) +
    (report.note ? `\n**Note from the person:** ${report.note}\n` : '') +
    `\nFingerprint: \`fp-${fp}\`\n\n` +
    '_Filed by the in-app problem report (architecture.md section 16.4). ' +
    'It holds diagnostics only: no title, host, address or account._\n'
  );
}

export function issueTitle(report) {
  const formats = [report.video_codec, report.audio_codec].filter(Boolean).join('/');
  const where = report.container ? ` in ${report.container}` : '';
  return `[report] ${report.error.slice(0, 80)}${formats ? ` (${formats}${where})` : ''}`;
}

function github(env, fetchImpl, path, init = {}) {
  return fetchImpl(`https://api.github.com${path}`, {
    ...init,
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${env.GITHUB_TOKEN}`,
      'User-Agent': 'subnext-report-relay',
      'X-GitHub-Api-Version': '2022-11-28',
      ...(init.headers ?? {}),
    },
  });
}

function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

/**
 * Handles one request. [fetchImpl] is injectable so the logic runs under test
 * without the network.
 */
export async function handle(request, env, fetchImpl = fetch) {
  const url = new URL(request.url);
  if (url.pathname !== '/report') return json(404, { error: 'not found' });
  if (request.method !== 'POST') return json(405, { error: 'POST only' });
  if (!env.GITHUB_TOKEN || !env.REPORT_REPO) {
    return json(500, { error: 'relay not configured' });
  }

  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > MAX_BODY_BYTES) return json(413, { error: 'too large' });

  if (env.RATE_LIMITER) {
    const caller = request.headers.get('cf-connecting-ip') ?? 'unknown';
    const { success } = await env.RATE_LIMITER.limit({ key: caller });
    if (!success) return json(429, { error: 'slow down' });
  }

  const raw = await request.text();
  if (new TextEncoder().encode(raw).length > MAX_BODY_BYTES) {
    return json(413, { error: 'too large' });
  }
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return json(400, { error: 'not json' });
  }
  const checked = validateReport(parsed);
  if (!checked.ok) return json(400, { error: checked.error });
  const report = checked.report;
  const fp = await fingerprint(report);

  // Same problem already open? Add a line to it instead of a new issue, so the
  // issue becomes a count of how many people hit it. GitHub's search index lags
  // by seconds, so two reports at once can still open two issues.
  const q = encodeURIComponent(
    `repo:${env.REPORT_REPO} is:issue is:open label:app-report "fp-${fp}"`,
  );
  const found = await github(env, fetchImpl, `/search/issues?q=${q}&per_page=1`);
  if (found.ok) {
    const data = await found.json();
    const existing = data.items?.[0];
    if (existing) {
      // A popular failure should not turn one issue into thousands of lines.
      // Answered as filed, so a sender cannot tell the cap from success.
      if ((existing.comments ?? 0) >= MAX_COMMENTS_PER_ISSUE) {
        return json(202, { status: 'merged' });
      }
      const comment = await github(
        env,
        fetchImpl,
        `/repos/${env.REPORT_REPO}/issues/${existing.number}/comments`,
        {
          method: 'POST',
          body: JSON.stringify({
            body:
              `Another report: ${[report.platform, report.os_version].filter(Boolean).join(' ')}, ` +
              `app ${report.app_version}.` +
              (report.note ? `\n\n**Note:** ${report.note}` : ''),
          }),
        },
      );
      if (!comment.ok) return json(502, { error: 'could not file' });
      return json(202, { status: 'merged' });
    }
  }

  // A new issue, so check the hourly ceiling first. If GitHub cannot answer,
  // the report is filed anyway: losing a real report costs more than one extra
  // issue, and a GitHub that cannot search will mostly fail to file as well.
  const cap = Number(env.MAX_NEW_ISSUES_PER_HOUR) || DEFAULT_MAX_NEW_ISSUES_PER_HOUR;
  const since = new Date(Date.now() - 3600_000).toISOString().slice(0, 19) + 'Z';
  const recentQ = encodeURIComponent(
    `repo:${env.REPORT_REPO} is:issue label:app-report created:>=${since}`,
  );
  const recent = await github(env, fetchImpl, `/search/issues?q=${recentQ}&per_page=1`);
  if (recent.ok && ((await recent.json()).total_count ?? 0) >= cap) {
    return json(429, { error: 'busy' });
  }

  const created = await github(env, fetchImpl, `/repos/${env.REPORT_REPO}/issues`, {
    method: 'POST',
    body: JSON.stringify({
      title: issueTitle(report),
      body: issueBody(report, fp),
      labels: ['app-report'],
    }),
  });
  if (!created.ok) return json(502, { error: 'could not file' });
  return json(202, { status: 'filed' });
}

export default {
  fetch: (request, env) => handle(request, env),
};
