# Source of truth for the dialecticch/homebrew-orbit formula.
#
# Do NOT hand-edit the version or sha256: run ./sync-tap.sh <tag>, which reads
# the release's SHA256SUMS and rewrites both formulas, then copy them to the
# tap. A hand-maintained checksum is a checksum that silently goes stale --
# this file sat at 0.1.0-rc.1 against a 0.4.0 codebase.
class OrbitMcp < Formula
  desc "Mandate-governed MCP server for Makina-X machines (read-write build)"
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
  url "https://github.com/dialecticch/homebrew-orbit/releases/download/v#{version}/orbit-mcp-aarch64-apple-darwin.tar.xz"
  sha256 "bc1b922ca9f922fb11ffab65cb4d91bc5f81436476b9f4dc5fb9f5d945159785" # filled by sync-tap.sh from the release's SHA256SUMS

  # NOT ADDED HERE: the release also publishes x86_64 Linux assets, which no
  # formula references. Adding them means teaching sync-tap.sh to fill a SECOND
  # (url, sha256) pair from a different asset name, and widening that fill
  # logic inside a fix that unblocks `brew tap` on the stable channel is the
  # wrong risk to take — a mis-filled checksum fails as a corrupted download.
  # Filed separately; the tap serves macOS today exactly as it did before.

  # NOT `conflicts_with "orbit-mcp-readonly"`: that makes Homebrew LOAD the sibling
  # formula while installing this one, and on Homebrew with tap trust a tap
  # trusted only for this formula then refuses the whole install ("Refusing
  # to load formula …/orbit-mcp-readonly from untrusted tap"). The same refusal is
  # made in `install` below by looking at the sibling's opt prefix, which
  # never loads its formula.

  # Hard runtime dependency: the documented bootstrap (compose_root ->
  # ensure_integrations) shells out to `git clone/fetch/checkout` for the
  # pinned makina-integrations ref. On a fresh Mac with no Xcode CLT the
  # bare `git` stub pops a GUI installer mid-tool-call; declaring it here
  # makes brew install a real one up front.
  depends_on "git"

  # Refuse a platform this tarball cannot run on — AT INSTALL TIME, and the
  # timing is the whole design.
  #
  # cc-156 removed a load-time conditional (`if OS.mac? && Hardware::CPU.arm?`
  # around url/sha256) because a condition that could not be EVALUATED left the
  # formula with no url and Homebrew rejected the FORMULA rather than the
  # platform — `brew tap` broken on the stable channel with every version field
  # correct. That fix was right and stands: url/sha256 stay unconditional above.
  #
  # Its consequence was this: `brew install` on Linux or Intel began DOWNLOADING
  # the darwin-arm64 tarball and installing a binary that cannot execute. It
  # used to refuse. A refusal is a bad experience; a successful install of a
  # binary that cannot run is a bug report from someone who believes they
  # installed the product.
  #
  # So the refusal moves to where it belongs. A formula must LOAD everywhere —
  # that is what `brew tap`, `brew search` and every dependency walk need — and
  # need only INSTALL where it works. `install` runs on one machine, at a moment
  # when a raised error is the correct outcome anyway, so a check here cannot
  # break tapping the way a class-level one did.
  #
  # NOT SOLVED HERE, deliberately: the release does publish an x86_64 Linux
  # tarball, but it requires glibc >= 2.39 (read from `.gnu.version_r`, not
  # guessed), so Ubuntu 22.04 and Debian 12 cannot run it, and there is no
  # aarch64-linux build at all. Pointing the formula at it would re-create this
  # very defect on every older Linux — "installs something that cannot run",
  # one platform over. Naming the tarball and its floor lets a reader decide;
  # installing it for them would not.
  def install
    unless OS.mac? && Hardware::CPU.arm?
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
      server keeps serving the old build until it is restarted. Then reload
      the bundled skills, and refresh any host skills you copied separately.
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
