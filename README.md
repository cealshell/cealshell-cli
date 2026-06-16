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
| `update [pkg…]` | `up`, `upgrade` | Update packages to their latest version |
| `list [pattern]` | `ls` | List installed packages |
| `search [query]` | `find` | Search the package catalogue |
| `sync` | `refresh` | Refresh the keyring from all remotes |
| `remote <show\|set\|reset> [url]` | `remotes` | Show or change the remote |
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
| `-a` | `--all` | (update) Update both scopes — your whole project |
| `-y` | `--yes` | Skip the confirmation prompt |
| `-f` | `--fresh` | (sync) Rebuild the keyring from scratch |
| `-d` | `--debug` | (sync) Verbose per-remote output |

```
--c install global:signal@1.2.0 -sy      # shared + auto-confirm, bundled
--c remove signal --shared --yes
--c update -a -y                          # update the whole project, no prompt
--c sync -fd
```

## Package references

`install` accepts:

- `slug` — e.g. `signal` (resolved against the synced keyring)
- `owner:slug` — e.g. `global:signal`
- either of the above with `@version` — e.g. `global:signal@1.2.0` (defaults to `latest`)

### On-demand GitHub installs (the proxy)

Any public GitHub repo that ships a `.rbxm` release asset can be installed
without being pre-registered. When an `owner:repo` reference isn't found in the
keyring, the CLI resolves it through the registry's GitHub **proxy**:

```
--c install janisfox:marble          # → github.com/janisfox/marble (latest)
--c install janisfox:marble@1.0.0    # a specific release
```

Behind the scenes this hits `https://api.cealshell.dev/github/janisfox:marble@latest`
(the `/github/` provider prefix is the default, so it can be omitted in the API
path too). Every proxied request is recorded in the central registry, so all
installed/fetched packages are trackable and filterable by provider.

## Requiring packages

Installed packages are exposed through a single `Packages` module at the root of
the scope they were installed into. Index it by package name — modules are
required lazily and cached:

```lua
-- server packages (ServerStorage)
local Packages = require(game.ServerStorage.Packages)
local Signal = Packages.Signal

-- shared packages (ReplicatedStorage), e.g. installed with -s
local Shared = require(game.ReplicatedStorage.Packages)
local Promise = Shared.Promise
```

`Packages.list()` returns the names of everything installed in that scope. (If
your place already has a `Packages` instance, Cealshell uses `CealPackages`
instead; `install` prints the exact require path each time.)

### How installs are tagged

Every installed instance is tagged so it's easy to find and manage:

- a `Cealshell` [CollectionService](https://create.roblox.com/docs/reference/engine/classes/CollectionService) tag, and
- `CealshellPackage`, `CealshellOwner`, `CealshellVersion` attributes.

The registry also records `owner`, `slug`, `version` and `remote` per package,
which is what lets `update` know what's installed and whether a newer version
exists.

## The remote & the API

Packages are fetched from a single remote (default: `https://api.cealshell.dev`).
Change it with `remote set <url>`, inspect it with `remote show`, and restore the
default with `remote reset`.

To override the remote for **one install only**, prefix the reference with a host:

```
--c install cshl.xlch.dev/janisfox:marble    # resolves against https://cshl.xlch.dev
```

A prefix segment is treated as a remote when it looks like a host (a dot, a port,
`localhost`, or an explicit `http(s)://` scheme); otherwise it's read as a provider
(e.g. `github/…`, `codeberg/…`). The override is per-action and is recorded on the
installed package so `update` re-fetches it from the same place.

The CLI talks to the registry's **API v2** (`/api/v2/packages`), which returns a
consistent envelope:

```json
{ "ok": true, "data": { /* … */ } }
{ "ok": false, "error": { "code": "not_found", "message": "…" } }
```

---

Licensed MIT © janisfox 2026.
