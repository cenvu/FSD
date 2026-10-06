# filetype v1.1.3 scratch feasibility retry — STOP

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_RETRY_D_20261006-200544.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=6cd35a82612b4e275ff7ccdacb7ffe590da30342
REMOTE_HEAD=6cd35a82612b4e275ff7ccdacb7ffe590da30342
LAST_VERIFIED_AT=2026-10-06T20:05:44+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|STATE/PROJECT_STATE.md|FSD/Classification/LocalFileClassificationProvider.swift|FSD/Classification/BundledMagikaClassificationProvider.swift|FSD/Classification/ClassificationRuntimeService.swift|handoffs/FSD_CLASSIFIER_NOMATCH_RUNTIME_REPAIR_D_20261006-192830.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029R
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=GO_BUILD_TOOL_LOCAL_TELEMETRY_ESCAPED_SCRATCH;LICENSE_CLOSURE_AND_MATCHER_INVENTORY_UNPROVEN
PROPOSED_NEXT=RETURN_TO_BRAIN_FOR_PROVIDER_STRATEGY_ADJUDICATION
NO_AUTO_NEXT=YES

## Task lock and truthful result

TASK_ID=FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_029R
ROLE=WORKER
MODE=SCRATCH_ONLY_NATIVE_PROVIDER_FEASIBILITY_RETRY
BASE_HEAD=6cd35a82612b4e275ff7ccdacb7ffe590da30342
UPSTREAM_HEAD=6cd35a82612b4e275ff7ccdacb7ffe590da30342
EXPECTED_CANONICAL_HEAD=6cd35a82612b4e275ff7ccdacb7ffe590da30342
TASK031_PUBLICATION=de8484e203b8b6e259dac90349d44069fc5a6ed0
TECHNICAL_SHA=6cd35a82612b4e275ff7ccdacb7ffe590da30342
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=PINNED_filetype_v1.1.3_SCRATCH_ONLY_NATIVE_FEASIBILITY_19_PROOFS
ALLOWED_PATHS=handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_RETRY_D_20261006-200544.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_PATHS;SWIFT_TESTS_DOCS_XCODE_SCHEMA_STORAGE_DEPENDENCY_MANIFEST_VENDOR_MODEL_RESOURCE_HELPER_BINARY;STATE/PROJECT_STATE.md;STATE/RULE_PROMOTION_LEDGER.tsv;HISTORICAL_HANDOFFS;PRODUCTION_INTEGRATION;ALTERNATE_PROVIDER;AUTOMATIC_NEXT
SUCCESS_CRITERIA=ALL_19_HARD_PROOFS_EVIDENCED_WITH_ALL_WRITABLE_GO_STATE_UNDER_SCRATCH
VALIDATIONS=PIN_SOURCE_INSPECTION;SCRATCH_GO_TESTS;TWO_CLEAN_BUILDS;BINARY_INSPECTION;BOUNDARY_AND_CONTAINER_RUNS;NONPRIVILEGED_LSOF_PS;SOURCE_REVIEW;DIFF_CHECK;FINALIZER_PARITY_CHECKER_PUSH_FETCH
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=STOP
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY_PENDING_BRAIN
PROVIDER_PRODUCTION_SELECTED=NO
INTEGRATION_AUTHORIZED=NO

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=21
WORKER_REQUIREMENTS_NOT_APPLICABLE=0
WORKER_REQUIREMENTS_UNPROVEN=3
WORKER_POSTFLIGHT=FAIL
NEXT_TASK_STARTED=NO

Guard counts:19 proof obligations (17 evidenced,2 unproven) plus5 execution
obligations below (4 evidenced,1 failed containment guarantee counted among
unproven obligations). A checker mechanics PASS cannot convert this STOP into
a successful feasibility result. Closure checks are pending at immutable-source
creation and their actual receipts belong in Desktop/final return.

## STOP cause — separate from noMatch semantics

FACT: noMatch semantics and pin/native/input/process/reproducibility observations
succeeded. The spike stopped because the Worker configured a nonfunctional
Go tool telemetry override: GOTELEMETRY=off. Exact local Go source documents
GOTELEMETRY as a non-settable go-env value and initializes telemetry using the
user configuration directory. Go cmd/internal/telemetry uses TEST_TELEMETRY_DIR
for explicit relocation; that variable was not set in the executed environment.
Default mode is local when no mode file exists. Setting GOTELEMETRY in the
process environment did not turn local counters off.

FACT: seven current Go1.27.1 counter files were freshly observed at
/Users/cenvu/Library/Application Support/go/telemetry/local, outside scratch:
go, gofmt, compile, asm, link, vet, nm. Their 16384-byte files have Oct6 task-time
mtimes (19:55 through19:59 +07). The directory existed previously (Aug22).
A local report and upload.token also have a task-time mtime. The exact observed
paths/stats are in scratch inspection/toolchain-containment-failure.json.
The absence of a mode file and inspected default-local source support local
collection, with no evidence of a telemetry network upload; no network-upload
claim is made for the build tool. This is distinct from the proven zero-socket,
zero-telemetry-code helper process.

ROOT_CAUSE=ENVIRONMENT_CONTROL_NOT_SUPPORTED;WRITABLE_TOOL_TELEMETRY_NOT_RELOCATED
SCRATCH_CONTAINMENT=FAILED
UNAUTHORIZED_GLOBAL_CONFIG_EDIT=NONE
OWNER_TELEMETRY_FILES_REMOVED_OR_REWRITTEN=NO
REPAIR_ATTEMPTS=0

The Worker stopped further Go invocation and feasibility work on detecting
this breach. No cleanup of unknown/preexisting user state, system installation,
production change or silent fallback was attempted. Re-running builds cannot
undo the original containment breach. A future BRAIN-authorized retry would
need source-verified scratch telemetry relocation and an off-mode file created
only there before any Go invocation; this report does not authorize that retry.
License closure and exact registered inventory remain explicitly unproven.

## Required proof summary

TARGET=filetype_v1.1.3
PROOF_01=EVIDENCED
PROOF_02=EVIDENCED
PROOF_03=EVIDENCED
PROOF_04=EVIDENCED
PROOF_05=UNPROVEN
PROOF_06=EVIDENCED
PROOF_07=EVIDENCED
PROOF_08=EVIDENCED
PROOF_09=EVIDENCED
PROOF_10=EVIDENCED
PROOF_11=EVIDENCED
PROOF_12=EVIDENCED
PROOF_13=EVIDENCED
PROOF_14=EVIDENCED
PROOF_15=EVIDENCED
PROOF_16=EVIDENCED
PROOF_17=EVIDENCED
PROOF_18=UNPROVEN
PROOF_19=EVIDENCED
PROOFS_EVIDENCED=17/19
PROOFS_FAILED=0/19
PROOFS_UNPROVEN=2/19
MODULE_SUM=h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=
MODULE_GOMODSUM=h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY=
TOOLCHAIN=go1.27.1_darwin_arm64
TOOLCHAIN_SOURCE=EXISTING_LOCAL_/opt/homebrew/Cellar/go/1.27.1/libexec_COPIED_TO_SCRATCH;NO_HOMEBREW_COMMAND_OR_INSTALL
TOOLCHAIN_SHA256=LOCAL_GO_EXECUTABLE:548608a910c46de32c65a3934f461b1787acf6ddd371044826068d8503b8509b
TOOLCHAIN_ARCHIVE_SHA256=NOT_APPLICABLE_NO_ARCHIVE_DOWNLOAD
BINARY_ARCH=arm64_ONLY
MINOS=13.0
OTOOl_LIBRARIES=/usr/lib/libSystem.B.dylib|/usr/lib/libresolv.9.dylib
UNKNOWN_MAPPING=no_match_ALL_FIVE_METADATA_NULL
ZERO_BYTE_MAPPING=EXACT_ErrEmptyBuffer_PLUS_len0_PLUS_Unknown_TO_no_match_ALL_METADATA_NULL
NETWORK_STATIC=HELPER_GRAPH_NO_CLIENT_DOWNLOADER_TELEMETRY;77_PACKAGES;NO_NET_IMPORT
NETWORK_RUNTIME=THREE_LIVE_HELPERS_NO_NETWORK_OR_UNIX_SOCKET;LSOF_ALL_EXIT0;NETWORK_QUERY_EXIT1_EMPTY_NO_ERROR
DESCENDANTS=0_LIVE_AND_AFTER_NORMAL_SIGTERM_SIGKILL;ALL_REAPED
REPRO_SHA256_A=e7907f75903da75b5a3649f8fc894ac304fadef17d126ca37f2b76cd2ec8e2d6
REPRO_SHA256_B=e7907f75903da75b5a3649f8fc894ac304fadef17d126ca37f2b76cd2ec8e2d6
LICENSE_CLOSURE=UNPROVEN_STOP_BEFORE_FINAL_NOTICE_RECONCILIATION
MATCHER_INVENTORY=PARTIAL_73_SOURCE_TYPE_DECLARATIONS;EXACT_REGISTRATION_RECONCILIATION_UNPROVEN
SCRATCH_PATH=/tmp/FSD-filetype029R/
MODEL_PRESENT=NO
MODEL_VERSION=null
CONFIDENCE=null
HELPER_SOURCE_SHA256=73b1ed19129fef5abe6b1d8b901150887a4678d0ad4485bc75275601249e438e

## Proof and requirement map

| Proof | Requirement | Status | Evidence and limit |
|---|---|---|---|
| 01 | Native build | EVIDENCED | FACT: two go build -a commands exit0; Go1.27.1 darwin/arm64; CGO0 GOOSdarwin GOARCHarm64. |
| 02 | No runtime interpreter | EVIDENCED | FACT: native direct execution with env={}; no Python/JVM/Node/Homebrew/classifier runtime dependencies. Python is the scratch test harness only. |
| 03 | Self-contained helper shape | EVIDENCED | FACT: file/lipo/otool/go version-m; one3861970-byte binary, no classifier resources/models/databases. Two macOS system dylibs recorded below. |
| 04 | Dependency closure | EVIDENCED | FACT: upstream go.mod contains module + go1.13 only; go list-m all has scratch and sole pinned filetype; deps77 =72 Go standard packages +4 filetype packages +scratch. No third-party module dependency of filetype. |
| 05 | License/notice closure | UNPROVEN | STOP before completing notice closure. MIT, Go BSD3/PATENTS and linked math.log Sun notice identified; final redistribution notice inventory was not completed. No legal conclusion. |
| 06 | Bounded inputs | EVIDENCED | FACT: runtime0/4/32/4096/4097 exercised; scratch call-count test observes Match once for <=4096 and never for4097/9000; LimitReader ceiling4097. |
| 07 | No source authority | EVIDENCED | FACT: len(os.Args)==1; actual path argument rejected; production scratch entrypoint uses only os.Stdin and filetype.Match. No MatchFile/MatchReader/os.Open/URL/callback in helper source; path wrappers dead-stripped. |
| 08 | Truthful result mapping | EVIDENCED | FACT: known PNG -> upstream png/image/png; nonempty Unknown,nil -> no_match; exact len0 ErrEmptyBuffer+Unknown -> no_match; all metadata null; other errors tested failed. |
| 09 | Detector provenance | EVIDENCED | FACT: exact v1.1.3/h1/GoModSum/info date/Go version/helper SHA/flags below; official module metadata supplies no Origin/VCS hash, explicitly UNKNOWN. |
| 10 | No model | EVIDENCED | FACT: matcher sources implement code/magic signatures, no model resources or dependency; all31 outputs modelVersion=null. |
| 11 | No synthetic confidence | EVIDENCED | FACT: helper never sets confidence; all31 envelopes confidence=null; no score invented. |
| 12 | Zero helper network/telemetry/downloader | EVIDENCED | FACT: helper/filetype transitive graph has no net, HTTP client, downloader, telemetry, os/exec or plugin. Three live helper inspections show stdin PIPE, no socket/endpoint; lsof-all exit0, network query exit1 empty/no error. Go BUILD TOOL telemetry is a separate containment FAILURE below. |
| 13 | No descendants | EVIDENCED | FACT: three live ps trees have zero descendants; normal exit0, SIGTERM-15, SIGKILL-9 all reaped; postexit zero descendants and PID absent. Helper source launches none. |
| 14 | Architecture | EVIDENCED | FACT: file=Mach-O64 arm64; lipo=Non-fat arm64 only. |
| 15 | Minimum deployment | EVIDENCED | FACT: vtool LC_BUILD_VERSION MACOS minos13.0 sdk26.2; 13.0<=15.0. |
| 16 | Reproducible artifact | EVIDENCED | FACT: two initially empty independent source/build dirs, source/module bytes equal, shared pinned cache/toolchain/env/flags, -a forces both rebuilds; SHA256_A==SHA256_B below. No reproducibility repair needed. |
| 17 | Slice03 host compatibility comparison | EVIDENCED | FACT/STRONG_INFERENCE: actual raw stdin+EOF, schema1 seven fields, normal exits and strict metadata bounds fit inspected host parser; stderr0; host empty env and arguments reproduced; termination/crash are reaped, host cancellation/crash guards preserved; timeout stays host-owned. Comparison only, no host integration/bundling/test mutation. |
| 18 | Registered matcher inventory | UNPROVEN | STOP before completing exact registration inventory reconciliation. Partial source scan identified73 type declarations across7 category files; no final inventory validation or product coverage decision performed. |
| 19 | No sampled-byte persistence | EVIDENCED | FACT: complete helper source below has no file write/hash/log/echo/sample diagnostics; derived envelope only on stdout; all31 stderr0; live descriptors0/1/2 pipes; empty working directory remains empty. Test harness/module fixtures are external scratch, not helper sample persistence. |

| Execution obligation | Status | Evidence |
|---|---|---|
| R20 Identity/authorization/fresh base | EVIDENCED (FACT) | Clean3-commit BRAIN-only fast-forward de8484e -> exact6cd35a8 after fetch; accepted STATE gate029R and task031 acceptance freshly read; only selected pin acquired. |
| R21 All writable Go state scratch-only | FAILED / UNPROVEN completion obligation | Seven Go build-tool counter files plus report/token outside scratch; unsupported environment override; stop and preserve. |
| R22 Tracked allowlist/protected state | EVIDENCED (FACT) | Preclosure all tracked file SHA256 bytes equal captured base; no untracked repo files. Finalizer allows exactly4 closure paths and preserves all history/state authority. |
| R23 Fresh postflight performed | EVIDENCED (FACT) | Full scratch helper/env/logs and artifact receipts reviewed, diffcheck0, base/upstream re-fetched equal. Postflight resultFAIL for containment + unfinished proofs. |
| R24 No production selection/integration/next | EVIDENCED (FACT) | No Swift/tests/app/dependency/artifact/source-reader/storage/schema changes. No032 or alternate provider/strategy work. Proposed return only to BRAIN. |

## Module and build provenance

Official Go module infrastructure only: GOPROXY=https://proxy.golang.org,
GOSUMDB=sum.golang.org. Exact download command (scratch module cwd):
/tmp/FSD-filetype029R/toolchain/bin/go mod download -json github.com/h2non/filetype@v1.1.3
Exit0; Versionv1.1.3; Sum/GoModSum above. Official .info gives
{"Version":"v1.1.3","Time":"2021-11-21T11:21:08Z"}.
Origin was not supplied; VCS commit identity remains UNKNOWN rather than guessed.
No @latest, git clone, provider switch, arbitrary download or Go archive acquired.
The expected accepted module sum exactly matched before any helper build.
Go mod verify exit0: all modules verified. go list -mod=readonly -m all exit0
lists only scratch and github.com/h2non/filetype v1.1.3. Upstream go.mod contains
only module declaration and go1.13; no upstream go.sum/require/third-party module.
Scratch go.sum has exactly the module and its go.mod sums.

Go toolchain was already installed locally. The existing libexec tree was copied
to scratch/toolchain; its license was found at the installed parent LICENSE and
copied into the scratch toolchain. No Homebrew command/install, pkg/system install,
official archive download or extraction occurred. TOOLCHAIN_SHA256 labels the
observed local go executable, not an official archive checksum or distribution
attestation. Exact Go version output: go version go1.27.1 darwin/arm64.

Build env actual: GOROOT=scratch/toolchain; GOPATH=scratch/gopath;
GOMODCACHE=scratch/gomodcache; GOCACHE=scratch/gocache; GOTMPDIR=scratch/gotmp;
GOTOOLCHAIN=local; GOENV=off; CGO_ENABLED=0; GOOS=darwin; GOARCH=arm64;
GOPROXY/GOSUMDB as above; GOTELEMETRY=off (ineffective, explicit failure).
The ordinary inherited HOME was never reassigned. Toolchain telemetry therefore
used its user default, violating writable-state containment despite other caches
being correctly relocated. Complete actual env is local scratch/env.json only;
not copied into handoff or remote transport.

Both independent build commands, in initially clean scratch/buildA and buildB:
/tmp/FSD-filetype029R/toolchain/bin/go build -a -mod=readonly -trimpath -buildvcs=false -ldflags=-buildid= -o helper .
Each source dir received identical main.go/go.mod/go.sum; no test source;
same toolchain/cache/env/flags; -a forces compilation twice; both exit0 with
empty stderr. Build source SHA above; flags suppress absolute path/VCS/buildID
variance. Both exact SHA256 values are equal; no repair attempt required.

go version-m lists go1.27.1; scratch module(devel); filetypev1.1.3/module sum;
-buildmodeexe;-compilergc;-trimpathtrue;CGO0;GOARCHarm64;GOOSdarwin;GOARM64v8.0.
file/lipo report native thin arm64. vtool shows LC_BUILD_VERSION MACOS,
minos13.0/sdk26.2/ntools0. otool-L lists only the two system dylibs above,
compatibility/current versions1.0.0 for libSystem and0.0.0 for libresolv.
The resolver dylib is recorded rather than concealed: graph has no net client,
nm-u has no resolver/socket/connect import, and live lsof has no socket. Standard
Go os/platform support retains generic open/execve symbols; these are not called
by the helper. No claim that every generic OS primitive is removed from binary.

## Exact zero-byte authorization and helper source

Pinned match.go: Match checks len(buf)==0 first and returns types.Unknown,
ErrEmptyBuffer at lines21-24; otherwise loops in-memory matchers and returns
Unknown,nil when none match. Exact filetype.go defines the dedicated sentinel
at lines19-20; full module Go-source search finds no other return site for it.
That authoritative narrow condition supports the user-approved empty-input rule.
The scratch helper additionally requires len0+Unknown before converting that
sentinel. ErrUnknownBuffer, a different/synthetic error, and any nonzero-input
ErrEmptyBuffer stay failed. Upstream MatchFile/MatchReader exist but are neither
called nor linked; MatchReader's8192 buffer is unrelated to this byte-only seam.
No source-reader ceiling or eligibility code changed.

The complete scratch main.go, shared by both builds, is metadata-only:

```go
package main

import (
	"encoding/json"
	"io"
	"os"

	"github.com/h2non/filetype"
	"github.com/h2non/filetype/types"
)

const maximumInput = 4096
const detectorIdentity = "github.com/h2non/filetype@v1.1.3"

type envelope struct {
	SchemaVersion   int      `json:"schemaVersion"`
	ResultKind      string   `json:"resultKind"`
	DetectedType    *string  `json:"detectedType"`
	MIMEType        *string  `json:"mimeType"`
	Confidence      *float64 `json:"confidence"`
	DetectorVersion *string  `json:"detectorVersion"`
	ModelVersion    *string  `json:"modelVersion"`
}

func classify(input io.Reader, match func([]byte) (types.Type, error)) envelope {
	result := envelope{SchemaVersion: 1, ResultKind: "failed"}
	buf, err := io.ReadAll(io.LimitReader(input, maximumInput+1))
	if err != nil || len(buf) > maximumInput {
		return result
	}
	kind, err := match(buf)
	if err == filetype.ErrEmptyBuffer && len(buf) == 0 && kind == filetype.Unknown {
		result.ResultKind = "no_match"
		return result
	}
	if err != nil {
		return result
	}
	if kind == filetype.Unknown {
		result.ResultKind = "no_match"
		return result
	}
	if kind.Extension == "" {
		return result
	}
	result.ResultKind = "classified"
	result.DetectedType = &kind.Extension
	if kind.MIME.Value != "" {
		result.MIMEType = &kind.MIME.Value
	}
	version := detectorIdentity
	result.DetectorVersion = &version
	return result
}

func main() {
	result := envelope{SchemaVersion: 1, ResultKind: "failed"}
	if len(os.Args) == 1 {
		result = classify(os.Stdin, filetype.Match)
	}
	encoded, err := json.Marshal(result)
	if err != nil || len(encoded)+1 > 4096 {
		os.Exit(1)
	}
	encoded = append(encoded, '\n')
	if n, err := os.Stdout.Write(encoded); err != nil || n != len(encoded) {
		os.Exit(1)
	}
}
```

Scratch deterministic Go unit tests:3 executed/3 passed/0 skipped/0 failed,
go test -mod=readonly -count=1 -v ./... exit0. They prove <=4096 exactly one
Match call, >4096 zero calls, specific empty sentinel only, errors remain
failed, and input read error does not call detector. No sleeps added.
These are throwaway scratch tests, not production integration or permanent FSD
regressions. Causal RED for product behavior is not applicable to this spike;
no FSD code behavior was changed. Existing accepted task031 tests were read as
evidence only; no FSD/Xcode tests or full suite rerun in029R.

## Actual bounded-input/container observations

31 direct native invocations, env={}, zero helper command arguments except
the deliberate argument-rejection negative case. All normal exits0; stderr0;
stdout is one seven-field envelope, <=4096; every nonclassified envelope has
all5 metadata=null. confidence/modelVersion=null in every case. This is a
bounded compatibility exercise, not an accuracy benchmark. Harness reads only
<=4096-byte prefixes from exact module fixtures; original sources remain read-only.

| Case | Input bytes | Result kind | Direct detectedType | Direct MIME |
|---|---|---|---|---|
| empty | 0 | no_match | null | null |
| small-known-png | 4 | classified | png | image/png |
| small-unknown | 32 | no_match | null | null |
| unknown-4096 | 4096 | no_match | null | null |
| known-4096 | 4096 | classified | png | image/png |
| reject-4097 | 4097 | failed | null | null |
| reject-source-path-argument | 0 | failed | null | null |
| sample.zip-prefix-4 | 4 | classified | zip | application/zip |
| sample.zip-prefix-32 | 32 | classified | zip | application/zip |
| sample.zip-prefix-4096 | 4096 | classified | zip | application/zip |
| sample.docx-prefix-4 | 4 | classified | zip | application/zip |
| sample.docx-prefix-32 | 32 | classified | zip | application/zip |
| sample.docx-prefix-4096 | 4096 | classified | docx | application/vnd.openxmlformats-officedocument.wordprocessingml.document |
| sample.xlsx-prefix-4 | 4 | classified | zip | application/zip |
| sample.xlsx-prefix-32 | 32 | classified | zip | application/zip |
| sample.xlsx-prefix-4096 | 4096 | classified | xlsx | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet |
| sample.pptx-prefix-4 | 4 | classified | zip | application/zip |
| sample.pptx-prefix-32 | 32 | classified | zip | application/zip |
| sample.pptx-prefix-4096 | 4096 | classified | pptx | application/vnd.openxmlformats-officedocument.presentationml.presentation |
| sample.mp4-prefix-4 | 4 | no_match | null | null |
| sample.mp4-prefix-32 | 32 | classified | mp4 | video/mp4 |
| sample.mp4-prefix-4096 | 4096 | classified | mp4 | video/mp4 |
| sample.mov-prefix-4 | 4 | no_match | null | null |
| sample.mov-prefix-32 | 32 | classified | mov | video/quicktime |
| sample.mov-prefix-4096 | 4096 | classified | mov | video/quicktime |
| sample.mkv-prefix-4 | 4 | no_match | null | null |
| sample.mkv-prefix-32 | 32 | no_match | null | null |
| sample.mkv-prefix-4096 | 4096 | classified | mkv | video/x-matroska |
| sample.webm-prefix-4 | 4 | no_match | null | null |
| sample.webm-prefix-32 | 32 | no_match | null | null |
| sample.webm-prefix-4096 | 4096 | classified | webm | video/webm |

Short OOXML fixture prefixes classify as generic upstream ZIP. Four-byte
MP4/MOV and4/32-byte MKV/WebM prefixes return no_match. The4096-byte inspected
fixtures return their direct specific upstream types. No claim of container
coverage beyond those prefixes, no fallback to additional bytes, and no
application/octet-stream substitution for Unknown. A registered known upstream
EOT type does use application/octet-stream as its own MIME declaration; unknown
never inherits it. Generic/bounded limits remain matters for later product review.

## Live process/network proof

Harness starts helper with stdin pipe kept open; helper naturally blocks in
ReadAll waiting for input/EOF (ps stateS). Before any payload delivery, lsof-nP-p
returns0 and shows only cwd/program/dyld mappings and descriptors0/1/2 PIPE;
no IPv4/IPv6/Unix socket. lsof-nP-a-pPID-i returns1 with empty stdout/stderr;
combined with positive all-FD listing this is no matching network socket,
not a failed permission inspection. ps-axo pid,ppid,stat,comm snapshot computes
transitive children; no children before or after each exit; helper PID reaped.
Normal completion provides input then EOF and receives no_match. SIGTERM and
SIGKILL act while waiting on stdin; no output/diagnostic. No sudo/firewall/packet
capture/process descendants/runtime interpreter. Go's OS threads are not children.

| Exit case | PID | Live ps state | Live descendants | Post descendants | Exit | Reaped |
|---|---|---|---|---|---|---|
| normal | 55951 | S | 0 | 0 | 0 | YES |
| SIGTERM | 55957 | S | 0 | 0 | -15 | YES |
| SIGKILL | 55963 | S | 0 | 0 | -9 | YES |

Static graph77packages contains72 standard packages and4 filetype packages:
filetype, types, matchers, matchers/isobmff, plus scratch main. No net/net-http,
telemetry/downloader/plugin/os-exec package attributable to helper/filetype.
Helper source imports encoding/json,io,os,filetype,types only. No goroutine,
watcher, daemon, telemetry or downloader in helper or matchers. Build-tool Go
telemetry is outside that graph and is the explicit task containment breach.

Host comparison inspected current BundledMagikaClassificationProvider parser
and runner plus runtime timeout/cancellation/no-row path: raw stdin once then
EOF; empty environment/zero args; seven fields/schema integer1; stdout4096,
stderr4096 discarded; strings<=256/no controls; normal status0/no crash required;
no_match all-null accepted; crash/nonzero fails; cancellation wins under host
lock; terminate/kill/close/reap owned by host; five-second timeout host-owned.
Scratch native envelopes and process behavior fit these constraints. No host
launch/bundle installation/integration proof is claimed or required here.

## Unfinished license and inventory work

FACT: pinned filetype LICENSE is MIT, copyright Tomas Aparicio, full notice
required in future bundled distribution materials. Identified exact file/digest:
module/LICENSE SHA256 85ffa04d14965497779ceb017229dae1448f470c62db422c97a14a4ce66c95b7.
Go LICENSE at local installed parent (copied to scratch/toolchain/LICENSE) is
Go Authors BSD3, including binary notice requirement; SHA256
911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad. Go PATENTS SHA256
96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc records additional IP grant.
Selected Go math/log.go has an inherited Sun1993 permission notice requiring
preservation; linked math.log was observed by go-tool-nm. Exact file/digest:
d8675d3d9c665ec0db5cc15478c03efb244301bfa1268d02ae1861bf6f2812ab.
The compiled-source notice scan also found source notices for unused math
functions; final linked/redistribution notice closure had not been completed
when containment STOP occurred. Go tool vendor modules are not present in the
helper import graph. These engineering observations are not legal advice and
do not satisfy the final license-closure proof.

Partial declaration scan: Application3; Archive28; Audio9; Document6; Font4;
Image13; Video10 =73 declared upstream types. Registration source prepends
Application/Image/Video/Audio/Font/Document/Archive category precedence, but
iterates each category's Go map, so within-category matcher order is not fixed.
Legacy Doc/Xls/Ppt can share four-byte signatures in source, a factual ambiguity
for later product review; no ranking/accuracy score or altered registry was
introduced. Exact registered inventory reconciliation stopped unfinished,
so declaration counts are not claimed as a final supported-product inventory.

## RAW pointers, scope and closure

All helper/module/toolchain/source/tests/binaries/fixtures/logs/inspection material
is outside repository under scratch. No executable/resource enters FSD.app.
RAW: logs/module-download.json; module/go.mod and go.sum; logs/modules.stdout;
logs/deps.stdout; inspection/deps.json; logs/verify.stdout; logs/tests.stdout;
logs/buildA.json and buildB.json; inspection/file.txt,lipo.txt,otool-libraries.txt,
minos.txt,buildinfo.txt,nm.txt,go-symbols.txt; logs/input-results.json;
logs/process-results.json; inspection/artifact-hashes.json;
inspection/compiled-source-notices.json;
inspection/toolchain-containment-failure.json; exercise.py; run_go.py; env.json.
Essential receipts and complete helper source above remain recoverable if /tmp
is cleared. Actual local build env may include inherited private values and
is deliberately not published; it is not product authority or a dependency lock.

Initial main was task031 publication,0ahead/3behind. After fetch, the3BRAIN-only
control commits were fast-forwarded to the exact expected base. Baseline captured
before spike mutation. Fresh preclosure fetch confirms HEAD=origin/main=base,
0/0 and clean; git diff--check exit0. Every tracked file matched baseline SHA256
and no untracked repo file existed before closure. No historical handoff edited,
no protected STATE/product/docs/schema/source/tests/app/dependency delta.
The sole known technical SHA is the accepted base/basis; this task has no tracked
implementation commit. Finalizer appends one Worker ledger/event and creates
this immutable source plus exact CURRENT. Prepublication HOT is actual base/time;
future publication is resolved by handoff git-log, not inserted into immutable
self-containing source. Desktop preserves dated BRAIN-owned state, adds fresh
accepted-state pointers, canonical Operator raw bytes/digest and full CURRENT.
Checker runs exact4-path allowlist; push/fetch/parity/clean/sync checks remain
pending at creation and are reported only once actually observed.

Worker-local STOP is an incomplete spike, not rejection/selection of the provider.
BRAIN must adjudicate containment failure,17/19 partial proofs and next strategy.
No production integration, task032, retry repair or alternate provider started.
The only proposal is the HOT return to BRAIN for strategy adjudication.
