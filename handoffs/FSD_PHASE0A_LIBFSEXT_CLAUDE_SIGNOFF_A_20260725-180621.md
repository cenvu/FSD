# FSD Unified Session Handoff

AGENT: Claude
MODEL VERIFIED: Claude Sonnet 5.0 via Claude Code
ROLE: A (Audit) — Temporary Canonical Gate Reviewer
MODE: verification
TASK ID: FSD-PHASE0A-LIBFSEXT-CLAUDE-SIGNOFF-0725-17
PHASE: Phase 0A — Multi-filesystem feasibility (libfsext sub-gate signoff)

**Temporary substitution authorization:** The project owner has explicitly authorized Claude Sonnet 5.0 as the temporary substitute reviewer for this specific libfsext gate because Codex usage is currently unavailable. This substitution applies only to this FSD Phase 0A libfsext sign-off; it does not permanently change the normal Agent assignment policy, does not authorize Claude to implement code, and does not authorize Git, commit, push, or GitHub work. This session did not claim to be, and is not, GPT 5.6 Sol.

## OBJECTIVE

Perform a focused independent review of the existing libfsext feasibility evidence (Forge spike + first audit + revalidation audit) and issue a Claude Sonnet 5.0 gate recommendation on: canonical provider acceptance, the Phase 0A libfsext sub-gate status, per-condition gate classification, whether native-filesystem feasibility testing may begin, and whether Phase 0 Xcode/Catalog implementation remains blocked. Not a full re-execution of the feasibility campaign — a targeted trace-and-spot-check review.

## REPOSITORY STATE BEFORE

- `FSD_ROOT` resolved to `/Users/cenvu/Desktop/DEV/FSD`.
- Git: NOT INITIALIZED. No `.git` directory (`git status --short` exit 128; `git diff --check` exit 129).
- No Swift, Xcode project, or `Package.swift` file exists anywhere in the tree (`find` for `*.swift`/`*.xcodeproj`/`Package.swift` outside `spikes/` returned nothing) — confirms Phase 0 Xcode/Catalog implementation has not started.
- `docs/PRODUCT_STATE.md` §"Not started" lists "Xcode project" first — consistent.
- Three prior Handoffs exist for this sub-gate: `FSD_PHASE0A_LIBFSEXT_C_20260725-160300.md` (Forge, role code `C`), `FSD_PHASE0A_LIBFSEXT_A_20260725-174000.md` (first audit, APPROVE WITH CONDITIONS), `FSD_PHASE0A_LIBFSEXT_REAUDIT_A_20260725-175300.md` (revalidation, APPROVE WITH CONDITIONS).
- `spikes/phase0a-libfsext/` exists with source, build scripts, fixtures, and recorded output files, unmodified by this session.
- **Canonical-document discrepancy found before any spike evidence was touched** (see FINDINGS): `docs/PRODUCT_STATE.md` and `docs/MVP_PLAN.md` both state R0 correction "remains open... this state has not changed since" the 2026-07-24 REJECT audit; `docs/README.md` states R0 "has been independently closed." These three documents disagree with each other as of this session.

## FILES READ

- `handoffs/FSD_PHASE0A_LIBFSEXT_C_20260725-160300.md` (full)
- `handoffs/FSD_PHASE0A_LIBFSEXT_A_20260725-174000.md` (full)
- `handoffs/FSD_PHASE0A_LIBFSEXT_REAUDIT_A_20260725-175300.md` (full)
- `spikes/phase0a-libfsext/src/main.c` (full, 144 lines)
- `spikes/phase0a-libfsext/scripts/generate_fixtures.sh` (full, for the case-distinct-fixture claim)
- `spikes/phase0a-libfsext/fixtures-manifest.md`, `spikes/phase0a-libfsext/README.md`
- `spikes/phase0a-libfsext/libfsext-release/include/libfsext.h` (name APIs, `libfsext_volume_open_file_io_handle`, `format_version` signature)
- `spikes/phase0a-libfsext/libfsext-release/libbfio/libbfio_file_range_io_handle.h` (offset API existence)
- `spikes/phase0a-libfsext/fixtures/tree/` directory listing (case-distinct fixture root-cause check)
- `docs/FILESYSTEM_FEASIBILITY_PLAN.md` §1–3
- `docs/DECISIONS.md` ADR-009, ADR-011, ADR-015 (re-read current text, not assumed from prior Handoffs)
- `docs/PRODUCT_STATE.md`, `docs/MVP_PLAN.md` (two-gate header), `docs/README.md` §Status
- `docs/SECURITY_AND_READ_ONLY_POLICY.md` (referenced; read-only contract cross-check, not re-quoted in full — unchanged from prior Plan Gate audits this session already verified)

## FILES CHANGED

**NONE.** This is a review-only session. No canonical document, spike source, fixture image, or build script was modified. All independent rebuilds and spot-check output were written to `/private/tmp/fsd-libfsext-signoff-0725-17/`, outside the repository.

## WORK COMPLETED

Traced the highest-impact claims directly from source/headers rather than accepting either prior Handoff's word, then ran the permitted minimal spot checks (not a full re-run of the fixture/sanitizer/leak campaign, per instruction). Confirmed the technical substance of both prior audits is accurate. Found one factual defect in both prior Handoffs' repository-hygiene claims (trailing whitespace), one refinement to the case-distinct-fixture root-cause diagnosis, and one live canonical-document contradiction about R0 status that bears directly on the Phase 0 blocking question.

## IMPLEMENTATION OR REVIEW DETAILS

### Read-only / open-mode claim

`src/main.c` line 116: `libfsext_volume_open(volume, filename, LIBFSEXT_OPEN_READ, &error)` — confirmed the only open call in the file, `LIBFSEXT_OPEN_READ` the only mode used. Full-file read confirms no `write`, `fwrite`, `pwrite`, or writable `open()` call anywhere in the 144-line source. **Matches both prior Handoffs exactly.**

### Invalid UTF-8 name handling

`src/main.c` lines 17–30: when `libfsext_file_entry_get_utf8_name_size()` returns 0 or fails, `name = strdup("")`. Independently re-ran the spike against `valid_ext4.img`; the entry at inode 25 (the `bad_utf8_\xff\xfe` fixture file) prints as `path='//', ... inode=25`, i.e. an empty name indistinguishable from root. **Independently reproduced, matches both prior Handoffs.**

`libfsext.h` grep for name-related public API: only `get_utf8_name`/`get_utf8_name_size` and `get_utf16_name`/`get_utf16_name_size` exist for file entries (plus the equivalent pair for extended attributes and sub-entry lookup by name). **No public raw-byte name getter exists** — confirms the revalidation audit's correction to the first audit's proposed fix (`libfsext_file_entry_get_name()` does not exist in the public API).

Per ADR-009 (re-read current text): "If Foundation cannot represent a name, the scanner records an issue and marks the affected region uncertain (complete_with_warnings)... raw filename byte preservation is out of scope for MVP." An inode-based synthetic identity, combined with an emitted `scan_issue` and an uncertain classification, is consistent with this contract and does not claim to preserve the original filename. This is a safe, available method — the review is not rejected on this point.

### Partition-offset claim

`src/main.c` lines 102–104: `off64_t offset = strtoll(argv[2], NULL, 10)` — parsed, never referenced again anywhere in the file (confirmed via full-file `grep -n offset`). Independently ran both `./phase0a_libfsext_spike fixtures/partitioned_ext4.img` and `./phase0a_libfsext_spike fixtures/partitioned_ext4.img 10485760` — **identical failure** (`Failed to open volume`, exit 1) in both cases, proving the offset argument has no effect. `libfsext_volume_open_file_io_handle()` confirmed present at line 247 of `libfsext.h`; `libbfio_file_range_io_handle.h`/`.c` confirmed present in the bundled `libbfio` sources. **Independently reproduced; the production API path is real, matches both prior Handoffs.**

### Static linkage / arm64

Independently rebuilt a static binary from `src/main.c` against all 16 `.a` archives found under `libfsext-release/*/.libs/*.a`. Result: `Mach-O 64-bit executable arm64`; `otool -L` shows only `/usr/lib/libSystem.B.dylib`. Reproduced the identical compiler warning both prior audits reported, verbatim: `src/main.c:126:52: warning: incompatible pointer types passing 'uint16_t *' ... to parameter of type 'uint8_t *'`. **Independently reproduced, third independent build (Forge's dynamic build, first audit's static rebuild, this session's static rebuild) all agree.**

### Ground-truth enumeration and read-only hash check

Ran the existing dynamic-linkage spike (`phase0a_libfsext_spike`, present and unmodified in the spike directory) against `valid_ext4.img`. SHA-256 before: `7d0b904bfd41faae7d3bff4e6b07f67c9732a30ce80a6a374f7c7c38813602e4`; after: identical — matches the exact hash recorded in both prior Handoffs. Output includes the Korean-Unicode filename entry, correct symlink target resolution (read without following), and the same 14+1 entry structure both prior audits reported. **Independently reproduced.**

### Case-distinct fixture

`scripts/generate_fixtures.sh` lines 34–35 create `case_file.txt` then `Case_File.txt` in the tree directory. Both prior Handoffs attributed the missing uppercase variant to `mke2fs -d` "apparently" collapsing the two names. This session inspected `fixtures/tree/` directly (the actual source directory `mke2fs -d` reads from) and found **only `case_file.txt` present there — `Case_File.txt` never existed in the source tree at all.** A `strings` scan of `valid_ext4.img` independently confirms only `case_file.txt` appears in the image. **Refinement to both prior audits' diagnosis:** the collision happens when the shell script populates `TREE_DIR` on the host filesystem (macOS APFS, case-insensitive by default) — before `mke2fs -d` ever runs — not inside `mke2fs -d` itself. This does not change the conclusion (fixture-generation-environment issue, not a libfsext or ext4 behavior question) but is a more precise root cause than either prior Handoff recorded.

### Repository hygiene — discrepancy found

Both prior Handoffs claim spike source has no trailing whitespace (`FSD_PHASE0A_LIBFSEXT_A_20260725-174000.md` §8.15: "Trailing whitespace in spike source: None detected"; `FSD_PHASE0A_LIBFSEXT_REAUDIT_A_20260725-175300.md` §10 commands: "grep trailing whitespace in spike source → none"). Independent `grep -nE "[ \t]+$"` against `src/main.c` and `scripts/generate_fixtures.sh` found **20 trailing-whitespace lines in `main.c`** (lines 16, 31, 35, 38, 41, 45, 50, 56, 59, 70, 91, 100, 106, 108, 115, 122, 124, 129, 138, 141) and **4 in `generate_fixtures.sh`** (lines 52, 55, 64, 66). This is a factual correction to both prior Handoffs' hygiene claims. It has no bearing on the technical feasibility conclusions — the source still compiles, behaves, and reads exactly as both prior audits describe — but the claim itself was wrong and is recorded here rather than silently repeated.

### Canonical R0/Phase-0 gate status — live document contradiction

`docs/PRODUCT_STATE.md`: *"1. R0 correction remains open... This state has not changed since that audit [2026-07-24 REJECT]."* `docs/MVP_PLAN.md` header: *"R0 approval — ...was independently audited and returned REJECT... This replan does not resolve R0 — it is a separate, still-open concern."* `docs/README.md` §Status: *"Foundational R0 schema issues have been independently closed; final plan-gate correction and audit remain."* These three canonical documents make **mutually inconsistent claims about the same fact** (whether R0 is open or closed) as of this session. Both prior Phase0A libfsext Handoffs (Audit and Reaudit) independently concluded R0 "remains blocked" as an unrelated gate, consistent with `PRODUCT_STATE.md`/`MVP_PLAN.md`, not `README.md`. This review adopts the more specific and more recently-reasoned position (`PRODUCT_STATE.md`/`MVP_PLAN.md`, which both cite the exact unresolved audit and its unchanged status) rather than `README.md`'s shorter, unsupported "closed" claim, and reports the contradiction rather than resolving it — a documentation fix, not a spike-source fix, is out of this session's scope.

## COMMANDS EXECUTED

```
# Read-only / open-mode source trace
grep -n "libfsext_volume_open\|write(\|fwrite(\|pwrite(" spikes/phase0a-libfsext/src/main.c

# Ground-truth spot check
shasum -a 256 fixtures/valid_ext4.img                       (before)
otool -L .libs/phase0a_libfsext_spike
./phase0a_libfsext_spike fixtures/valid_ext4.img > /private/tmp/fsd-libfsext-signoff-0725-17/ext4_spotcheck.txt
shasum -a 256 fixtures/valid_ext4.img                       (after — matches)
grep "inode=25" /private/tmp/.../ext4_spotcheck.txt

# Static build (independent, third rebuild)
find libfsext-release -name '*.a' -type f
gcc -o /private/tmp/fsd-libfsext-signoff-0725-17/static_spike src/main.c \
    -I libfsext-release/include [all 16 .a archives]
file /private/tmp/.../static_spike
otool -L /private/tmp/.../static_spike

# Partition offset
./phase0a_libfsext_spike fixtures/partitioned_ext4.img               → exit 1
./phase0a_libfsext_spike fixtures/partitioned_ext4.img 10485760      → exit 1 (identical)
grep -n "offset" spikes/phase0a-libfsext/src/main.c
grep -n "libfsext_volume_open_file_io_handle\|file_range_io_handle" libfsext-release/include/libfsext.h
find libfsext-release -iname "*file_range*"

# Name API and case-distinct fixture
grep -n "_get_.*name" libfsext-release/include/libfsext.h
ls -la spikes/phase0a-libfsext/fixtures/tree
strings spikes/phase0a-libfsext/fixtures/valid_ext4.img | grep -i case_file

# Canonical scope confirmation
grep -n -A3 "Not started" docs/PRODUCT_STATE.md
find . \( -iname "*.swift" -o -iname "*.xcodeproj" -o -iname "Package.swift" \) -not -path "*/spikes/*"
sed -n '1,15p' docs/FILESYSTEM_FEASIBILITY_PLAN.md
sed -n '/## ADR-009/,/## ADR-010/p' docs/DECISIONS.md
sed -n '/## ADR-015/,/## ADR-016/p' docs/DECISIONS.md
sed -n '1,25p' docs/PRODUCT_STATE.md
sed -n '1,15p' docs/MVP_PLAN.md
sed -n '95,98p' docs/README.md

# Repository hygiene
git status --short          → exit 128, not a repository
git diff --check            → exit 129, not a repository
grep -rlnE "[ \t]+$" handoffs/FSD_PHASE0A_LIBFSEXT_*.md spikes/phase0a-libfsext/src/main.c spikes/phase0a-libfsext/scripts/generate_fixtures.sh
grep -rlnE "^(<<<<<<<|=======|>>>>>>>)" handoffs/FSD_PHASE0A_LIBFSEXT_*.md spikes/phase0a-libfsext/src/main.c
ls temp.db temp2.db modify_schema.py modify_verify.py replace_docs.py fix_mount_consent.py verify_output.txt   (pre-existing root artifacts, unchanged, out of this review's scope)
```

## AUTOMATED VERIFICATION

All verification performed via command execution and source/header inspection. No manual visual inspection was required or performed.

## REAL MANUAL TESTS

NONE REQUIRED, per instruction and per `FILESYSTEM_FEASIBILITY_PLAN.md` §3: Phase 0A is disk-image-only by canonical design.

## VERIFIED RESULTS

| Claim | Status |
|---|---|
| `LIBFSEXT_OPEN_READ` is the only open mode; no write-capable call exists | **VERIFIED** — independent source trace, full-file read |
| Read-only: image hash unchanged after enumeration | **VERIFIED** — independently reproduced, hash matches both prior Handoffs |
| ext4 metadata enumeration matches prior ground-truth evidence | **VERIFIED** — independently re-run, output structurally identical |
| Invalid UTF-8 name becomes an empty, root-indistinguishable name | **VERIFIED** — independently reproduced at inode 25 |
| No public raw-byte filename getter in libfsext | **VERIFIED** — exhaustive grep of public header, only UTF-8/UTF-16 getters exist |
| Partition-offset argument is dead code in the adapter | **VERIFIED** — independently reproduced (offset arg has zero effect), source-traced |
| `libfsext_volume_open_file_io_handle()` + `libbfio_file_range_io_handle` exist for a production offset path | **VERIFIED** — confirmed present in headers/sources |
| Static build yields arm64 Mach-O linked only against `libSystem.B.dylib` | **VERIFIED** — independently rebuilt (third independent build across all three review sessions) |
| `format_version` compiler warning (`uint16_t*` vs `uint8_t*`) | **VERIFIED** — independently reproduced, identical message and line |
| `Case_File.txt` never reaches the ext4 image | **VERIFIED**, with a refined root cause — absent from the source tree itself (host APFS collision), not merely absent post-`mke2fs` |
| No Swift/Xcode/`Package.swift` exists anywhere outside `spikes/` | **VERIFIED** — confirms Phase 0 implementation has not started |
| Prior Handoffs' "no trailing whitespace in spike source" claim | **REFUTED** — independently found 24 trailing-whitespace lines across `main.c` and `generate_fixtures.sh` |
| `docs/PRODUCT_STATE.md`/`docs/MVP_PLAN.md` vs. `docs/README.md` disagree on R0 status | **VERIFIED** — direct quotation from all three current documents |

## INFERRED RESULTS

| Claim | Basis |
|---|---|
| ext2/ext3 enumeration correctness | Not independently re-run this session (permitted spot-check budget was spent on ext4 + the highest-impact claims); credible based on two independent prior ground-truth comparisons plus this session's independent ext4 confirmation using the same code path |
| Encrypted-subtree, corrupted-image, sanitizer, and leak-check results | Not re-run this session (out of the permitted minimal-spot-check list and not contradicted by anything found); accepted as credible on the strength of two independent prior Handoffs' command-level evidence, consistent with this session's own source-level confirmation of the relevant error-handling code path |
| General robustness beyond the tested fixture set | INFERRED, not proven — same caveat both prior Handoffs correctly recorded |

## PROPOSED ITEMS

Carried forward from the revalidation audit, independently endorsed by this session's own source/header inspection:

- Inode-based synthetic identity for entries with unrepresentable names, paired with a `scan_issue` and an uncertain classification (no raw-byte API exists to do otherwise; consistent with ADR-009's explicit MVP boundary).
- Partition-offset support via `libbfio_file_range_io_handle` + `libfsext_volume_open_file_io_handle()` (API confirmed present and real).
- Recursion-depth limit for the production adapter (confirmed unbounded recursive `enumerate_entry()` in source).
- Distinct exit/status signaling for partial enumeration (confirmed the spike exits 0 even when the encrypted-subtree branch fails).
- `format_version` type fix to `uint8_t` (confirmed benign but real compiler warning).
- Regenerate fixtures for a genuinely case-distinct pair, from a case-sensitive intermediate location (not the host's case-insensitive APFS tree) — refined recommendation based on this session's root-cause finding.

New from this session:

- Correct the trailing-whitespace claim in future Handoff hygiene sweeps for this spike (not a spike-source fix — out of scope for this review — but future sessions should not repeat the "None detected" claim without re-verifying it).
- Reconcile the R0-status contradiction between `PRODUCT_STATE.md`/`MVP_PLAN.md` ("remains open") and `README.md` ("independently closed") before treating either as settled for gate-tracking purposes.

## BLOCKED ITEMS

| Item | Reason |
|---|---|
| `git status --short` | Not a git repository |
| `git diff --check` | Not a git repository |
| Full re-execution of the ASan/UBSan/leak/fuzz campaign | Explicitly out of scope for this focused review per instruction |
| Native APFS/HFS+/FAT/exFAT/NTFS/UDF feasibility testing | Explicitly out of scope for this review |
| Definitive LGPL legal conclusion | Explicitly out of scope; formal legal review required separately |

## ACCEPTED RISKS

| Risk | Mitigation |
|---|---|
| LGPL-3.0-or-later obligations for the chosen linkage strategy | ADR-015 specifies dynamic linking in `FSD.app/Contents/Frameworks/`; `COPYING.LESSER` confirmed present; formal review required before distribution, not before Phase 0A or Phase 2 |
| No public raw-byte name API in libfsext | ADR-009 explicitly excludes raw-byte preservation from MVP scope; inode-based identity plus `scan_issue` is a safe, available substitute |
| Single corruption pattern tested (block-group descriptors, not primary superblock) | Not independently re-tested this session; accepted per both prior Handoffs' explicit caveat not to generalize; production helper-process isolation (ADR-017) bounds blast radius regardless |
| Case-distinct fixture never actually exercised libfsext's case-sensitive-name handling | Does not block the current gate (ext2/3/4 are case-sensitive by default; this is a fixture-generation-environment artifact, root-caused this session to the host's case-insensitive APFS tree, not a library behavior question); required before Phase 2 exit criteria are considered complete |
| Agent-identity mismatch across the review chain (originally assigned GPT 5.6 Sol; performed by Claude Opus 4.6 Thinking twice, now Claude Sonnet 5.0 once, all under explicit temporary authorization) | Evidence is source-traceable and independently reproducible regardless of which agent produced or re-verified it; this session's own independent spot checks corroborate the technical substance directly, not merely the prior agents' say-so |

## KNOWN ISSUES

1. Forge Handoff filename role code `_C_` instead of `_F_` per ADR-013 — historical, not renamed, per safety rules. (Confirmed unchanged this session.)
2. `format_version` type mismatch (`uint16_t*` vs `uint8_t*`) — benign compiler warning, independently reproduced.
3. Missing case-distinct fixture pair — refined root cause: absent from the source tree itself, not just the resulting image.
4. Both prior audit Handoffs' "no trailing whitespace in spike source" claim is factually incorrect — 24 lines found across two files.
5. `docs/PRODUCT_STATE.md`/`docs/MVP_PLAN.md` say R0 "remains open"; `docs/README.md` says R0 "has been independently closed." Live contradiction, unresolved as of this session.
6. Pre-existing, unrelated root-level artifacts (`temp.db`, `temp2.db`, `modify_schema.py`, `modify_verify.py`, `replace_docs.py`, `fix_mount_consent.py`, `verify_output.txt`) remain present, first flagged by the first Phase0A audit Handoff, still unresolved. Out of this review's scope; noted for completeness only.
7. Encrypted-subtree failure and dead partition-offset code both leave the adapter exiting 0 despite incomplete enumeration — confirmed by source inspection of the sibling-loop and `main()`'s single `return 0` path after any enumeration outcome.

## REMAINING WORK IN CURRENT PHASE

Phase 0A also requires native-filesystem feasibility testing for the 7 native-readable variants (APFS, HFS+, FAT16, FAT32, exFAT, NTFS-ro, UDF) per `FILESYSTEM_FEASIBILITY_PLAN.md`. This review covers only the libfsext/embedded-raw sub-gate. Phase 0B's formal ADR-015 confirmation record has not yet been made.

## EXACT NEXT ACTION

1. Record the Phase 0A libfsext sub-gate as **PASS WITH DEFERRED PRODUCTION CONDITIONS** (confirmed, not merely re-asserted, by this session).
2. Proceed to Phase 0A native-filesystem feasibility testing (7 native-readable variants) as the next Phase 0A deliverable.
3. Reconcile the R0-status contradiction between `PRODUCT_STATE.md`/`MVP_PLAN.md` and `README.md` before either is relied on as settled.
4. Carry Conditions A, B, D, F (below) into Phase 2 production-integration planning; carry Condition C into pre-distribution legal review; carry Condition E into Phase 2 fixture regeneration.

## GIT STATUS

```text
$ git status --short
fatal: not a git repository (or any of the parent directories): .git   (exit 128)
$ git diff --check
usage: git diff --no-index ...   (exit 129, no repository/index to diff against)
```

GIT STATUS: BLOCKED — NOT A REPOSITORY

## COMMIT READINESS

NOT APPLICABLE — no Git repository exists. No commit was made or attempted.

## PUSH READINESS

NOT AUTHORIZED — no Git repository, no remote, no GitHub access, no push performed or requested.

## RECOMMENDED REVIEW FOCUS

1. The R0-status contradiction (`PRODUCT_STATE.md`/`MVP_PLAN.md` "open" vs. `README.md` "closed") — this is the single item most likely to cause CONTROL CENTER to reach an incorrect conclusion about Phase 0 blocking status if not resolved first.
2. Condition A (invalid UTF-8 handling) remains the most architecturally significant Phase 2 condition — it touches ADR-009's core Unicode-identity contract, not just an adapter convenience.
3. The corrected trailing-whitespace claim, so future sessions do not repeat "None detected" without re-checking.

---

## PROBLEM

Determine whether the accumulated libfsext feasibility evidence (one coding spike, two independent audits) is sound enough to (a) accept libfsext as FSD's canonical ext2/ext3/ext4 dependency, (b) close the Phase 0A libfsext sub-gate, and (c) authorize the next Phase 0A deliverable (native-filesystem feasibility), without re-running the entire campaign — using a substitute reviewer (Claude Sonnet 5.0) because the normally-assigned reviewer is unavailable.

## CONSTRAINTS

- Read-only, disk-image-only feasibility testing; no physical-device access; no raw writes.
- No canonical document, spike source, or fixture image may be modified by this review.
- No Swift/XPC/production code may be written.
- No Git operations of any kind.
- Temporary spot-check output must remain outside the repository.
- Only a focused review is permitted — not a full re-execution of the fixture/sanitizer/leak matrix.

## ASSUMPTIONS

- The two prior audit Handoffs' detailed command-level evidence for claims not independently re-run this session (ext2/ext3 enumeration, encrypted-subtree behavior, corrupted-image resilience, ASan/UBSan/leak results) is accurate, absent contradiction — this session's own spot checks corroborate the subset it did re-run and found no discrepancy in any *technical* claim (only in one *hygiene* claim).
- "Canonical acceptance of libfsext" means acceptance for the feasibility/library-choice question (ADR-015), not a certification of any specific production adapter implementation.
- Phase 0A's explicit "no SQLite persistence, disk-image-only, prints to stdout" scope (independently confirmed by this session's own reading of `FILESYSTEM_FEASIBILITY_PLAN.md` §3 in the prior Plan Gate review chain) means production-adapter deficiencies do not, by themselves, block this sub-gate.

## OPTIONS

1. **APPROVE** outright, treating all five (now seven, with F and G added) conditions as fully resolved or irrelevant.
2. **APPROVE WITH CONDITIONS**, accepting the library-feasibility proof while explicitly gating specific, itemized production/distribution work.
3. **REJECT**, on the theory that the invalid-UTF-8 or partition-offset gaps are severe enough to disqualify libfsext outright, or that the trailing-whitespace/R0-contradiction findings undermine confidence in the whole evidence chain.

## TRADE-OFFS

- Option 1 is not supportable: real, independently-reproduced adapter deficiencies exist (invalid-UTF-8 data loss, dead offset code, unbounded recursion, exit-code-0-on-partial-failure). Ignoring them would misrepresent the state of the work.
- Option 3 overreacts: none of the found deficiencies are library-feasibility questions — they are adapter-implementation gaps with confirmed, viable, real API-level solutions (raw-byte identity via inode substitution, `libbfio_file_range_io_handle`, a depth counter, a distinct exit code). The trailing-whitespace and R0-contradiction findings are hygiene/documentation issues, not evidence of a broken feasibility conclusion — every technical claim this session re-traced independently held up.
- Option 2 matches the actual evidence: proven library feasibility plus itemized, real, non-blocking-to-this-gate conditions.

## RECOMMENDED APPROACH

APPROVE WITH CONDITIONS, confirming both prior audits' technical conclusions, adding the refined case-distinct-fixture root cause, correcting the trailing-whitespace claim, and flagging the R0-status document contradiction for resolution before it affects a gate decision elsewhere.

## REJECTED APPROACHES

- Full re-execution of the ASan/UBSan/leak/fuzz campaign — rejected as explicitly out of scope and unnecessary; no contradiction was found in this session's own re-tracing of the relevant source paths that would justify the cost.
- Accepting the Forge Handoff's original claims (§18 raw-byte preservation, §21 offset handling) at face value — rejected; both were independently re-confirmed as overstated by two separate audit rounds and this session's own source trace agrees.
- Treating Condition E (case-distinct fixture) as fully "optional" without qualification — this session nudges it toward "required later test" given ADR-010's case-sensitivity comparison behavior is a real correctness feature FSD needs verified, not cosmetic polish, even though it still does not block the current gate.

## REQUIRED REAL TESTS

None for this sub-gate — Phase 0A is disk-image-only by canonical design and no user manual test is required (per instruction). Required *future* tests (Phase 2, not this gate): a case-sensitive-host-generated fixture pair; a partition-offset round-trip through the production `libbfio_file_range_io_handle` path; an invalid-UTF-8 round-trip through the production `scan_issue`/uncertain-classification path.

## ESCALATION RECOMMENDATION

Escalate the R0-status document contradiction (`PRODUCT_STATE.md`/`MVP_PLAN.md` vs. `README.md`) to CONTROL CENTER for resolution before any decision that depends on "is Phase 0 blocked by R0" is treated as settled. No other item in this review rises to an escalation-worthy level — all other findings have a clear, itemized, non-blocking-to-this-gate disposition.

---

## AUDIT SCOPE

Per instruction: evidence quality in the three existing Handoffs; the adapter's open and enumeration paths; invalid UTF-8 behavior; public name APIs exposed by libfsext; partition-offset implementation and available APIs; read-only evidence; representative metadata enumeration evidence; static-linkage evidence; malformed/encrypted-image evidence (accepted as credible, not re-run); licensing-risk classification; FSD architectural and MVP scope; Handoff compliance. Explicitly excluded: editing any file, full campaign re-execution, native-filesystem feasibility testing, legal advice, Git operations, VisualDiffer access.

## EVIDENCE REVIEWED

See FILES READ and COMMANDS EXECUTED above. Summary: three Handoffs read in full; primary adapter source read in full; two library headers grepped for the specific API-existence questions at issue; one fixture-tree directory inspected directly; one image scanned with `strings`; four canonical documents re-read for current text (not assumed from prior Handoffs' quotations); one independent static rebuild; one independent dynamic-binary execution with before/after hashing; two independent partition-offset invocations; two hygiene greps.

## FINDINGS BY SEVERITY

### HIGH (carried forward, independently reconfirmed, unchanged severity)

1. **Invalid-UTF-8 names silently lost by the spike adapter's fallback path.** Independently reproduced. No public raw-byte API exists to fix this by simple substitution — confirmed by this session's own header search, matching the revalidation audit's correction to the first audit. Production resolution: inode-based synthetic identity + `scan_issue` + uncertain classification, consistent with ADR-009.
2. **Partition-offset argument is dead code.** Independently reproduced (identical failure with and without the offset argument). The production API path (`libbfio_file_range_io_handle` + `libfsext_volume_open_file_io_handle()`) is confirmed real and available.

### MEDIUM (carried forward, independently reconfirmed; one new item added)

3. Encrypted-subtree entry not surfaced with name/inode context in the error path — not re-run this session, accepted as credible per source-level confirmation of the sibling-loop's `[Error getting sub entry N]` pattern.
4. Exit code 0 for partial enumeration (encrypted-subtree case) — confirmed by source inspection: `main()` has a single unconditional `return 0` after the enumeration call, regardless of any internal `[Error ...]` print.
5. Missing case-distinct fixture pair — confirmed, with a refined root cause (absent from the source tree itself, not just the image).
6. Unbounded recursion depth — confirmed by source inspection of `enumerate_entry()`'s self-call with no depth counter or limit.

### LOW (carried forward; two new items this session)

7. `format_version` type mismatch — independently reproduced, identical warning.
8. Forge Handoff role code `_C_` instead of `_F_` — confirmed unchanged, not renamed per safety rules.
9. **NEW — Prior audit Handoffs' "no trailing whitespace in spike source" claim is incorrect.** 24 trailing-whitespace lines independently found across `main.c` (20) and `generate_fixtures.sh` (4). Hygiene-only; no technical-conclusion impact.
10. **NEW — Live contradiction between `PRODUCT_STATE.md`/`MVP_PLAN.md` ("R0 remains open") and `README.md` ("R0 has been independently closed").** Documentation-consistency issue directly relevant to the Phase-0-blocking question; not a spike defect.

## REQUIRED FIXES

None for the Phase 0A libfsext sub-gate itself. Required before Phase 2 production integration: Conditions A, B, D, F (below). Required before distribution: Condition C. Required before Phase 2 exit (not blocking entry): Condition E. Required for documentation accuracy (not a code fix): reconcile the R0-status contradiction.

## OPTIONAL IMPROVEMENTS

- Fix `format_version` to `uint8_t`.
- Strip trailing whitespace from `main.c` and `generate_fixtures.sh` (not performed by this review — out of scope; a future Coding-role session should do this).
- Fix the `//` double-slash path-construction artifact noted by the first audit.
- Record the libfsext download archive checksum for reproducibility.
- Separate stderr/stdout for error messages in the adapter.

## PER-CONDITION GATE CLASSIFICATION

| # | Condition | Classification | Reason |
|---|---|---|---|
| A | Invalid UTF-8 identity, `scan_issue`, uncertainty handling | **BLOCKS PHASE 2 PRODUCTION INTEGRATION** | Independently reproduced data-loss behavior; library correctly signals inability to convert, the adapter's error handling is what needs work; a real, ADR-009-consistent resolution exists (inode-based identity) but is not yet implemented anywhere |
| B | Partition-offset implementation | **BLOCKS PHASE 2 PRODUCTION INTEGRATION** | Confirmed dead code; confirmed real, available, read-only-compatible API path (`libbfio_file_range_io_handle` + `libfsext_volume_open_file_io_handle()`) not yet used by any adapter |
| C | LGPL-3.0-or-later compliance review | **BLOCKS DISTRIBUTION ONLY** | `COPYING.LESSER` confirmed present; ADR-015 specifies dynamic linking, satisfying the substitution requirement in principle; only external distribution triggers the formal-review obligation — Phase 0A, Phase 2, and internal development builds are unaffected |
| D | Production recursion-depth limit | **BLOCKS PHASE 2 PRODUCTION INTEGRATION** | Confirmed unbounded recursion in source; standard defensive-coding requirement for any adapter accepting untrusted filesystem structures, especially inside the isolated helper process ADR-017 specifies |
| E | Verified case-distinct fixture | **DOES NOT BLOCK; REQUIRED LATER TEST** | Refined root cause confirms this is a fixture-generation-environment artifact (host APFS case-insensitivity), not a libfsext or ext-filesystem behavior question; but ADR-010's case-sensitivity comparison logic is a real correctness feature that needs an actual verified test before Phase 2 exit criteria are complete — nudged from "optional" to "required later test" for that reason, while still not blocking the current gate or Phase 2 entry |
| F | Partial-success signaling for inaccessible subtrees | **BLOCKS PHASE 2 PRODUCTION INTEGRATION** | Confirmed by source inspection: the adapter always returns 0 regardless of internal enumeration errors; a production `EmbeddedRawProvider` must distinguish `complete` from `complete_with_warnings`/`partial`, which requires this signal to exist somewhere in the call chain |
| G | Compiler warning for `format_version` type | **DOES NOT BLOCK; OPTIONAL IMPROVEMENT** | Independently reproduced; functionally benign (ext version values 2/3/4 fit in either integer width); a one-line type fix, not a behavior risk |

## DECISION

### APPROVE WITH CONDITIONS

**Claude Sonnet 5.0 review decision:** APPROVE WITH CONDITIONS. This is a review recommendation for CONTROL CENTER's consideration, not itself a final CONTROL CENTER approval.

**Confirmation of prior technical findings:** Confirmed. Every technical claim independently re-traced this session (read-only open mode, no write calls, image-hash preservation, ext4 ground-truth enumeration, invalid-UTF-8 silent loss, absence of a public raw-byte name API, dead partition-offset code and the real API path that should replace it, static-linkage self-containment, the `format_version` compiler warning) matches both prior Handoffs exactly. Two non-technical corrections were made: the trailing-whitespace claim was wrong, and the case-distinct-fixture root cause is more specific than either prior Handoff recorded. Neither correction changes any technical conclusion.

**Canonical provider recommendation:** libfsext (libyal project, `libfsext-experimental-20260201`, LGPL-3.0-or-later) is confirmed as the canonical ext2/ext3/ext4 Embedded Raw Provider dependency for FSD, per ADR-015.

**Phase 0A libfsext sub-gate recommendation:** **PASS WITH DEFERRED PRODUCTION CONDITIONS.**

**Conditions blocking Phase 2 production integration:** A, B, D, F.

**Conditions blocking distribution:** C.

**Conditions that do not block either gate:** E (required later test), G (optional improvement).

**May native-filesystem feasibility testing begin next?** **YES.** The libfsext sub-gate is passed; nothing found this session changes that conclusion.

**Does Phase 0 Xcode/Catalog implementation remain blocked?** **YES**, by two gates, with one important caveat: (1) Phase 0A/0B — the libfsext sub-gate is now passed (by this and two prior independent reviews) but the native-filesystem sub-gate has not started and the formal Phase 0B decision has not been recorded; (2) R0 correction — per `PRODUCT_STATE.md` and `MVP_PLAN.md`, both stating R0 "remains open" as of the unresolved 2026-07-24 REJECT audit. **Caveat:** `README.md` currently states R0 "has been independently closed," directly contradicting the other two documents. This review treats R0 as still open for gate-blocking purposes (consistent with the two more detailed, specifically-reasoned canonical documents and with both prior Phase0A Handoffs' own conclusion), but flags this contradiction as needing resolution — if `README.md` is actually correct and `PRODUCT_STATE.md`/`MVP_PLAN.md` are stale, then only the Phase 0A/0B gate remains open, not two gates.

**No checksum file was created for this Handoff.** Confirmed.

**No canonical, source, fixture, or spike file was modified by this session.** Confirmed — this Handoff is the only file created or changed.
