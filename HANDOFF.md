# HANDOFF

Remaining human steps (the project never blocks on these):

1. **Add a remote first.** This repo currently has no `origin` (local only, no off-device backup). Create a **public** GitHub repo (default name `hundred-block`), `git remote add origin <url>`, `git push -u origin main`.
2. Settings -> Pages -> Source: **GitHub Actions**. Confirm the first deploy and open the URL.
3. Replace the Ko-fi placeholder URL in `lib/config.dart` (added in Phase 4).
4. Test on a real Windows tablet and Android tablet (procedure added in Phase 5).
5. Confirm assumptions in Plan.md Appendix D (licence, app name, scoring constants).

## Blockers / BLOCKED items
None yet.

## Deploy (HUMAN)
`.github/workflows/pages.yml` builds with `BASE_HREF=/<repo-name>/` and deploys on push to `main`. After creating the public repo and pushing: Settings -> Pages -> Source: GitHub Actions.

## Real-tablet map performance (HUMAN)
Headless software-GL numbers are only indicative. On the tablet: open the Pages URL, play a round, pan and pinch-zoom continuously for 30 s and note whether it feels smooth (target: no visible stutter). Report device model, browser and version.

## Licence check (HUMAN, before public launch)
Address records for Burbank carry the Overture licence string `LicenseRef-Proprietary`, while Overture's attribution page says Los Angeles County addresses are CC0. See `DATA_LICENSES.md` ("Open question"). Confirm, or replace the address source.
