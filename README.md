# Dialectic Orbit — Homebrew tap

Prebuilt binaries for **Dialectic Orbit** (`orbit-mcp`), an MCP server
that gives AI agents governed access to a Gnosis Safe running a
`MakinaXModule` strategy.

This repository contains **no source** — only the Homebrew formulas and the
release artifacts they point at.

## For testers

1. **Install** the read-write build with the two commands under
   [Install](#install) below. Already installed? Update instead:

   ```sh
   brew update
   brew upgrade orbit-mcp
   ```

2. **Nothing to copy.** Orbit serves its guides to your agent through the
   connection. If you copied Orbit's skills for an earlier version, ask the
   agent to replace them with Orbit's stubs (its `get_guide` tool returns them).

3. **Register Orbit in Claude Code**, once, for every folder you work in:

   ```sh
   claude mcp add --scope user orbit -- orbit-mcp
   ```

4. **Start.** Open Claude Code and say "Set up Dialectic Orbit". The agent
   walks you through the rest and asks before anything costs money.

Report issues in the internal channel you were invited from, with the steps,
a screenshot and the output of `orbit-mcp --version`. Never share keys, seed
phrases or Safe owner keys; nobody will ask for them.

## Install

```sh
brew trust --formula dialecticch/orbit/orbit-mcp   # Homebrew with tap trust only
brew install dialecticch/orbit/orbit-mcp
```

Reporting only, with signing code compiled out rather than disabled:

```sh
brew trust --formula dialecticch/orbit/orbit-mcp-readonly   # Homebrew with tap trust only
brew install dialecticch/orbit/orbit-mcp-readonly
```

On older Homebrew without `trust`, skip the trust line. Trusting one formula is
enough: neither formula makes Homebrew load the other.

The two cannot both be installed — they install the same binary name. Pick
one; installing one over the other stops and says how to switch.

## First run

```sh
orbit-mcp onboard
```

That is the starting point: it walks the whole flow, asks for your Safe, and
tells you who must act next at every step. The individual commands below exist
for when you already know what you want.

```sh
orbit-mcp --version     # variant + version + commit
orbit-mcp --help        # every command
```

**One name, one binary.** `orbit-mcp` is what a person types and what an MCP
host launches, so `orbit-mcp onboard` and the MCP registration refer to the
same program.

## Verifying what you downloaded

Every release publishes `SHA256SUMS`, and `BUILD-INFO` naming the source commit
the binaries were built from:

```sh
shasum -a 256 -c SHA256SUMS
```

Homebrew already checks the formula's own `sha256` on install; the above is for
anyone fetching a tarball directly.

## Updating

```sh
orbit-mcp self-update              # latest release
orbit-mcp self-update --tag vX.Y.Z # a specific one
orbit-mcp self-update --rollback   # restore the previous binary
```

It downloads from this repository over plain HTTPS — no GitHub account, no
`gh`, no credentials. It verifies the checksum and the staged binary's reported
version before swapping anything, keeps the previous binary as `*.prev`, and
**never compiles**.

## Platforms

**This tap serves macOS arm64 (Apple Silicon).** That is what `brew install`
here installs and the only target it can install correctly.

Linux x86_64 installs from the release page, not this tap. First check your
glibc (the tarballs need **glibc 2.39 or newer**; Ubuntu 22.04 and Debian 12
are too old):

```sh
ldd --version | head -1
```

Then download, verify and unpack into a directory of its own:

```sh
TAG=v0.1.1   # the release you want
mkdir -p ~/orbit && cd ~/orbit
curl -fLO "https://github.com/dialecticch/homebrew-orbit/releases/download/${TAG}/orbit-mcp-x86_64-unknown-linux-gnu.tar.xz"
curl -fLO "https://github.com/dialecticch/homebrew-orbit/releases/download/${TAG}/SHA256SUMS"
grep orbit-mcp-x86_64-unknown-linux-gnu.tar.xz SHA256SUMS | sha256sum -c -
tar -xJf orbit-mcp-x86_64-unknown-linux-gnu.tar.xz
~/orbit/orbit-mcp --version
```

Register `~/orbit/orbit-mcp` (the full path) with your agent app, for example
`claude mcp add --scope user orbit -- ~/orbit/orbit-mcp`. The write tarball
includes the simulators Orbit needs (Base Anvil and a pinned stock anvil), so
Foundry is not required. There is **no `aarch64-unknown-linux-gnu` build**.

**Do not install via this tap on Linux or Intel macOS.** The formula stops
there with a message rather than installing a binary that cannot run on your
machine, and says what is available for your machine.

The binaries are **not signed or notarized**, so first launch on macOS may need
Gatekeeper approval (System Settings → Privacy & Security).

## Troubleshooting

**`brew install` stops making progress.** Homebrew 7.0.8 can hang while
downloading in parallel. Orbit's download is fine. Stop it with Ctrl-C and run:

```sh
HOMEBREW_DOWNLOAD_CONCURRENCY=1 HOMEBREW_NO_AUTO_UPDATE=1 brew install dialecticch/orbit/orbit-mcp
```

For the reporting-only build, use `dialecticch/orbit/orbit-mcp-readonly` instead.
