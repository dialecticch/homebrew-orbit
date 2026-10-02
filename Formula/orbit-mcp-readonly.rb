# Source of truth for the dialecticch/homebrew-orbit formula.
#
# Do NOT hand-edit the version or sha256: run ./sync-tap.sh <tag>, which reads
# the release's SHA256SUMS and rewrites both formulas, then copy them to the
# tap. A hand-maintained checksum is a checksum that silently goes stale --
# this file sat at 0.1.0-rc.1 against a 0.4.0 codebase.
class OrbitMcpReadonly < Formula
  desc "Reporting-only MCP server for Makina-X machines (no signing capability compiled in)"
  homepage "https://github.com/dialecticch/homebrew-orbit"
  version "0.1.0-rc.3"

  # url/sha256 are declared UNCONDITIONALLY. They used to sit inside
  # `if OS.mac? && Hardware::CPU.arm?`, which meant that whenever that
  # expression was false — or could not be EVALUATED — the formula had no url
  # at all, and Homebrew rejected the FORMULA rather than the platform:
  #
  #     Error: dialecticch/orbit/orbit-mcp: formula requires at least a URL
  #
  # A tester hit exactly that: their Homebrew could not parse macOS `26.2` and
  # raised `MacOSVersion::Error` while evaluating the condition. Their broken
  # brew was not our bug; turning it into an error that points at our
  # packaging was. `brew tap` was broken on the stable channel with every
  # version field correct.
  #
  # A conditional may narrow or override what is served. It must never be the
  # only place a url is declared.
  url "https://github.com/dialecticch/homebrew-orbit/releases/download/v#{version}/orbit-mcp-readonly-aarch64-apple-darwin.tar.xz"
  sha256 "f203d13b2b68a52e2eba8c1872808516f1e31bad2d05a1d94bdb36e17aa4535e" # filled by sync-tap.sh from the release's SHA256SUMS

  # NOT ADDED HERE: the release also publishes x86_64 Linux assets, which no
  # formula references. Adding them means teaching sync-tap.sh to fill a SECOND
  # (url, sha256) pair from a different asset name, and widening that fill
  # logic inside a fix that unblocks `brew tap` on the stable channel is the
  # wrong risk to take — a mis-filled checksum fails as a corrupted download.
  # Filed separately; the tap serves macOS today exactly as it did before.

  # NOT `conflicts_with "orbit-mcp"`: that makes Homebrew LOAD the sibling
  # formula while installing this one, and on Homebrew with tap trust a tap
  # trusted only for this formula then refuses the whole install ("Refusing
  # to load formula …/orbit-mcp from untrusted tap"). The same refusal is
  # made in `install` below by looking at the sibling's opt prefix, which
  # never loads its formula.

  # Hard runtime dependency: the documented bootstrap (compose_root ->
  # ensure_integrations) shells out to `git clone/fetch/checkout` for the
  # pinned makina-integrations ref. On a fresh Mac with no Xcode CLT the
  # bare `git` stub pops a GUI installer mid-tool-call; declaring it here
  # makes brew install a real one up front.
  depends_on "git"

  # Refuse a platform this tarball cannot run on — AT INSTALL TIME, and the
  # timing is the whole design. See the long note in `orbit-mcp.rb`: cc-156
  # removed a LOAD-time conditional because a condition that could not be
  # evaluated left the formula with no url and broke `brew tap` itself; the
  # cost was that `brew install` on Linux or Intel started succeeding and
  # installing an unrunnable binary. A formula must LOAD everywhere and need
  # only INSTALL where it works.
  def install
    unless OS.mac? && Hardware::CPU.arm?
      odie <<~EOS
        orbit-mcp-readonly is packaged for macOS on Apple Silicon (arm64) only,
        and this machine is not that. Refusing rather than installing a binary
        that cannot run here.

        Linux x86_64: the release publishes
        `orbit-mcp-readonly-x86_64-unknown-linux-gnu.tar.xz`. Download and
        unpack it directly — it needs glibc 2.39 or newer, so Ubuntu 22.04 and
        Debian 12 will not run it.

        Linux arm64 and Intel macOS: no build is published today.

        Releases: https://github.com/dialecticch/homebrew-orbit/releases
      EOS
    end
    # The artifact carries the DISTINCT name so `tar -tf` says which variant
    # you have without executing it; the installed COMMAND is `orbit-mcp`
    # for both variants, because that is what every skill, the README, and
    # MCP host configs invoke.
    if (HOMEBREW_PREFIX/"opt/orbit-mcp").exist?
      odie <<~EOS
        orbit-mcp is installed, and both install a binary named `orbit-mcp`.
        A machine is read-only or read-write, not both. To switch, run:
          brew uninstall orbit-mcp
        and then install orbit-mcp-readonly again.
      EOS
    end
    bin.install "orbit-mcp-readonly" => "orbit-mcp"
    # One command name: `orbit-mcp` is both what a person types and what an
    # MCP host launches. See `orbit-mcp --help`.
    # The files the product points at, installed so those pointers resolve
    # rather than leading into a private repo.
    pkgshare.install Dir["share/*"]
  end

  def caveats
    <<~EOS
      Read-only build: strictly reporting — no signing capability is compiled
      in, and the server refuses to start if key material is configured.

      Start here:
        orbit-mcp onboard     # where you are and what remains — resumable; on
                            # first run it asks for your Safe and writes the config
        orbit-mcp --help      # every command, incl. `orbit-mcp <tool> [--args…]`

      References:
        #{opt_pkgshare}/skills/orbit-portfolio/SKILL.md
        #{opt_pkgshare}/example.config.toml     # every option, annotated
        #{opt_pkgshare}/package-manifest-schema.md  # the manifest contract

      After `brew upgrade`: restart/reconnect your MCP host — a running
      server keeps serving the OLD build until it is restarted. To catch a
      stale server, compare the health_check tool's `version` (the RUNNING
      image) against `orbit-mcp --version` (what is on disk).

      Set `operator_address` in your [safes.<name>] block — read-only builds
      have no signer to derive it from, and position valuation is
      operator-gated on-chain.
    EOS
  end

  test do
    assert_match "[read-only]", shell_output("#{bin}/orbit-mcp --version")
    assert_match "orbit-mcp onboard", shell_output("#{bin}/orbit-mcp --help")
  end
end
