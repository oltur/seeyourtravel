# Security policy

## Reporting a vulnerability
Please do not open a public issue for a security problem. Use GitHub's **Report a vulnerability** button (Security tab) or write to info@seeyourtravel.app. You will get an answer within a few days.

## What is in scope
The code in this repository and the site https://seeyourtravel.app. Please do not test with other people's accounts or data.

## Secrets
The repository must never contain keys, passwords, `.env`, `web/Web.config`, photos, tracks or database files. A CI job (gitleaks) checks every push; if you find a secret in the history, report it as above.
