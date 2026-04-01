const { getRepo } = require('./lib/repo');

/**
 * Redirects to the APK file. Prefer PUBLIC_APK_URL to avoid any GitHub URL in the browser.
 * Otherwise redirects to GitHub's temporary asset URL (S3) using a server-side token.
 */
module.exports = async function handler(req, res) {
  const publicApkUrl = process.env.PUBLIC_APK_URL;
  if (publicApkUrl) {
    res.setHeader('Location', publicApkUrl);
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="app-release.apk"'
    );
    return res.status(302).end();
  }

  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    return res.status(503).send('GITHUB_TOKEN is not configured on this deployment.');
  }

  const { owner, repo } = getRepo();
  const base = `https://api.github.com/repos/${owner}/${repo}`;

  const relRes = await fetch(`${base}/releases/latest`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  });

  if (!relRes.ok) {
    return res.status(relRes.status).send('Could not load latest release.');
  }

  let release = await relRes.json();
  let apk = (release.assets || []).find((a) => a.name && a.name.endsWith('.apk'));

  if (!apk) {
    const listRes = await fetch(`${base}/releases?per_page=30`, {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    });
    if (listRes.ok) {
      const releases = await listRes.json();
      for (const r of releases) {
        const candidate = (r.assets || []).find(
          (a) => a.name && a.name.endsWith('.apk')
        );
        if (candidate) {
          release = r;
          apk = candidate;
          break;
        }
      }
    }
  }

  if (!apk) {
    return res.status(404).send('No APK asset found on recent releases.');
  }

  const assetUrl = `${base}/releases/assets/${apk.id}`;
  const assetRes = await fetch(assetUrl, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/octet-stream',
    },
    redirect: 'manual',
  });

  const loc = assetRes.headers.get('location');
  if ([301, 302, 307, 308].includes(assetRes.status) && loc) {
    res.setHeader('Location', loc);
    res.setHeader(
      'Content-Disposition',
      'attachment; filename="app-release.apk"'
    );
    return res.status(302).end();
  }

  if (assetRes.status === 200) {
    return res.status(500).send('Unexpected direct body; expected redirect from GitHub.');
  }

  return res.status(502).send('Could not resolve APK download URL from GitHub.');
};
