# Source of truth for the dialecticch/homebrew-orbit formula.
#
# Do NOT hand-edit the url version or sha256: run ./sync-tap.sh <tag>, which
# reads the release's SHA256SUMS and rewrites both formulas, then copy them
# to the tap. The version lives in the url (strict audit: a separate
# `version` line is redundant), and sync-tap.sh refuses a url that does not
# name the tag.
class OrbitMcpReadonly < Formula
  desc "Reporting-only MCP server for Makina-X machines (no signing code)"
  homepage "https://github.com/dialecticch/homebrew-orbit"
  # url/sha256 are declared unconditionally: a url that exists only inside a
  # conditional leaves the formula with no url when it cannot be evaluated, and
  # `brew tap` rejects the formula. A conditional may narrow or override what is
  # served but must never be the only place a url is declared.
  url "https://github.com/dialecticch/homebrew-orbit/releases/download/v0.1.9/orbit-mcp-readonly-aarch64-apple-darwin.tar.xz"
  sha256 "943b0f761b36bfba71ffa769f5339a74ab6dcec69689268102e01facbe4798d3" # sync-tap.sh # sync-tap.sh
  license "BUSL-1.1"

  # The x86_64 Linux release assets are not referenced here; supporting them
  # needs sync-tap.sh to fill a second (url, sha256) pair from another asset name.

  # No `conflicts_with "orbit-mcp"`: it makes Homebrew load the sibling formula,
  # which a tap trusted only for this formula refuses ("Refusing to load formula
  # …/orbit-mcp from untrusted tap"). `install` below checks the sibling's opt
  # prefix instead, which never loads its formula.

  # Hard runtime dependency: the bootstrap (compose_root -> ensure_integrations)
  # shells out to `git clone/fetch/checkout`; declaring it avoids the GUI
  # installer stub on a Mac without Xcode CLT.
  depends_on "git"

  # Refuse a platform this tarball cannot run on at install time, not load time:
  # a formula must load everywhere (`brew tap`, `brew search`) and only needs to
  # install where it works. See `orbit-mcp.rb`.
  def install
    supported = OS.mac? && Hardware::CPU.arm?
    unless supported
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
    # The artifact carries a distinct name so `tar -tf` shows the variant; the
    # installed command is `orbit-mcp` for both variants.
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

      Orbit serves its guides through the connection (the get_guide tool);
      replace any copied orbit-* skills with the stubs it returns.

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
