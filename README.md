# SeeYourTravel

An ASP.NET Web Forms app (runs on Mono/XSP4 in Docker on Linux) that replays travel tracks on a map with photos, places and weather, plus AI photo search and an assistant (Google Gemini + local CLIP).

* Copy `web/Web.config.example` to `web/Web.config` and fill in your own database password, Google client ID and admin emails.
* Copy `.env.example` to `.env` for the SQL, Cloudflare and Gemini keys. Never commit either file.
* See `DEPLOY.md` for running it in Docker.
