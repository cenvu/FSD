# FSD P15 Runtime Slice 02 — bounded source authority and Data-only provider

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_D_20261004-213748.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=1316b937ebd74d07a990bf0d2f59210a039e58c2
REMOTE_HEAD=ea0e2289fc0583446a67ccbeefbb015e457cd01a
LAST_VERIFIED_AT=2026-10-04T21:37:48+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|docs/P15_RUNTIME_PLAN.md|docs/ARCHITECTURE.md|docs/SECURITY_AND_READ_ONLY_POLICY.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|docs/database/schema.sql
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_P15_RUNTIME_SLICE_02_BOUNDED_SOURCE_AUTHORITY_012
STATUS=EXECUTION_VERIFIED_PENDING_PUBLICATION_AT_CAPTURE
BLOCKER=NONE
PROPOSED_NEXT=FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AUDIT
NO_AUTO_NEXT=YES

## Task lock and execution guard

TASK_ID=FSD_P15_RUNTIME_SLICE_02_BOUNDED_SOURCE_AUTHORITY_012
ROLE=WORKER
MODE=PRODUCT_IMPLEMENTATION_SOURCE_AUTHORITY
BASE_HEAD=ea0e2289fc0583446a67ccbeefbb015e457cd01a
UPSTREAM_HEAD=ea0e2289fc0583446a67ccbeefbb015e457cd01a
TECHNICAL_SHA=1316b937ebd74d07a990bf0d2f59210a039e58c2
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_AND_DATA_ONLY_PROVIDER
ALLOWED_PATHS=FSD/Catalog/SnapshotWriter.swift|FSD/Catalog/EntryClassificationRepository.swift|FSD/Classification/BoundedClassificationSourceReader.swift|FSD/Classification/LocalFileClassificationProvider.swift|FSD.xcodeproj/project.pbxproj|FSDTests/ClassificationEnrichmentTests.swift|FSDTests/SnapshotHistoryTests.swift|FSDTests/ClassificationSourceReaderTests.swift|FSDTests/ClassificationProviderContractTests.swift|docs/P15_RUNTIME_PLAN.md|handoffs/FSD_P15_RUNTIME_SLICE_02_SOURCE_AUTHORITY_D_20261004-213748.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;SCHEMA;FILESYSTEM_DETECTOR
SUCCESS_CRITERIA=FINAL_ROOT_LOCATOR;READ_AUTHORITY_BOUNDARY;DATA_ONLY_CONTRACT;REQUIRED_VALIDATION
VALIDATIONS=ROOT_MATRIX;CANCELLATION_RED;CLEAN_DEBUG_BUILD;FULL_DEBUG_SUITE;DIFF_SCOPE_AND_DIFF_CHECK;CONTROL_PLANE_CLOSURE
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
WORKER_RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=18
WORKER_REQUIREMENTS_EVIDENCED=18
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Authority / reconciliation

FACT: continued same task after second resolution with all WIP preserved; no restart, no rewrite of working Data-only/provider/reader code. Re-anchored at exact base ea0e2289fc0583446a67ccbeefbb015e457cd01a with 0/0 clean; prior base commit is HEAD with no drift. Accepted STATE authorizes exactly Slice 02; Slice 01 and its audit stand accepted. The second resolution supersedes only the root-alias candidate rule; every other Slice-02 contract stayed active and was honored unchanged.

Task-execution discipline and applicable Compact rules were read. Direct authorities: this task text, P15 Slice 02 plan, ARCHITECTURE, SECURITY_AND_READ_ONLY_POLICY section 2.1, TEST_PLAN section 9, schema SQL, FilesystemDetector (read-only reference).

At capture: technical commit above holds the 10 reviewed Slice-02 paths; origin/main remains base, ahead 1/behind 0, clean before finalizer projections. No drift was absorbed by recapturing base. Publication/synchronization is pending at immutable capture. Final completion waits for push/fetch and clean 0/0.

## Concrete delta

- Root locator rewritten to the FINAL contract in SnapshotWriter: Stage A returns the direct lexical remainder with zero filesystem I/O; Stage B canonicalizes the selected capture root only via POSIX realpath; Stage C builds exactly one candidate from canonical components with no raw fallback, table or second attempt; Stage D accepts it only after a no-follow walk from the mount root lands on the same object by st_dev and st_ino. Canonicalization, candidate, proof or containment failure fails capture closed.
- Entry boundary untouched in shape: realpath never touches entries, is never provider-visible, and never follows entry symlinks after capture. Reconstruction stays mount plus stored root locator plus validated entry path with lstat, O_NOFOLLOW open, fstat and post-open/post-read identity validation. FilesystemDetector is byte-identical to base.
- Cancellation precedence repaired at the single content-read boundary: once the read attempt returns or throws, observed cancellation wins over mapping to failed or sourceChanged, with no retry and exactly one content call. Pre-read sourceChanged and unsupported results stand when cancellation had not yet occurred.
- Provider contract completed Data-only: request holds exactly one immutable bounded Data field with no path, URL, handle, metadata, callback, resolver or bypass initializer; result carries all six locked cases with async cancellation-aware calls; the disabled provider stays side-effect-free. Obsolete direct enrichment service and its three tests removed; hostile-provider and unsupported-entry behavior covered by the reader matrix.
- Legacy schema-v8 fixture repaired by inserting the required root entry before terminal completion; no invariant weakened, no v9 locator assigned, no backfill; legacy classification stays unavailable with no row.
- Docs projection limited to P15 Slice 02 locked decision and Step 1, restated to the FINAL contract with the first-clarification raw-components wording superseded. No ADR, no DECISIONS edit, no other slice touched.

## Execution requirements / evidence

EVIDENCED items are FACT from executable tests, complete diff/status inspection and real receipts.

| # | Requirement | Status / evidence |
|---|---|---|
| 1 | Authority/baseline/WIP preservation | EVIDENCED — exact base 0/0 clean; all prior WIP retained; smallest delta applied to the changed decision only. |
| 2 | Direct child and mount root locators | EVIDENCED — nested capture stores exact normalized lexical locator with no alias I/O; mount-root capture stores empty locator. |
| 3 | macOS var presentation via canonical candidate | EVIDENCED — real /var/folders presentation accepted as private/var/... after same-object proof; raw mount-plus-var candidate proven absent. |
| 4 | Rejection matrix closed | EVIDENCED — canonicalization failure, missing/different-object/escaping/unprovable candidates, outside-mount and dot-component roots all rejected with zero persisted rows. |
| 5 | Single candidate structural proof | EVIDENCED — one construction site taking only canonical components, unit-covered; no second-candidate path exists. |
| 6 | Detector unchanged, no schema delta | EVIDENCED — FilesystemDetector, migrations, schema and verify files byte-identical to base. |
| 7 | Cancellation precedence REDs green | EVIDENCED — failed-read EINTR and read-plus-disappearance both return cancelled with exactly one content call and no retry. |
| 8 | Legacy v8 fail-closed behavior | EVIDENCED — schema-8 classification unavailable with no row, no locator backfill, later capture leaving the legacy snapshot fingerprint untouched. |
| 9 | Exact volume identity | EVIDENCED — recorded versus live volume identifier compared exactly; mismatch yields sourceChanged. |
| 10 | No-follow open and regular-only read | EVIDENCED — descriptor-relative O_NOFOLLOW walk and open; directories, packages, symlinks and special files unsupported before content I/O. |
| 11 | Escape and race detection | EVIDENCED — path traversal, symlink escape, substitution and disappearance detected via lstat/fstat and revalidation walks. |
| 12 | Byte/call ceiling | EVIDENCED — at most 4096 bytes from offset zero, one content call, zero tail reads; hostile provider never observes more. |
| 13 | Data-only request shape | EVIDENCED — single Data field; no path/URL/handle/metadata/callback present even under hostile-provider probes. |
| 14 | Async provider and disabled safety | EVIDENCED — async cancellation-aware calls; disabled provider side-effect-free and unavailable. |
| 15 | Sample/network/write silence | EVIDENCED — no sample persistence, hashing, logging, network or source writes; fingerprints unchanged around reads. |
| 16 | Snapshot/comparison truth unchanged | EVIDENCED — full suite green with entry/snapshot fingerprints and comparison behavior intact. |
| 17 | Required builds and suites | EVIDENCED — clean Debug build exit0; focused Slice-02 selection 84 pass; full Debug 365 total with 362 pass, 3 environment-probe skips, 0 fail. |
| 18 | Diff, scope and closure mechanics | EVIDENCED — diff check clean; base diff holds only the 14 allowed paths; product diff empty; old handoffs byte-identical; Desktop parity verified after push. |

## Completion gates

EXACT_VOLUME_IDENTITY=PASS
NOFOLLOW_OPEN=PASS
REGULAR_FILE_ONLY=PASS
PATH_ESCAPE=BLOCKED
SYMLINK_ESCAPE=BLOCKED
RACE_SUBSTITUTION=DETECTED
MAX_BYTES=4096
CONTENT_READ_CALLS=1
TAIL_READS=0
CANCEL_BOUNDARIES=PASS
REQUEST_DATA_ONLY=PASS
REQUEST_HAS_PATH=NO
REQUEST_HAS_URL=NO
REQUEST_HAS_HANDLE=NO
REQUEST_HAS_METADATA=NO
REQUEST_HAS_CALLBACK=NO
REQUEST_CALLER_BUDGET=NO
PROVIDER_ASYNC=YES
SAMPLE_PERSISTENCE=NONE
SAMPLE_HASHING=NONE
SAMPLE_LOGGING=NONE
NETWORK=NONE
SOURCE_WRITE=NONE
SNAPSHOT_TRUTH_UNCHANGED=YES
COMPARISON_TRUTH_UNCHANGED=YES
PRODUCT_SCOPE=SLICE_02_ONLY

## Commands / receipts / failures

Observed environment: macOS arm64; Xcode with isolated derived data at /tmp/FSD-P15-Slice02-DerivedData.

Baseline before the delta: 63 focused tests with 5 failures, each matching a directed item — two cancellation precedence REDs, the direct-locator proof-of-no-IO case, the legacy root-entry terminal invariant, and the superseded raw-components alias expectation. No failure was stacked or guessed; each mapped to one contract clause.

After the delta: focused Slice-02 selection exit0 with 84 pass and 0 fail across SnapshotHistoryTests, ClassificationSourceReaderTests, ClassificationProviderContractTests and ClassificationEnrichmentTests. Clean Debug build exit0 BUILD SUCCEEDED. Full Debug suite exit0: 365 total, 362 pass, 3 skips, 0 fail. git diff check exit0; complete scope, historical-byte and Desktop parity checks passed before the technical commit; candidate hashes preserved.

## Advisories / limits

- Full-suite skips are the three known environment-dependent external probes (isolated probe catalog plus two externally prepared filesystem-matrix cases); all require host-provided fixtures that were not present. Schema, authority and safety classes all executed.
- The macOS presentation integration case pins the real /var/folders to Data-volume layout and skips only if that system layout is absent; the deterministic unit and rejection matrix does not depend on host layout.
- Independent source read-authority audit remains required before Slice 03; Worker did not self-author it.

## Proposed state / publication closure

Proposed baseline: Slice 02 bounded source authority with Data-only provider contract implemented, proofs green, advisories above. Accepted STATE, rule promotions and product authorities outside the allowed paths remain unchanged. Worker ledger classification stays pending.

Finalizer projects this one immutable source with full CURRENT mirror, one Worker row and one worker_return event, exact Operator with full CURRENT Desktop transport while preserving dated prior fields, and publishes. Push, fetch, clean 0/0 and parity receipts are pending at immutable capture; final completion waits for fresh physical verification. Technical SHA is the implementation commit; handoff publication SHA is resolved from Git, avoiding self-reference. Return to BRAIN and stop.
