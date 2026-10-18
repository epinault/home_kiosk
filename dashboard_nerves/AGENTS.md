# AGENTS.md — dashboard_nerves (Nerves firmware)

`:dashboard_nerves` is the Nerves firmware for the home kiosk. It targets a Raspberry Pi 3 with a touchscreen.
On boot it brings up WiFi via VintageNet and starts a fullscreen Qt WebEngine browser
(`webengine_kiosk`, on the `kiosk_system_rpi3` Nerves system). It also starts the `:dashboard` Phoenix
app (`../dashboard`, path dep) on port 80, and points the browser at `http://localhost/` once the
network has internet. Its own code is small: one Application module and one GenServer. Most changes
are config, deps, or the network/browser glue.

## Project Overview

| Item | Value |
|------|-------|
| Elixir / OTP | `.tool-versions`: `elixir 1.11.2-otp-22`, `erlang 22.3.4.12` (OTP 22 is required by the kiosk system, per commit 8258115) |
| Nerves | `nerves` 1.6.3, `nerves_bootstrap ~> 1.6` archive, `shoehorn` 0.7.0 |
| Targets | `@all_targets [:rpi3]` + `:host` |
| Nerves system | `kiosk_system_rpi3` 1.10.0 (`~> 1.8`, `targets: :rpi3`). Qt WebEngine built in |
| Networking | `nerves_pack` 0.4.1 -> `vintage_net` 0.9.2, `vintage_net_wifi` 0.9.1, `mdns_lite` 0.6.6, `nerves_ssh` 0.2.1, `ssh_subsystem_fwup` 0.5.1 |
| Browser | `webengine_kiosk` 0.3.0 |
| Logging | `ring_logger` (console backend removed) |
| Embedded app | `{:dashboard, path: "../dashboard"}` (Phoenix 1.5.7 / LiveView 0.15) |
| CI | none for this project (root `.gitlab-ci.yml` only covers `dashboard/`) |
| Modules | `DashboardNerves.Application`, `DashboardNerves.NetworkWatcher`, `DashboardNerves` (hello-world stub) |

## Essential Commands

Run all commands from `dashboard_nerves/`.

```bash
# Setup (host)
mix archive.install hex nerves_bootstrap     # once per machine
mix deps.get

# Test / dev on host (MIX_TARGET unset => :host; preferred_cli_target forces run/test to :host)
mix test
mix test test/some_test.exs:12               # no tests exist yet; test/ has only test_helper.exs
mix format --check-formatted

# Device (HUMAN ONLY — agents must not run these)
export MIX_TARGET=rpi3
QMAKE=/usr/local/opt/qt@5.11/bin/qmake mix deps.get     # QMAKE needed on the author's macOS for webengine_kiosk
QMAKE=/usr/local/opt/qt@5.11/bin/qmake mix firmware     # -> _build/rpi3_dev/nerves/images/dashboard_nerves.fw
mix firmware.burn                                       # write to SD card
./upload.sh nerves.local                                # OTA update over SSH (see below)

# Remote shell / debugging on the device
ssh nerves.local                    # IEx over nerves_ssh, key = ~/.ssh/id_ed25519.pub baked in at build
#   RingLogger.attach / RingLogger.tail   (hint printed by rootfs_overlay/etc/iex.exs)
#   QtWebEngine remote debugging: port 9222 locally, socat-forwarded to 9223 on the device
```

No mix aliases are defined except `loadconfig: [&bootstrap/1]`. That alias starts `nerves_bootstrap`,
which in turn injects the `firmware*` tasks when `MIX_TARGET` is set.

**Agents never run `mix firmware`, `mix firmware.burn`, `mix burn`, `mix firmware.push`, or
`./upload.sh`.** Validate changes with `mix compile` / `mix test` on host. Then tell the human which
target command to run.

## Targets, env vars and config

| Var | Effect |
|-----|--------|
| `MIX_TARGET` | unset/`host` -> laptop build. `rpi3` -> firmware build with `targets: @all_targets` deps + `kiosk_system_rpi3`. `_build/` holds `dev/` and `rpi3_dev/` |
| `MIX_ENV` | `dev` by default. `prod` enables `strip_beams` and `start_permanent` |
| `QMAKE` | path to a Qt 5.11 `qmake` for building `webengine_kiosk` on the dev machine |
| `QTWEBENGINE_CHROMIUM_FLAGS`, `QTWEBENGINE_REMOTE_DEBUGGING` | set at runtime by `platform_init/1` (`--disable-gpu`, `9222`) |

Config load order (`config/config.exs`):

1. `config.exs` sets: `rootfs_overlay`, shoehorn `init: [:nerves_runtime, :nerves_pack, :vintage_net]`,
   RingLogger, `nerves_ssh authorized_keys` read from **`~/.ssh/id_ed25519.pub` (raises if missing)**,
   and `mdns_lite` (advertises `nerves.local` + hostname, ssh/sftp/epmd).
2. `target.exs` is imported when target != host. It only configures `:nerves_init_gadget`, which is **no longer a
   dep** (replaced by `nerves_pack`), so the file is dead config.
3. `#{Mix.target()}.exs` is either `host.exs` (windowed 800x480 kiosk, homepage google.com) or `rpi3.exs`.

`config/rpi3.exs` carries everything the device needs:
- `:webengine_kiosk`: uid/gid `kiosk`, `data_dir: "/root/kiosk"`, homepage `http://nerves.local`.
- **WiFi**: `config :vintage_net, regulatory_domain: "US", config: [{"wlan0", %{type: VintageNetWiFi,
  vintage_net_wifi: %{networks: [...]}, ipv4: %{method: :dhcp}}}]`. Two WPA-PSK networks with
  priorities. The old `:nerves_network` block (pre-VintageNet) is left commented out. Ignore it, and do not
  revive `NERVES_NETWORK`-style config, because `nerves_network` is not a dep anymore.
- `DashboardWeb.Endpoint` for the embedded Phoenix app: `http: [port: 80]`, `server: true`,
  `code_reloader: false`, `check_origin: false`. The `:dashboard` app's own `config/*.exs` is not loaded in this
  build, so this file is the device config for the Phoenix app.
- `:darkskyx` api key and `:tzdata` `data_dir: "/root/tzdata"` (writable partition).

WiFi credentials, the Dark Sky key, and `secret_key_base` are **plaintext in `rpi3.exs`**. Do not echo
them into docs, logs, or commits. If asked to change WiFi, edit only the `networks:` list.

## Architecture

```
mix.exs                    # targets, deps, release (cookie "dashboard_nerves_cookie", Nerves.Release steps)
mix.lock                   # THE lockfile for host + rpi3
mix.lock.host, mix.lock.rpi3  # stale 2019 snapshots, unused (see Lockfiles)
config/                    # config.exs, host.exs, rpi3.exs, target.exs (above)
lib/dashboard_nerves.ex    # generated hello/0 stub
lib/dashboard_nerves/application.ex      # supervision tree + platform_init
lib/dashboard_nerves/network_watcher.ex  # VintageNet -> Dashboard.NetworkService.ready!/0 + browser nav
rel/vm.args.eex            # -setcookie, -mode embedded, -heart (30 s), shell history, --dot-iex /etc/iex.exs
rootfs_overlay/etc/iex.exs # copied into the root filesystem; loaded by every IEx session on device
upload.sh                  # OTA firmware push over SSH
test/test_helper.exs       # ExUnit.start(); no tests
```

**Supervision tree** (`DashboardNerves.Supervisor`, `:one_for_one`):
1. `{WebengineKiosk, {Application.get_all_env(:webengine_kiosk), [name: Display]}}`, always started.
2. `children(@target)`: for non-host targets that is `DashboardNerves.NetworkWatcher`.

`platform_init/1` (non-host) runs `udevd` + `udevadm trigger/settle`, sets the QtWebEngine env vars,
and starts `MuonTrap.Daemon` running `socat tcp-listen:9223,fork tcp:localhost:9222` for remote
devtools.

**NetworkWatcher** subscribes to `["interface", "wlan0", "connection"]`. On `:internet` it calls
`Dashboard.NetworkService.ready!()` and `WebengineKiosk.go_to_url(Display, "http://localhost/")`.
On any other value it only logs.

**rootfs_overlay/** is merged over the Nerves system's root filesystem at `mix firmware`
(`config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"`). Today it holds only `/etc/iex.exs`
(`use Nerves.Runtime.Helpers` + RingLogger hint). A syntax or runtime error in that file can crash the VM and
reboot the device. Put files the device needs at fixed paths here, e.g. `/etc/...`.

### How upload.sh works

`./upload.sh [destination] [path/to/file.fw]` takes these defaults: destination `nerves.local`, `MIX_TARGET=rpi0` (**not
rpi3, so export `MIX_TARGET=rpi3` or pass the .fw path**), and `MIX_ENV=dev`. It finds the first `.fw` in
`_build/${MIX_TARGET}_${MIX_ENV}/nerves/images` and falls back to the older Nerves 1.4 layouts. It prints
the `fwup -m` metadata, which needs `fwup` installed on the host. On macOS it resolves the IP via `arp` and binds
ssh to a 169.254 link-local interface if needed. It then runs
`cat file.fw | ssh -s -o PreferredAuthentications=publickey <dest> fwup`, which is the `ssh_subsystem_fwup`
subsystem on port 22. The device applies the update and reboots. The header comment still mentions
`nerves_firmware_ssh` on port 8989; that is outdated, because the actual command uses the SSH subsystem.

## Lockfiles

- Mix reads only **`mix.lock`**, for every target (no `lockfile:` option in `mix.exs`).
- `mix.lock.host` / `mix.lock.rpi3` date from Dec 2019 (Phoenix 1.3.4/1.4.1, `kiosk_system_rpi3` 1.3.2)
  and are unreferenced. Leave them alone unless the human says to remove them.
- To change a `targets:`-scoped dep, edit `mix.exs`, then the human runs `mix deps.get` both
  with and without `MIX_TARGET=rpi3`, so `mix.lock` contains both sets. In your summary, state which
  deps are target-scoped, that `mix.lock` changed, and that `mix.lock.host` / `mix.lock.rpi3`
  were not updated.
- `:dashboard`'s transitive deps (phoenix, live_view, httpoison, calendar, darkskyx, …) are locked here
  too, and must stay compatible with `../dashboard/mix.lock`.

## Conventions

- `.formatter.exs` has default inputs and no `import_deps`. Run `mix format`.
- `use Mix.Config` style config (pre-`import Config`).
- Target-specific behaviour is chosen at compile time from `@target Mix.target()`, plus target-specific
  config files. Keep hardware-only code out of the host path.
- Logging goes through `Logger`, collected by RingLogger. There is no console output on device.

## Testing

There are no tests. `mix test` runs on host only (`preferred_cli_target`). If you add tests, keep them
host-safe: no VintageNet, WebengineKiosk, or `/sys` access. The realistic check for this project is
`mix compile` on host, followed by a human-run firmware build.

## Elixir / Nerves Guidelines

- `Mix.target()` returns an **atom** (`:host`, `:rpi3`). Match on atoms, never strings (see Gotchas).
- Never block in `Application.start/2` or `init/1`. On a device, a crash loop combined with `-heart` means a reboot loop.
  Use `handle_continue` or `send_after`.
- Use VintageNet subscriptions (`VintageNet.subscribe/1`) for network state. Don't poll.
- Shell out with `MuonTrap` (supervised) rather than bare `System.cmd`/`:os.cmd` for long-running
  processes.
- Prefer `@impl true` on callbacks in new code. Use tagged tuples, and `with` over nested `case`.

## Workflow for Agents

1. Decide which project the change belongs to. UI and data go in `../dashboard`. Boot, network, browser,
   and device config go here.
2. Make the change, then run `mix format` and `mix compile` on host (no `MIX_TARGET`).
3. Do not build, burn, or upload firmware. In the hand-off, list the exact commands the human
   should run (`MIX_TARGET=rpi3 mix deps.get && mix firmware && ./upload.sh nerves.local`).
4. Flag any `mix.exs` dep change and its lockfile impact (see Lockfiles).
5. Commit with a short imperative message. The primary remote is GitLab.

## Constraints — Never Do

- Never run `mix firmware`, `mix firmware.burn`/`mix burn`, `mix firmware.push`, or `./upload.sh`.
- Never change a `targets:` dep or `kiosk_system_rpi3` version without noting the impact on
  `mix.lock` and the stale `mix.lock.host` / `mix.lock.rpi3`.
- Never hand-edit any `mix.lock*`.
- Never bump OTP/Elixir in `.tool-versions` independently of `kiosk_system_rpi3`. The system pins the OTP
  the firmware runs.
- Never commit or copy WiFi PSKs, API keys, the firmware passphrase in `README.md`, or SSH keys.
- Never put risky code in `rootfs_overlay/etc/iex.exs`.
- Don't remove the `{:dashboard, path: "../dashboard"}` dep or `:dashboard` from `extra_applications`.

## Gotchas

- **`application.ex` matches `"host"` (string), but `@target` is an atom.** As a result, `children("host")` and
  `platform_init("host")` never match. On host, the code runs `udevd`, starts socat, and starts
  `NetworkWatcher` (VintageNet is not a host dep), so host `mix run` is likely broken. Fixing it means
  changing the clauses to `:host`.
- `README.md` documents `mix firmware.push`. That task came from `nerves_firmware_ssh`, which is no longer a dep. Use
  `upload.sh` (human only). The README also contains a plaintext passphrase.
- `upload.sh` defaults `MIX_TARGET` to `rpi0`.
- `config/config.exs` raises at load time if `~/.ssh/id_ed25519.pub` doesn't exist, even for host builds.
- `config/target.exs` configures `nerves_init_gadget`, which is not installed. It is harmless but misleading.
- `rpi3.exs` endpoint config uses the Phoenix 1.4 `pubsub: [name:, adapter: PG2]` key, while Phoenix 1.5
  (`../dashboard/config/config.exs`) uses `pubsub_server: Dashboard.PubSub`. The device endpoint may lack
  `pubsub_server`. Verify this before relying on PubSub-backed features on device.
- The browser starts on `http://nerves.local` and is redirected to `http://localhost/` only when
  `wlan0` reports `:internet`. Without internet, the kiosk stays on the initial page.
- Firmware must include the built assets: run `npm run deploy` in `../dashboard/assets` before
  `mix firmware`, because `priv/static` is gitignored.

## Key Files

| Path | Why |
|------|-----|
| `mix.exs` | targets, deps (incl. `../dashboard`), release config |
| `config/config.exs` | shoehorn, ssh keys, mdns, config import order |
| `config/rpi3.exs` | WiFi, kiosk browser, device Phoenix endpoint, darksky, tzdata |
| `config/host.exs` | host kiosk window settings |
| `lib/dashboard_nerves/application.ex` | supervision tree, udev/QtWebEngine init |
| `lib/dashboard_nerves/network_watcher.ex` | network-ready handshake with `:dashboard` |
| `rel/vm.args.eex` | VM flags, heart, cookie |
| `rootfs_overlay/etc/iex.exs` | on-device IEx init |
| `upload.sh` | OTA update script |
| `mix.lock` | the real lockfile |
| `../dashboard/lib/dashboard/network_service.ex` | the other side of the readiness handshake |
| `../AGENTS.md` | how the two projects fit together |
