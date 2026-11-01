# SeeYourTravel

**[seeyourtravel.app](https://seeyourtravel.app)** is a web app for creating, sharing and replaying journeys on a map. Draw or import a route, and the app plays it back with photos, places, weather and the elevation profile along the way. The project started in 2014 as an ASP.NET Web Forms site and now runs on Linux (Mono + SQL Server in Docker).

## What it does
- **Tracks:** draw a route, search two places, import GPX or record your own; replay it with photos flying in, Wikipedia and Google places, weather and elevation.
- **Your library:** My tracks, My photos, My places, with year/month/person filters, people recognition (local face engine) and public/private control.
- **AI search and assistant** (optional): find photos by how they look ("beach at sunset"), tracks and places by a sentence ("churches in Italy", "only the ones near the beach"), and chat with an assistant that sees what is on the screen. Answers come in the language you ask in; voice input and read-aloud are supported.
- Works on phones; English, Ukrainian, German and Hebrew.

## Architecture
| Part | What |
|------|------|
| `web/` | ASP.NET Web Forms app on Mono/XSP4 (EF6, services in `web/services`, front end in `web/js`) |
| `sql` | SQL Server 2022 container, data in `db/mssql-data` |
| `clip` (`tools/clip`) | local CLIP photo search (no LLM runs here) and the Gemini Flash-Lite calls for the assistant, with daily and monthly usage limits |
| `tools/` | import, backup, face scan and photo index scripts |

Everything is defined in [`compose.yaml`](compose.yaml). The public site is published through a Cloudflare tunnel; see [`DEPLOY.md`](DEPLOY.md).

## Run it
```
cp web/Web.config.example web/Web.config    # database password, Google client ID, admin accounts
cp .env.example .env                         # SYT_SA_PASSWORD, optional GEMINI_API_KEY
docker network create syt
make up                                      # or: docker compose up -d      -> http://localhost:8088
```
Without a Google client ID the site runs in local mode (you are signed in as the owner; this is never used for requests that come through a proxy or tunnel).
The AI features need a `GEMINI_API_KEY` in `.env`; without it search falls back to plain word matching.

## Secrets and personal data
`.env`, `web/Web.config`, `db/` and `web/data/` (photos, tracks, the database) are git-ignored and must never be committed.

## License
The code of this project is released under the [MIT License](LICENSE).
Third-party components keep their own licences: the libraries in `web/libs` (jQuery, Leaflet and plugins, Bootstrap and others, see the headers of each file), the "powered by Google" images in `web/img/poweredbygoolge` (Google's terms apply), map tiles from OpenStreetMap contributors (ODbL) and photos or text from Wikipedia and Wikimedia Commons, which are shown with their authors and licences. The Natural Earth country borders in `web/App_Data/countries50.geojson` are public domain.
