/**
 * Resolves owner/repo for GitHub API calls.
 * Prefer env vars set in Vercel (Git integration or manual).
 */
function getRepo() {
  const full = process.env.GITHUB_REPOSITORY;
  if (full && full.includes('/')) {
    const [owner, repo] = full.split('/');
    return { owner, repo };
  }
  const owner =
    process.env.GITHUB_REPO_OWNER ||
    process.env.VERCEL_GIT_REPO_OWNER ||
    'BYU-STAPL';
  const repo =
    process.env.GITHUB_REPO_NAME ||
    process.env.VERCEL_GIT_REPO_SLUG ||
    'SafeScales';
  return { owner, repo };
}

module.exports = { getRepo };
