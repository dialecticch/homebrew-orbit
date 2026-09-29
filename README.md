# Dialectic Orbit — Homebrew tap

Prebuilt binaries for **Dialectic Orbit** (`orbit-mcp`), an MCP server
that gives AI agents governed access to a Gnosis Safe running a
`MakinaXModule` strategy.

This repository contains **no source** — only the Homebrew formulas and the
release artifacts they point at.

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

Linux tarballs (`x86_64-unknown-linux-gnu`) are published with each release and
can be downloaded and unpacked directly. Two things to know before you do:

- they require **glibc ≥ 2.39**, so Ubuntu 22.04 and Debian 12 cannot run them;
- there is **no `aarch64-unknown-linux-gnu` build**.

**Do not install via this tap on Linux or Intel macOS.** The formula will
download the macOS-arm64 tarball and install a binary that cannot run on your
machine — it succeeds and leaves you with something broken rather than
refusing.

The binaries are **not signed or notarized**, so first launch on macOS may need
Gatekeeper approval (System Settings → Privacy & Security).
