# Contributing

Thank you for helping. Small, focused pull requests are easiest to review.

## Run it locally
See the [README](README.md#run-it). For changes to the website, `tools/test_site.sh start` starts a test copy on http://127.0.0.1:8089 where everybody is the administrator and the database is the same as the main site's, so use a database copy for experiments.

## Before you open a pull request
- The CI jobs must pass: lint, the website build and start-up check, gitleaks, Trivy and CodeQL.
- Keep text for people in the translation files (`web/locales/<language>/translation.json`), and add a key to all languages (English is the reference; CI warns about missing keys).
- Never commit `.env`, `web/Web.config`, photos, tracks, database files or backups. `.gitignore` covers them, but check `git status` before `git add`.
- Describe the change and why it is needed in the commit message.

## Security problems
Do not open a public issue. See [SECURITY.md](SECURITY.md).

## Conduct
Be kind and assume good intent. Harassment and personal attacks are not welcome; maintainers may remove comments and block accounts that do this. Reports: info@seeyourtravel.app.
