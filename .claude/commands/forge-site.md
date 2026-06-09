---
name: forge-site
description: Create a new Laravel Forge site end-to-end — site, git repo, PostgreSQL DB, .env, deploy, Cloudflare DNS, and SSL
argument-hint: "<spec — fill in the template below, or just: server, domain, repo, branch, db name, A-record IP>"
---

# /forge-site — Create a New Forge Site (end-to-end)

Provision a new Laravel Forge site using the **laravel-forge-agent** with the **laravel-forge** skill.

Spec: $ARGUMENTS

## Input Template

```
- Server:            <e.g. acodax-axispro-new-01>
- Domain:            <e.g. xyz.acodax.com>
- Frontend pkg mgr:  <None | npm | yarn | pnpm | bun>     (default: None)
- PHP version:       <e.g. 8.4 | match sibling site>      (default: match sibling)
- Isolated user:     <no | yes>                            (default: no)

Git:
- Repo:    <https://github.com/org/repo>
- Branch:  <branch-name>

Database (PostgreSQL):
- DB name:   <live_db_dms_xxx>
- DB user:   <forge (default password) | new user + password>   (default: forge)

DNS (Cloudflare):
- A record IP:  <usually the server IP>
- Proxy:        <enabled | disabled>                       (default: enabled)

After setup:
- Deploy now?    <yes | no>                                (default: yes)
- Issue SSL?     <yes (Let's Encrypt) | no>                (default: yes)
```

Required minimum: **server, domain, repo, branch, DB name, A-record IP**. Apply the defaults above for anything omitted and state which defaults were chosen.

## Workflow

1. **Discover & guard against duplicates**
   - Resolve the server ID from its name; capture its IP, PHP version, `database_type`.
   - List existing sites and databases. If the site / DB / DNS record already exists, **reuse it** — do not create a duplicate; report it as already present.
   - Find a sibling site on the same repo/server and read its config + deploy script to mirror conventions.

2. **Create the site** — `project_type: php`, `directory: /public`, PHP/isolation per spec or sibling. Wait for `status: installed`.

3. **Install the git repo** — provider `github`, the given repo + branch. Wait for `repository_status: installed`.

4. **Database** — if the named DB doesn't exist, create it. With DB user = `forge`, reuse the existing forge superuser (its default password is already in the Forge-provisioned `.env`); no new user needed.

5. **Configure `.env`** — set `DB_CONNECTION=pgsql` (or per DB type), `DB_DATABASE=<name>`, `DB_USERNAME`, `DB_PASSWORD`. Verify the values after writing.

6. **APP_KEY (do not skip)** — Forge provisions an empty `APP_KEY`. Run `php artisan key:generate --force`, then `php artisan optimize` to rebuild the config cache with the new key. Verify `APP_KEY` is set.

7. **Deploy script** — mirror the sibling: `composer install --no-dev --optimize-autoloader`, migrations, optimize. Add npm build steps **only** if a frontend package manager was specified (None → no frontend steps). The git-install `composer:false` flag drops the composer line — re-add it.

8. **Deploy** (if requested) — trigger deploy, poll to completion, read the deploy log, confirm migrations ran and `Deployment complete`.

9. **Cloudflare DNS** (if not already present) — create an A record `domain → IP` with the requested proxy setting, via the Cloudflare API (`CLOUDFLARE_API_TOKEN`). Look up the zone ID from the apex domain.

10. **SSL (if requested) — get the challenge path right BEFORE issuing**
    - Confirm DNS resolves to the server and port 80 is reachable.
    - Ensure the nginx config has a `location /.well-known/acme-challenge { alias /home/forge/.letsencrypt; }` block. Legacy ID-based sites can be missing it — if so, add it (via the Forge nginx API, which runs `nginx -t` + reload as root) and verify a probe token is served publicly first.
    - Request the Let's Encrypt cert (apex + `www`), poll until `installed`, then **activate** it.
    - After securing, verify: `http://` → `https://` redirect, apex 200 with a trusted cert, and `www` → apex over HTTPS. Confirm the ACME path is still served over HTTP so auto-renewal works.

## Changing an existing site's branch (DESTRUCTIVE — follow exactly)

If the request is to **change the deploy branch** of an existing site (not create one), do NOT treat it as a simple update. `POST .../git` re-clones the repo, which **wipes `vendor/` and resets `.env`** (empties `APP_KEY`, sets `DB_DATABASE=forge`). Skipping the steps below takes the live site down with a 500 (`No application encryption key`) and runs migrations against the wrong `forge` database. See the `laravel-forge` skill §4b.

1. **Verify the target branch exists**: `git ls-remote --heads <repo> <branch>`.
2. **Back up `.env` first**: `cp /home/forge/<domain>/.env /tmp/<domain>.env.bak` (and keep a copy via the env API).
3. **Change the branch** with `POST .../git` — pass `{provider, repository, branch}` **without** `composer:false`. Poll until `repository_status: installed`.
4. **Restore `.env`** from the backup (Forge will have reset it) — confirm `APP_KEY` and `DB_DATABASE` are the real values, not `forge`/empty.
5. **Ensure the deploy script** still has `composer install` (re-add if missing), then **deploy**.
6. **Rebuild config cache**: `php artisan optimize:clear && php artisan optimize` — verify cached `app.key` is non-empty and DB is the correct tenant DB.
7. **Migrate the correct DB**: `php artisan migrate:status` then `migrate --force` against the tenant DB (e.g. `live_db_dms_*`), mindful of branch schema divergence — never the default `forge` db.
8. **Verify**: 0 pending migrations, live URL returns 200.

## Credentials & Tools

- Forge API token: `~/.laravel-forge/config.json` (`.token`). Base URL `https://forge.laravel.com/api/v1`. Read it without printing it.
- Forge CLI is installed (`forge`) and authenticated.
- Cloudflare: `CLOUDFLARE_API_TOKEN` (and `CLOUDFLARE_ACCOUNT_ID`) in the environment.
- Server SSH for diagnostics: key `~/.ssh/id_forge_server` (note: the `forge` user has no passwordless sudo — apply nginx changes via the Forge API, which runs as root).

## Output

Report what was **created** vs **already existed**, the site/DB IDs, the deploy result, the DNS record, and the final SSL verification table.

## Usage

```
/forge-site "server: acodax-axispro-new-01, domain: nypd.acodax.com, repo: https://github.com/org/repo, branch: main, db: live_db_dms_nypd, A-record IP: 13.207.105.133, proxy: enabled, deploy: yes, ssl: yes"
```
