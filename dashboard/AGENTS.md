# AGENTS.md — dashboard (Phoenix app)

`:dashboard` is the Phoenix LiveView UI for the home kiosk. It is a set of fullscreen pages sized for an
800x480 Raspberry Pi touchscreen, shown by a Qt WebEngine kiosk browser. It has no database, no auth,
and no users. GenServers fetch data from external HTTP APIs, cache it, and LiveViews poll those
GenServers. In production the app is **not deployed on its own**: `../dashboard_nerves` compiles it as a
path dependency into the Nerves firmware (see `../AGENTS.md`). On a laptop it runs as a normal
Phoenix app on port 4000.

## Project Overview

| Item | Value |
|------|-------|
| Elixir (mix.exs) | `~> 1.9`. The toolchain actually used is `elixir 1.11.2-otp-22` / `erlang 22.3.4.12` (`../dashboard_nerves/.tool-versions`) |
| Phoenix | 1.5.7 |
| Phoenix LiveView | 0.15.3 (`.leex` templates, `Phoenix.LiveView.Helpers`; pre-HEEx) |
| phoenix_html / live_dashboard | 2.14.3 / 0.4.0 |
| HTTP client | HTTPoison 1.7.0 (`use HTTPoison.Base`) |
| Time/zones | `calendar` 1.0.0 + `tzdata` 1.0.3, hardcoded zone `America/Los_Angeles` |
| Weather | `darkskyx` 1.0.0 (Dark Sky API — **shut down, see Gotchas**) |
| Mocking | `mockery` 2.3.1 (`mockable/1` macro in lib, `mock/3` in tests) |
| DB | none (no Ecto) |
| Assets | webpack 4 + babel, plain CSS (no Tailwind, no daisyUI), Font Awesome kit from CDN |
| CI | GitLab (`../.gitlab-ci.yml`, runs from this dir) |
| Deploy | embedded in Nerves firmware (`../dashboard_nerves`) |
| Modules | app `Dashboard`, web `DashboardWeb`, endpoint `DashboardWeb.Endpoint`, PubSub `Dashboard.PubSub` |

## Essential Commands

Run all commands from `dashboard/`.

```bash
# Setup
mix deps.get
cd assets && npm install && cd ..        # package.json links phoenix/phoenix_html/phoenix_live_view from ../deps

# Dev
mix phx.server                           # http://localhost:4000, webpack --watch via endpoint watcher
iex -S mix phx.server

# Assets (production bundle -> priv/static, needed before a firmware build)
cd assets && npm run deploy              # webpack --mode production

# Test
mix test
mix test test/dashboard_web/live/index_live_test.exs
mix test test/dashboard_web/live/index_live_test.exs:13

# Quality gate (exactly what CI runs; run all four before committing)
mix compile --warnings-as-errors
mix format --check-formatted
mix credo
mix test
```

There are no mix aliases (no `precommit`, no `setup`). The four commands above are the quality gate.
There is no `.credo.exs`, so credo runs with its defaults, non-strict.

## Architecture

```
lib/
  dashboard.ex                         # empty context namespace
  dashboard/
    application.ex                     # supervision tree (below)
    network_service.ex                 # Dashboard.NetworkService: :pending -> :ready flag, flipped by firmware
    backlight.ex                       # Dashboard.Backlight: writes /sys/class/backlight/rpi_backlight/brightness (0..255)
    weather/
      weather.ex                       # Dashboard.Weather GenServer, refresh every 30 min, Seattle lat/long hardcoded
      retriever.ex                     # @callback retrieve_data/2; impl from :dashboard, :weather_retriever (default Darksky)
      darksky.ex                       # Dashboard.Weather.Darksky: Darkskyx.forecast -> %{daily: [7], hourly: [8]}
    image_service/
      images_service.ex                # Dashboard.ImageService GenServer (one per named instance), rand_image/1
      retriever.ex                     # @callback load_images/1 behaviour
      static_list.ex                   # reads priv/static/images.txt -> https://images.pinault-family.us/<name>
      dynamic_list.ex                  # DuckDuckGo image search by keywords
      duckduckgo_search.ex             # scrapes vqd token then hits /i.js (HTTPoison.Base)
    menu_service.ex                    # Dashboard.MenuService GenServer: today/0, next_five_days/0
    menu.ex                            # Dashboard.Menu: GET https://images.pinault-family.us/menu.json
  dashboard_web.ex                     # :controller/:view/:router/:channel/:live_view quote blocks
  dashboard_web/
    endpoint.ex router.ex
    channels/user_socket.ex
    live/                              # one LiveView per page (below)
    templates/layout/                  # root.html.eex (nav sidebar), app.html.eex, live.html.leex
    templates/page/*_live.html.leex    # one template per LiveView, rendered via PageView
    views/                             # PageView (date_to_dayname/1), LayoutView (active_class/2), ErrorView, ErrorHelpers
test/
  test_helper.exs                      # ExUnit.start() only
  support/conn_case.ex channel_case.ex # no DataCase (no DB)
  dashboard_web/live/*_live_test.exs   # one test file per LiveView
  dashboard_web/views/*_test.exs
assets/  js/app.js (LiveSocket), css/app.css (all styling), static/ (svg weather icons, images.txt), webpack.config.js
```

### Supervision tree (`Dashboard.Application`, `:one_for_one`)

1. `{Phoenix.PubSub, name: Dashboard.PubSub}`
2. `DashboardWeb.Endpoint`
3. `Dashboard.NetworkService`
4. `Dashboard.Backlight`
5. `Dashboard.Weather`
6. `{Dashboard.ImageService, name: Dashboard.PersonalImages, retriever: StaticList}`
7. `{Dashboard.ImageService, name: Dashboard.GokuImages, retriever: DynamicList, keywords: "dragon ball"}`
8. `Dashboard.MenuService`

`ImageService.child_spec/1` uses `:name` as the child id, which is why two instances can coexist. The
services load data in `handle_continue/2`. Image and menu services check `NetworkService.ready?/0`
and schedule `:retry` after 5 s when it is false.

### Routes / LiveViews (`DashboardWeb.Router`, `:browser` pipeline)

| Path | Module | Data source | Refresh |
|------|--------|-------------|---------|
| `/` | `IndexLive` | `Weather.retrieve/0`, `MenuService.today/0`, WSDOT gif | clock 1 s, menu 30 min (weather timer has no handler) |
| `/slideshow` | `SlideshowLive` | `ImageService.rand_image(PersonalImages)` | 30 s |
| `/menu` | `MenuLive` | `MenuService.next_five_days/0` | 10 min |
| `/dragonball` | `DragonballLive` | `ImageService.rand_image(GokuImages)` | 30 s |
| `/traffic` | `MapLive` | `images.wsdot.wa.gov/nwflow/flowmaps/bridges.gif?<ts>` | 60 s |
| `/settings` | `SettingsLive` | `Backlight`; `phx-change="config-changed"` maps 1..100 -> 15..255 | event |
| `/dashboard` | `live_dashboard` | Phoenix LiveDashboard | — |

The PubSub server exists but nothing broadcasts. LiveViews poll with `Process.send_after/3`.
External integrations: Dark Sky, DuckDuckGo (scraped), `images.pinault-family.us` (personal photos and
`menu.json`), WSDOT traffic map, and the Font Awesome kit script in `root.html.eex`.

## Conventions

- Formatting: `.formatter.exs` has `import_deps: [:phoenix]` and default line length 98. Existing code
  writes parenthesised plug/router calls (`plug(:accepts, ["html"])`, `live("/", IndexLive)`). Keep
  that style in those files.
- LiveViews `use Phoenix.LiveView` **directly** (not `use DashboardWeb, :live_view`) and render with
  `Phoenix.View.render(DashboardWeb.PageView, "<name>_live.html", assigns)`. A new page needs
  `lib/dashboard_web/live/<name>_live.ex`, `templates/page/<name>_live.html.leex`, a `live/2` route,
  a nav link in `templates/layout/root.html.eex`, and `test/dashboard_web/live/<name>_live_test.exs`.
- Every module has a `@moduledoc` (`@moduledoc false` for LiveViews/Application). `@spec` is not used.
  Behaviours declare `@callback` and implementations use `@behaviour`.
- External data goes behind a behaviour (`Weather.Retriever`, `ImageService.Retriever`) and a caching
  GenServer, so failures keep the last good state and only log. Keep that shape: LiveViews never call
  HTTP directly.
- HTTP clients are `use HTTPoison.Base` modules with `process_request_url/1` prefixing a `@base_url`.
  They return `{:ok, _} | {:error, _}` and chain with `with`.
- Timezone is the literal `"America/Los_Angeles"` everywhere. Location is hardcoded Seattle.
- CSS is hand-written in `assets/css/app.css`, with a dark theme (`#000` background). Class names are
  BEM-ish (`weather-box`, `full-image-wrapper`), and tests select on them. Do not introduce
  Tailwind/daisyUI.

## Testing

- Only LiveView and view tests exist. They use `DashboardWeb.ConnCase` + `Phoenix.LiveViewTest`
  (`live/2`, `has_element?/2`, `render/1`). Nothing is `async: true` except the empty view tests.
- Tests run against the **real application tree**: the GenServers start with the app. Tests do not
  assert on fetched data, only on page structure (CSS selectors and static text).
- Isolate service calls with Mockery. In lib, wrap the call as `mockable(Dashboard.ImageService).rand_image(...)`
  (requires `import Mockery.Macro`). In the test, call `mock(ImageService, :rand_image, "myimgurl")` and
  `assert_called(ImageService, :rand_image)`:

```elixir
test "renders the slideshow page", %{conn: conn} do
  mock(ImageService, :rand_image, "myimgurl")
  {:ok, view, _} = live(conn, "/slideshow")
  assert has_element?(view, "img[class*=full-image]")
  assert_called(ImageService, :rand_image)
end
```

- To swap the weather backend in tests, set `config :dashboard, :weather_retriever, Mod` in
  `config/test.exs` (not done today). No ExMachina, Mox, or coverage tool.
- Do not add `Process.sleep` to wait for GenServers. Mock the public function or call it directly.

## Elixir / Phoenix Guidelines (for these versions)

- This is **Phoenix 1.5 / LiveView 0.15**. Use `.leex` templates with `<%= %>`, `Routes.live_path/2`,
  `live_redirect`/`live_patch` helpers, and `Phoenix.View` views. There is no HEEx, `~H`, `<.link>`, function
  components, `Layouts.app`, `current_scope`, streams, or `Phoenix.Component`. Do not apply
  Phoenix 1.7/1.8 patterns here.
- Config uses `use Mix.Config` (`config/*.exs`), and prod reads `SECRET_KEY_BASE`/`PORT` in
  `config/prod.secret.exs`. There is no `runtime.exs`.
- Variables rebound inside `case`/`if` do not leak out. Return the new state from the expression
  (`state = case ... do {:ok, d} -> Map.merge(state, d); _ -> state end`).
- Prefer pattern matching and `with`, and return tagged tuples. Use `@impl true` on GenServer callbacks in new
  code (existing modules omit it). Never call `String.to_atom/1` on params. `SettingsLive` already does
  `String.to_integer(params["brightness"])`, so guard or validate input in new handlers.
- Keep HTTP on HTTPoison for consistency unless the human approves adding `Req`. Don't add a second
  HTTP client casually: the dep must also cross-compile into the firmware.
- Let GenServers crash on programmer errors. Rescue or tolerate only external-fetch failures (current pattern).
- Anything touching hardware (`Backlight`) must no-op on a laptop. Follow `File.exists?(@brightness_file)`.

## Workflow for Agents

1. Read the LiveView, its template, and the GenServer it reads from. Check `../dashboard_nerves/config/rpi3.exs`
   if the change involves config.
2. Add or adjust the LiveView test (selector-based, Mockery for service calls).
3. Implement.
4. Run the quality gate: `mix compile --warnings-as-errors && mix format --check-formatted && mix credo && mix test`.
5. If you added or bumped a dep, it must also resolve in `../dashboard_nerves/mix.lock`. Tell the human
   so they can run `mix deps.get` there (host and `MIX_TARGET=rpi3`).
6. Commit with a short imperative message, matching history. The remote is GitLab, so use GitLab MRs.

## Constraints — Never Do

- Never bypass CI checks or use `--no-verify`. Never hand-edit `mix.lock`.
- Never commit `priv/static/` (built output, gitignored), `assets/node_modules/`, or `erl_crash.dump`.
- Never copy the hardcoded secrets (`secret_key_base`, Dark Sky `api_key` in `config/config.exs`) into
  new places. Never add new secrets to config. Read new ones with `System.get_env/1`.
- Don't add Ecto, auth, or a DB. Don't add a dep without considering cross-compilation for the rpi3 target.
- Don't commit `IO.inspect`/`IEx.pry`.
- Don't remove `Dashboard.NetworkService.ready!/0`. The firmware (`DashboardNerves.NetworkWatcher`) calls it.
- Don't rename `Dashboard.PubSub`, `DashboardWeb.Endpoint`, or `DashboardWeb.ErrorView`. The device config in
  `../dashboard_nerves/config/rpi3.exs` references them.

## Gotchas

- **Dark Sky is dead** (Apple shut the API down in 2023). `Darkskyx.forecast/2` fails, so the home page
  weather is empty. Replace it by writing a new `Dashboard.Weather.Retriever` implementation.
- **`Dashboard.Weather` never stores fetched data.** In `handle_continue/2` and `handle_info/2`,
  `state = Map.merge(state, data)` is rebound inside `case`, and the outer `state` is returned unchanged.
  This is a real bug, and it also produces "unused variable" warnings that `--warnings-as-errors` may flag.
- `IndexLive` schedules `:update_weather`, but its `handle_info` clause is commented out. On a connected
  socket, after 30 min the message raises a `FunctionClauseError` and the LiveView crashes and remounts.
- `DragonballLive` aliases a nonexistent `Dashboard.ImageSearchService` (unused alias).
  `dashboard_web.ex`'s `view_helpers/0` imports a nonexistent `DashboardWeb.Gettext` (gettext is not a dep).
  That compiles today only because no module calls `use DashboardWeb, :live_view` / `:live_component`.
- On a laptop, `NetworkService` stays `:pending`, so photo/menu services log "Not connected yet" every 5 s.
  Run `Dashboard.NetworkService.ready!()` in IEx to unblock them.
- `StaticList` reads `priv/static/images.txt`, which exists only after webpack copies `assets/static/`.
  Run `npm run deploy` or the dev watcher first.
- Several functions have unused params (`session`, `index`, `time`), so watch warnings when touching them.
- `root.html.eex` calls `window.app.poweroff()` for the power button. Nothing in this repo defines it,
  so it is presumably expected from the kiosk browser environment (unverified).
- `assets/assets/package-lock.json` is a stray tracked file. `deps/`, `_build/`, and `.elixir_ls/` exist locally.

## Key Files

| Path | Why |
|------|-----|
| `mix.exs` | deps (no aliases) |
| `lib/dashboard/application.ex` | supervision tree, ImageService instances |
| `lib/dashboard_web/router.ex` | all routes |
| `lib/dashboard_web/live/index_live.ex` | home page, the most complex LiveView |
| `lib/dashboard_web/templates/page/index_live.html.leex` | home page markup and selectors tests rely on |
| `lib/dashboard_web/templates/layout/root.html.eex` | nav sidebar, Font Awesome, power button |
| `lib/dashboard/weather/weather.ex` + `retriever.ex` | weather cache + pluggable backend |
| `lib/dashboard/image_service/images_service.ex` | generic cached image rotator |
| `lib/dashboard/network_service.ex` | readiness flag shared with firmware |
| `lib/dashboard/backlight.ex` | hardware brightness control |
| `config/config.exs`, `config/dev.exs` | endpoint + darkskyx config (host only) |
| `../dashboard_nerves/config/rpi3.exs` | the config this app actually gets on the device |
| `test/dashboard_web/live/slideshow_live_test.exs` | reference test with Mockery |
| `assets/css/app.css`, `assets/webpack.config.js` | styling and asset pipeline |
| `../.gitlab-ci.yml` | the CI gate |
