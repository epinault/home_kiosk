# CLAUDE.md

Claude Code guidance for this repository. The canonical agent instructions live in AGENTS.md.

@AGENTS.md

Subproject guides: `dashboard/AGENTS.md` (Phoenix app) and `dashboard_nerves/AGENTS.md` (Nerves
firmware). Read the one for the directory you are editing. There are deliberately no CLAUDE.md files in the
subfolders.

## Plugin Setup

```bash
claude plugin install elixir@claude-code-elixir
claude plugin install superpowers@claude-plugins-official
claude plugin install code-review@claude-plugins-official
```

## Claude-specific notes

- Do not run `mix firmware`, `mix firmware.burn` / `mix burn`, `mix firmware.push`, or
  `dashboard_nerves/upload.sh` through Bash. They cross-compile, write SD cards, or flash a live device.
  Print the command for the human instead.
- Run `mix` commands from inside `dashboard/` or `dashboard_nerves/`. The repo root is not a Mix project.
- Skills to reach for: `superpowers:systematic-debugging` for kiosk/runtime issues,
  `superpowers:test-driven-development` for LiveView changes in `dashboard/`, `code-review` before an MR,
  `update-dependencies` for dep bumps (remember both `dashboard/mix.lock` and `dashboard_nerves/mix.lock`),
  and `mr` for GitLab merge requests (the primary remote is GitLab).
- Never quote the plaintext credentials in `dashboard_nerves/config/rpi3.exs`, the `config.exs` files, or
  `dashboard_nerves/README.md` in responses, commit messages, or new files.
