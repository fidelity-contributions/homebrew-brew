# Homebrew Threat Model

Anthropic's OSS Scanner (<https://github.com/anthropics/oss-scanner>) reads this before scanning Homebrew/brew.

Homebrew is a package manager for macOS and Linux.
Its client retrieves package metadata and downloads, verifies their integrity, installs software and updates itself.
A defect in these trusted paths can compromise users' development environments and downstream software supply chains.
This enrolment covers the Homebrew/brew repository, including its checked-in CI and release workflows.
Other Homebrew repositories, hosted infrastructure and third-party packages require separate review; do not claim they were assessed from this checkout.

## Existing project guidance

Use the repository's current `AGENTS.md`, `CLAUDE.md` and any applicable nested `AGENTS.md` files.
`CLAUDE.md` points to `AGENTS.md`; it does not define a separate workflow.
Relevant documents in the checkout are:

- `docs/Homebrew-Security-and-Supply-Chain.md`: integrity checks, signed API metadata, bottle provenance, sandboxing, cask trust and the local account boundary.
- `docs/Tap-Trust.md`: explicit tap and item trust, canonical identities, aliases and renames.
- `docs/Support-Tiers.md`: supported configurations; security reports must affect Tier 1.
- `docs/Formula-Cookbook.md`: build, post-install and test execution, network permissions and credential filtering.
- `docs/Cask-Cookbook.md`: supported cask operations, completion generation and vendor installer exceptions.
- `docs/Responsible-AI-Usage.md` and `CONTRIBUTING.md`: human verification and contribution requirements.

The organisation-wide [security policy](https://github.com/Homebrew/.github/blob/HEAD/SECURITY.md) also applies.
`.oss-scanner/Dockerfile` downloads it to `/opt/homebrew-security-policy.md` for offline reference.
The boundaries below summarise that policy; they are not an expansion of its scope, and that policy takes precedence where they differ.
The supported versions are the latest release and latest commit on the default branch.
Record the exact scanned commit and distinguish development-branch defects from released vulnerabilities.

## Security boundaries and attacker control

Homebrew assumes a single trusted owning account.
The user's account, Homebrew prefix, cache, checkout, configuration, command line and shell environment are trusted.
An attacker who already controls them, an administrator account or a maintainer account is outside this threat model.
Shared multi-user installations are unsupported.

Evaluate attacker-controlled input only where a realistic supported workflow admits it without granting the attacker the authority being claimed as the impact.
Examples include downloaded bytes, archive members and links, remote metadata and redirects, and pull request content consumed by checked-in CI workflows.
For each path, establish the actual checks and trust decisions that precede use.
Do not assume an attacker can replace signed metadata, change a reviewed checksum or choose an official package definition without demonstrating how that becomes possible.

Trusting a third-party tap authorises executable code at the level of trust granted by the user.
Ordinary execution of that code is not a Homebrew vulnerability.
However, Homebrew must not silently promote a third-party source to official status, evaluate an item before required trust is granted, carry trust to a different identity contrary to the documented rules or bypass another documented protection.

Homebrew-managed install, post-install and test execution has intended sandbox and credential-filtering boundaries where those protections apply.
Package-supplied code bypassing those boundaries can be in scope; code executing within the permissions deliberately granted to it is not a bypass.
Use the platform-specific documented policy and actual configuration, rather than assuming every phase has the same permissions.
Vendor cask `installer script:` and macOS `pkg` installers deliberately run outside the cask sandbox and may need elevated privileges.
Do not report their intended access as a sandbox escape.
Once users launch installed upstream software directly, its behaviour is outside Homebrew's security boundary.

## Review priorities

- Bootstrap and update logic present in this repository; download checksums, JWS verification and package or bottle identity binding.
- Redirects, origin changes, tap trust, aliases, renames and migration metadata, particularly paths that cross official and third-party identities.
- Download and extraction paths: archive traversal, links, replacement of verified bytes and unsafe paths that cross an intended boundary.
- Formula and cask installation steps, subprocess execution, environment filtering and platform-specific filesystem, network and IPC sandbox rules.
- Checked-in CI and release workflows: untrusted contributions reaching privileged code, credentials, trusted artefacts or release outputs.
- Vendored code only where the finding is attributable to Homebrew-maintained integration or a Homebrew security boundary; standalone upstream defects belong to the upstream project.

Attestation verification is configuration-dependent; do not assume it is always enabled.
Repository code does not establish the current state of hosted rulesets, secrets, signing keys or runner isolation.
State any external-control assumption explicitly.

## Exclusions and severity

Do not report as Homebrew security vulnerabilities:

- Crafted commands, environment settings or configuration supplied by the user, or prior control of local files, `PATH`, the cache or the checkout.
- Merely installing malicious or vulnerable upstream software, executing an explicitly trusted tap or configuring an attacker-controlled mirror or wrapper.
- Behaviour confined to Tier 2, Tier 3 or unsupported configurations, unless it also affects Tier 1.
- Crashes, hangs or resource exhaustion that only stop the current command or require attacker-controlled local commands, configuration or files.
- Generic dependency alerts, antivirus labels, speculative dangerous APIs or documentation inconsistencies without a demonstrated Homebrew security-boundary violation.

For findings that meet the security policy, justify severity using demonstrated impact and realistic prerequisites.
Report confidence and reproduction status separately from severity.
When runtime reproduction is unavailable, provide a complete source-level proof and explicitly identify what remains unverified; do not present speculation as an established finding.
Do not inflate severity just because Homebrew is widely deployed, an API looks dangerous or arbitrary Ruby execution is possible after trust was deliberately granted.

## Reproduction environment

In the image `.oss-scanner/Dockerfile` builds, `/src` is both the checkout and the default Linux prefix (`/home/linuxbrew/.linuxbrew` is a symlink to it).
Portable Ruby, all developer gem groups and verified signed API metadata are installed during the online build.
The scanner runs as root in its isolated container, but the checkout belongs to the unprivileged `linuxbrew` user.
Run Homebrew commands and tests as that user so permission checks and API behaviour match an ordinary Homebrew owner.
Use `/src` for review, candidate patches and tests so that they operate on the same files.
For focused tests:

```sh
runuser -u linuxbrew -- env HOME=/home/linuxbrew bash -c 'cd /src && ./bin/brew tests --no-parallel --only=api,tap,trust,utils/curl,download_strategies,unpack_strategy,sandbox_operation,sandbox_linux,sandbox_landlock'
```

Use `./bin/brew ruby -- <args>` for Ruby drivers, never the system Ruby.
Use the same `runuser` invocation for other Homebrew commands.
Tests and fixtures are under `Library/Homebrew/test/`; use `./bin/brew tests --only=<path>` for focused reproduction and regression coverage.
Do not use `--online` during the offline audit.
Taps, arbitrary upstream package sources and bottles are not preloaded; use local fixtures for reproductions that must run offline.
The image has no init system, homebrew/core tap, csh, fish, pwsh, tcsh or zsh, so `brew tests` skips specs that need them, and a few untagged specs that need the network fail; neither is a Homebrew defect.
Keep `HOMEBREW_NO_AUTO_UPDATE=1` to retain the scanned revision.

The image supports Linux and platform-independent tests, not macOS runtime verification.
Review macOS code in scope, but label macOS-only reproductions as unexecuted and identify the required macOS follow-up.
Container or VM restrictions may also limit Linux sandbox testing; distinguish a missing kernel capability from a Homebrew defect.
The scanner's root privileges are a test-harness property, not a Homebrew attacker capability.
For privilege or sandbox findings, establish the same boundary violation under the supported unprivileged user configuration; do not infer exploitability from root-only behaviour or disable protections to make a reproducer pass.

For proposed changes, follow the applicable repository agent instructions, keep the fix small and provide a regression that fails before and passes after the fix.
Run `./bin/brew lgtm` as required by `AGENTS.md` and report any checks that cannot run in the offline environment.

## Reports

Send reports privately to the configured security contact.
Do not test against live Homebrew infrastructure or publish findings, issues, pull requests or exploit artefacts.
Each report should contain the scanned commit, exact file and line references, attacker prerequisites, input-to-impact path, violated documented guarantee, safe self-contained reproducer and expected versus observed results.
Include affected platforms and configurations, severity reasoning, the smallest credible patch and regression test, and any unverified assumptions.
Check for an existing test or mitigation before reporting, and group variants of the same root cause instead of sending duplicate reports.
Distinguish observed behaviour, successful exploitation and possible downstream impact.
If a finding only concerns quality or a separate upstream project, label it separately rather than presenting it as a Homebrew vulnerability.
