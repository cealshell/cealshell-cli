# cealshell

A simple package manager for Roblox Studio.

## How it works

Commands are typed into the **Studio command bar**, prefixed with `--c`:

```
--c install signal
```

The leading `--c` makes the line a Lua comment, so the command bar never errors;
the plugin reads the echoed line from the log and runs the command. There's
nothing else to open — just type and go.

## Commands

Run `--c help` for the full list, or `--c manual <command>` for details on any one.

| Command | Aliases | What it does |
| --- | --- | --- |
| `install <pkg>[@ver] …` | `add`, `i` | Install packages (auto-syncs on first use) |
| `remove <pkg> …` | `rm`, `uninstall` | Remove installed packages |
| `list [pattern]` | `ls` | List installed packages |
| `search [query]` | `find` | Search the package catalogue |
| `sync` | `refresh` | Refresh the keyring from all remotes |
| `remote <list\|add\|remove> [url]` | `remotes` | Manage package sources |
| `config <key> [value]` | `cfg` | Get/set a setting |
| `confirm` / `cancel` | `y` / `abort` | Confirm or abort a staged operation |
| `help` / `manual <cmd>` | `?` / `man` | Help |
| `clear` | `cls` | Clear the console |
| `about` | | Credits & contacts |

### Flags

Flags are consistent across commands and can be bundled:

| Flag | Long form | Meaning |
| --- | --- | --- |
| `-s` | `--shared` | Use `ReplicatedStorage` instead of `ServerStorage` |
| `-i` | `--into` | Install into the selected instance (untracked) |
| `-y` | `--yes` | Skip the confirmation prompt |
| `-f` | `--fresh` | (sync) Rebuild the keyring from scratch |
| `-d` | `--debug` | (sync) Verbose per-remote output |

```
--c install global:signal@1.2.0 -sy      # shared + auto-confirm, bundled
--c remove signal --shared --yes
--c sync -fd
```

## Package references

`install` accepts:

- `slug` — e.g. `signal`
- `owner:slug` — e.g. `global:signal`
- either of the above with `@version` — e.g. `global:signal@1.2.0` (defaults to `latest`)

## Remotes & the API

Packages are fetched from configured remotes (default: `https://api.cealshell.dev/`).
The CLI talks to the registry's **API v2** (`/api/v2/packages`), which returns a
consistent envelope:

```json
{ "ok": true, "data": { /* … */ } }
{ "ok": false, "error": { "code": "not_found", "message": "…" } }
```

---

Licensed MIT © janisfox 2026.
