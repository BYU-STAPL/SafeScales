const { getRepo } = require('./lib/repo');

/**
 * JSON for the download page: version + download target.
 * If PUBLIC_APK_URL is set, the browser never uses GitHub URLs (host APK on Blob/S3/R2/etc.).
 */
module.exports = async function handler(req, res) {
  res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate=300');

  const publicApkUrl = process.env.PUBLIC_APK_URL;
  if (publicApkUrl) {
    let tagName = process.env.RELEASE_TAG || null;
    const token = process.env.GITHUB_TOKEN;
    if (!tagName && token) {
      const { owner, repo } = getRepo();
      const gh = await fetch(
        `https://api.github.com/repos/${owner}/${repo}/releases/latest`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        }
      );
      if (gh.ok) {
        const data = await gh.json();
        tagName = data.tag_name;
      }
    }
    return res.status(200).json({
      tag_name: tagName || 'Latest',
      direct_download_url: publicApkUrl,
      download_via_proxy: false,
    });
  }

  const token = process.env.GITHUB_TOKEN;
  if (!token) {
    return res.status(501).json({
      error: 'no_token',
      message: 'Set GITHUB_TOKEN in Vercel project settings.',
    });
  }

  const { owner, repo } = getRepo();
  const url = `https://api.github.com/repos/${owner}/${repo}/releases/latest`;

  const gh = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  });

  if (!gh.ok) {
    const text = await gh.text();
    return res.status(gh.status).json({
      error: 'github',
      message: text.slice(0, 200),
    });
  }

  let data = await gh.json();
  let apk = (data.assets || []).find((a) => a.name && a.name.endsWith('.apk'));

  if (!apk) {
    const listRes = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/releases?per_page=30`,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
      }
    );
    if (listRes.ok) {
      const releases = await listRes.json();
      for (const r of releases) {
        const candidate = (r.assets || []).find(
          (a) => a.name && a.name.endsWith('.apk')
        );
        if (candidate) {
          data = r;
          apk = candidate;
          break;
        }
      }
    }
  }

  return res.status(200).json({
    tag_name: data.tag_name,
    download_via_proxy: Boolean(apk),
    apk_name: apk ? apk.name : null,
  });
};
