# Source of truth for the dialecticch/homebrew-orbit formula.
#
# Do NOT hand-edit the url version or sha256: run ./sync-tap.sh <tag>, which
# reads the release's SHA256SUMS and rewrites both formulas, then copy them
# to the tap. The version lives in the url (strict audit: a separate
# `version` line is redundant), and sync-tap.sh refuses a url that does not
# name the tag.
class OrbitMcp < Formula
  desc "Mandate-governed MCP server for Makina-X machines (read-write build)"
  homepage "https://github.com/dialecticch/homebrew-orbit"
  # url/sha256 are declared unconditionally: a url that exists only inside a
  # conditional leaves the formula with no url when it cannot be evaluated, and
  # `brew tap` rejects the formula. A conditional may narrow or override what is
  # served but must never be the only place a url is declared.
  url "https://github.com/dialecticch/homebrew-orbit/releases/download/v0.1.11/orbit-mcp-aarch64-apple-darwin.tar.xz"
  sha256 "aae452271ec4f1702c1c55aca2227959768b57086032f2139c2e6d8633aee8dc" # sync-tap.sh # sync-tap.sh
  license "BUSL-1.1"

  # The x86_64 Linux release assets are not referenced here; supporting them
  # needs sync-tap.sh to fill a second (url, sha256) pair from another asset name.

  # No `conflicts_with "orbit-mcp-readonly"`: it makes Homebrew load the sibling
  # formula, which a tap trusted only for this formula refuses ("Refusing to load
  # formula …/orbit-mcp-readonly from untrusted tap"). `install` below checks the
  # sibling's opt prefix instead, which never loads its formula.

  # Hard runtime dependency: the bootstrap (compose_root -> ensure_integrations)
  # shells out to `git clone/fetch/checkout`; declaring it avoids the GUI
  # installer stub on a Mac without Xcode CLT.
  depends_on "git"

  # Refuse a platform this tarball cannot run on at install time, not load time:
  # a formula must load everywhere (`brew tap`, `brew search`, dependency walks)
  # and only needs to install where it works. A load-time conditional around
  # url/sha256 would leave the formula with no url when it cannot be evaluated.
  #
  # The x86_64 Linux tarball is not used: it requires glibc >= 2.39 (so Ubuntu
  # 22.04 and Debian 12 cannot run it) and there is no aarch64-linux build.
  def install
    supported = OS.mac? && Hardware::CPU.arm?
    unless supported
      odie <<~EOS
        orbit-mcp is packaged for macOS on Apple Silicon (arm64) only, and this
        machine is not that. Refusing rather than installing a binary that cannot
        run here.

        Linux x86_64: the release publishes
        `orbit-mcp-x86_64-unknown-linux-gnu.tar.xz`. Download and unpack it
        directly — it needs glibc 2.39 or newer, so Ubuntu 22.04 and Debian 12
        will not run it.

        Linux arm64 and Intel macOS: no build is published today.

        Releases: https://github.com/dialecticch/homebrew-orbit/releases
      EOS
    end
    if (HOMEBREW_PREFIX/"opt/orbit-mcp-readonly").exist?
      odie <<~EOS
        orbit-mcp-readonly is installed, and both install a binary named `orbit-mcp`.
        A machine is read-only or read-write, not both. To switch, run:
          brew uninstall orbit-mcp-readonly
        and then install orbit-mcp again.
      EOS
    end
    bin.install "orbit-mcp"
    bin.install "orbit-watchdog"
    # One command name: `orbit-mcp` is both what a person types and what an
    # MCP host launches. See `orbit-mcp --help`.
    # The files the product points at, installed so those pointers resolve.
    # `example.config.toml` is cited by the config `init` writes, the skills
    # by these caveats, `watchdog.example.toml` by the onboarding skill.
    # Without them the references lead into a private repo.
    pkgshare.install Dir["share/*"]
    bin.install_symlink pkgshare/"base-anvil/orbit-base-anvil" => "orbit-base-anvil"
  end

  def caveats
    <<~EOS
      Write build: Base simulation uses the bundled orbit-base-anvil.
      Ethereum and HyperEVM still require stock foundry (anvil). Execution
      requires a signer and a mandate. Also installs orbit-watchdog —
      the independent loss circuit breaker (separate guardian key; run it on
      a different host when you can).

      Start here:
        orbit-mcp --version   # verify [read-write]
        orbit-mcp init        # initialize configuration
        orbit-mcp onboard     # resume setup and choose wizard or chat

      Register #{opt_bin}/orbit-mcp with your MCP host and connect it.
      The connected process serves the owner page. Do not start a second
      server. For CLI-only wizard use, run `orbit-mcp owner-serve` in your own
      terminal and leave it in the foreground. It holds the state lock.
      Obtain the page link with `orbit-mcp owner-url --wait` in your terminal;
      open it locally and keep the bearer link out of chat and captured logs.
      If host policy denies a command, use its approval flow or run the
      supported command yourself; do not retry it through another tool.

      References:
        #{opt_pkgshare}/skills/orbit-onboarding/SKILL.md
        #{opt_pkgshare}/example.config.toml     # every option, annotated
        #{opt_pkgshare}/package-manifest-schema.md  # the manifest contract
        #{opt_pkgshare}/watchdog.example.toml   # circuit-breaker config

      After `brew upgrade`, restart or reconnect your MCP host. A running
      server keeps serving the old build until it is restarted. Orbit
      serves its guides through the connection (the get_guide tool); replace
      any copied orbit-* skills with the stubs it returns.
      To catch a stale server, compare the health_check tool's `version`
      (the running build) with `orbit-mcp --version` (what is on disk).

      A newly provisioned Safe has NO instruction root, and that is normal —
      one cannot exist before you compose it. Orbit boots "unrooted" and
      offers the path out: install a package, compose_root, then the Safe
      OWNER signs setAllowedInstrRoot.

      Reporting-only? Run `brew uninstall orbit-mcp` first, then install
      dialecticch/orbit/orbit-mcp-readonly.
    EOS
  end

  test do
    assert_match "[read-write]", shell_output("#{bin}/orbit-mcp --version")
    # The documented entry point exists under the documented name.
    assert_match "orbit-mcp onboard", shell_output("#{bin}/orbit-mcp --help")
  end
end
