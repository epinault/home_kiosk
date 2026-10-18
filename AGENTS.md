# AGENTS.md

`home_kiosk` is a personal, single-household wall dashboard. It runs on a Raspberry Pi 3 with the
official 7" touchscreen (`rpi_backlight`). It shows the time, the Seattle weather, the household lunch/dinner menu,
a family photo slideshow, a Dragon Ball image rotator, the WSDOT bridges traffic map, and a
brightness/settings page. Deployment is a **Nerves firmware image**. A Qt WebEngine kiosk browser
(`webengine_kiosk`) boots fullscreen and points at a Phoenix LiveView app served on port 80 of the device.
There is no cloud deploy and no database.

This repo holds **two Mix projects**. Each one has its own `AGENTS.md`. Read the one for the
project you are changing.

| Path | What it is | Detailed guide |
|------|-----------|----------------|
| `dashboard/` | Phoenix 1.5 / LiveView 0.15 app (`:dashboard`, `Dashboard` / `DashboardWeb`). All UI and data fetching lives here. Runs standalone on a laptop. | [`dashboard/AGENTS.md`](dashboard/AGENTS.md) |
| `dashboard_nerves/` | Nerves 1.6 firmware (`:dashboard_nerves`, target `rpi3`, system `kiosk_system_rpi3`). Boots the Pi, sets up WiFi, starts the kiosk browser, and embeds `:dashboard`. | [`dashboard_nerves/AGENTS.md`](dashboard_nerves/AGENTS.md) |

## How the two projects relate

- `dashboard_nerves/mix.exs` depends on the Phoenix app by path, `{:dashboard, path: "../dashboard"}`.
  It also lists `:dashboard` in `extra_applications`. The Phoenix app is compiled **as a dependency** into
  the firmware release. It is not deployed separately.
- **Config from `dashboard/config/*.exs` is NOT loaded in the firmware build** (Mix does not load a
  dependency's config). On the device, the `DashboardWeb.Endpoint` config, `:darkskyx` and
  `:tzdata` all come from `dashboard_nerves/config/rpi3.exs`. That file sets `http: [port: 80]` and `server: true`.
  If you add app config in `dashboard/config/config.exs` that the device needs, mirror it in
  `dashboard_nerves/config/rpi3.exs`.
- **Static assets are not committed.** `dashboard/priv/static/` is gitignored and webpack builds it
  from `dashboard/assets/`. It includes `images.txt`, which `Dashboard.ImageService.StaticList` reads.
  Build the assets (`cd dashboard/assets && npm install && npm run deploy`) before you build firmware.
  If you skip this, the device serves pages with no CSS/JS/images.
- Runtime handshake: `DashboardNerves.NetworkWatcher` subscribes to VintageNet
  `["interface", "wlan0", "connection"]`. On `:internet` it calls `Dashboard.NetworkService.ready!/0`,
  and the browser then navigates to `http://localhost/`. `Dashboard.ImageService` and
  `Dashboard.MenuService` wait for `NetworkService.ready?/0` and retry every 5 s until it is true. On a
  laptop nothing calls `ready!/0`, so those two services retry forever in dev. That is expected.

## Nerves workflow (summary — details in `dashboard_nerves/AGENTS.md`)

Run every command from `dashboard_nerves/`.

```bash
# Host build: no hardware. MIX_TARGET unset == :host (mix.exs preferred_cli_target: run/test -> :host)
mix deps.get
mix test

# Device build: rpi3 is the only target in @all_targets
export MIX_TARGET=rpi3
mix deps.get
mix firmware              # -> _build/rpi3_dev/nerves/images/dashboard_nerves.fw
mix firmware.burn         # write to an SD card
./upload.sh nerves.local  # OTA over SSH (ssh_subsystem_fwup); set MIX_TARGET=rpi3 first, default is rpi0
```

The original author's notes (`dashboard_nerves/README.md`) prefix the target commands with
`QMAKE=/usr/local/opt/qt@5.11/bin/qmake` so that `webengine_kiosk` builds on macOS.

**Agents: never run `mix firmware`, `mix firmware.burn`, or `./upload.sh`.** These commands build cross-compiled
images, write to physical media, or flash a live device. Hand them to the human.

### Which lockfile applies

- `dashboard_nerves/mix.lock` is the **only lockfile Mix reads** for every target (host and rpi3).
  `mix.exs` sets no `lockfile:` option. This lock pins target-only deps (`kiosk_system_rpi3` 1.10.0,
  `nerves_pack`, `vintage_net_wifi`, …) next to the host deps.
- `dashboard_nerves/mix.lock.host` and `mix.lock.rpi3` are **stale 2019 snapshots** (Phoenix 1.3.4 /
  1.4.1, `kiosk_system_rpi3` 1.3.2, `nerves_system_rpi3`). Nothing references them. Do not use them as
  truth. Do not delete them unless the human asks.
- `dashboard/mix.lock` locks the standalone Phoenix app. When the firmware builds, the
  versions come from `dashboard_nerves/mix.lock`. A dep bump in `dashboard/` therefore needs a matching
  `mix deps.update <dep>` in `dashboard_nerves/`. Run it on the host and again with `MIX_TARGET=rpi3`, so target-only
  deps resolve too.
- If you change any `targets:`-scoped dep in `dashboard_nerves/mix.exs`, say so explicitly in your
  summary. List what changed in `mix.lock`, and note that `mix.lock.host` / `mix.lock.rpi3` were left
  untouched (stale).

## CI

`.gitlab-ci.yml` (repo root, image `elixir:latest`) runs **only for `dashboard/`**:
`mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix credo` (not `--strict`),
`mix test`. CI never builds the firmware. Remotes: `gitlab` (git@gitlab.com:Pinault/home_kiosk) and
`origin` (GitHub mirror). GitLab is the primary remote, so use GitLab MRs.

## Repo-wide constraints

- Never commit new secrets. The repo already contains plaintext credentials: WiFi PSKs and a
  Dark Sky API key in `dashboard_nerves/config/rpi3.exs`, a `secret_key_base` in both config trees,
  and a firmware passphrase in `dashboard_nerves/README.md`. Do not copy them into new files,
  docs, logs, or commit messages. Moving them to env vars is welcome, but only when the human asks.
- Never hand-edit any `mix.lock*`. Never commit `_build/`, `deps/`, `assets/node_modules/`,
  `priv/static/`, `erl_crash.dump`, or `.elixir_ls/` (all gitignored).
- Commit messages in history are short imperative sentences ("Adds menu support",
  "Improve code and adds more tests"), with occasional `chore:` prefixes. Keep commits small and scoped to one
  subproject where possible.

## Gotchas

- Toolchain: `dashboard_nerves/.tool-versions` pins `elixir 1.11.2-otp-22` / `erlang 22.3.4.12`.
  Commit 8258115 says OTP 22 is forced because of the kiosk system. `dashboard/` has no
  `.tool-versions` of its own.
- Dark Sky's API was shut down by Apple in 2023. `Dashboard.Weather.Darksky` will only return errors,
  and the weather panel renders empty. Replacing it means implementing `Dashboard.Weather.Retriever`
  and setting `config :dashboard, :weather_retriever, MyModule`.
- `dashboard_nerves/config/config.exs` raises at config load if `~/.ssh/id_ed25519.pub` is missing,
  even for host builds.
