# filetype v1.1.3 feasibility closure — PASS_WITH_ADVISORY

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD_DEMO_CRITICAL_PATH
HANDOFF_ID=handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_D_20261006-202845.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=533c22db54f224d47f3720e488a77e242d1959e5
REMOTE_HEAD=533c22db54f224d47f3720e488a77e242d1959e5
LAST_VERIFIED_AT=2026-10-06T20:28:45+07:00
AUTHORITY_PTRS=AGENTS.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/BRAIN_OPERATOR.md|STATE/PROJECT_STATE.md|handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_SPIKE_RETRY_D_20261006-200544.md
CURRENT_PHASE=DEMO_SPRINT
CURRENT_GATE=FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_029S
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_HARD;AMBIGUOUS_TRUNCATED_MATCHER_ORDER_ADVISORY
PROPOSED_NEXT=FSD_CLASSIFIER_FILETYPE_INTEGRATION_CONTRACT_032
NO_AUTO_NEXT=YES

## Task lock and result

TASK=FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_029S
TASK_ID=FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_029S
ROLE=WORKER
MODE=SCRATCH_ONLY_FEASIBILITY_CLOSURE
BASE_HEAD=533c22db54f224d47f3720e488a77e242d1959e5
UPSTREAM_HEAD=533c22db54f224d47f3720e488a77e242d1959e5
EXPECTED_CANONICAL_HEAD=533c22db54f224d47f3720e488a77e242d1959e5
PRIOR_STOP_PUBLICATION=0667a909bec27b326b83774620c19dc5e490b227
TECHNICAL_SHA=533c22db54f224d47f3720e488a77e242d1959e5
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=CORRECTED_GO_CONTAINMENT;FRESH_BUILD_REPRO_SMOKE;PROOF05_NOTICES;PROOF18_REGISTERED_SET;FIXED_INPUT_DETERMINISM
ALLOWED_PATHS=handoffs/FSD_CLASSIFIER_NATIVE_FEASIBILITY_CLOSURE_D_20261006-202845.md|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl
FORBIDDEN_PATHS=ALL_OTHER_REPO_PATHS;SWIFT;DOCS;TESTS;XCODE;SCHEMA;DEPENDENCY_FILES;REPO_OR_APP_HELPER_ARTIFACT;STATE/PROJECT_STATE.md;RULE_PROMOTION_LEDGER;HISTORICAL_HANDOFFS;GLOBAL_OWNER_TELEMETRY;PRODUCTION_INTEGRATION;ALTERNATE_PROVIDER
SUCCESS_CRITERIA=FRESH_CORRECTED_CONTAINMENT;BUILD_HASH_EQUAL_ROOT_CAUSED;LICENSE_NOTICE_CLOSED;REGISTERED_INVENTORY_RECONCILED;REALISTIC_AVAILABLE_FIXTURES_SINGLE_VALUED;SMOKE_AND_PROCESS_PASS
VALIDATIONS=EXACT_LOCAL_SOURCE;SANDBOXED_GO;MODULE_VERIFY;INDEPENDENT_BUILDS;MACHO;CALL_COUNT_TEST;LIVE_LSOF_PS;DWARF_NM_OBJDUMP;SOURCE_AND_READ_ONLY_INTROSPECTION;FRESH_PROCESS_RESULT_SETS;GLOBAL_METADATA_PARITY;CONTROL_PLANE_PUBLICATION
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY
RESULT=PASS_WITH_ADVISORY
RESULT_AUTHORITY=WORKER_EVIDENCE_ONLY_PENDING_BRAIN
PROVIDER_PRODUCTION_SELECTED=NO
INTEGRATION_AUTHORIZED=NO

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=21
WORKER_REQUIREMENTS_NOT_APPLICABLE=3
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

FACT: task029R remains BRAIN-accepted STOP. This return closes specified gaps with
fresh task029S evidence; it does not relabel the prior task. Its unchanged helper
source, exact binary identity and explicit accepted partial proofs support carry
forward only for the remaining unchanged semantics. Publication checks are
finalizer obligations; actual final receipts belong in Desktop and terminal return.

## Corrected containment and module provenance

GLOBAL_TELEMETRY_BEFORE_AFTER=IDENTICAL_15_ENTRIES_METADATA_ONLY
TEST_TELEMETRY_DIR=/tmp/FSD-filetype029S/go-telemetry
OUTSIDE_SCRATCH_WRITES=0_GO_TOOL_PERSISTENT_WRITES;OS_SANDBOX_ENFORCED
NEW_GLOBAL_TELEMETRY_FILES=0
GLOBAL_TELEMETRY_MTIME_CHANGES=0
GLOBAL_TELEMETRY_SIZE_CHANGES=0
GLOBAL_TELEMETRY_INODE_CHANGES=0
GLOBAL_OWNER_TELEMETRY_MUTATION=NONE
EXTERNAL_TELEMETRY_UPLOAD=NONE;NETWORK_DENIED_BY_OS
SCRATCH_TELEMETRY_STATE=go-telemetry/mode_ONLY;OFF_MODE_CREATED_DIRECTLY_IN_FRESH_SCRATCH
SCRATCH_PATH=/tmp/FSD-filetype029S/
TOOLCHAIN=go1.27.1_darwin_arm64
TOOLCHAIN_SOURCE=/opt/homebrew/Cellar/go/1.27.1/libexec;READ_AND_COPIED_WITHOUT_HOMEBREW_INVOCATION
TOOLCHAIN_GO_SHA256=548608a910c46de32c65a3934f461b1787acf6ddd371044826068d8503b8509b
TARGET=github.com/h2non/filetype@v1.1.3
MODULE_SUM=h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg=
MODULE_GOMODSUM=h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY=
MODULE_BYTES=REUSED_EXACT_TASK029R_CACHE_IN_FRESH_SCRATCH;GO_MOD_VERIFY_PASS
MODULE_NETWORK_REACQUISITION=NONE

FACT: before the first Go invocation, local VERSION identified Go1.27.1. Exact
src/cmd/internal/telemetry/counter/counter.go:22-24 calls
counter.OpenDir(os.Getenv("TEST_TELEMETRY_DIR")). telemetry.go:29-35 and :42-47
pass that same variable in both parent and child Config.TelemetryDir. Vendored
x/telemetry/start.go:145-154 and :254-256 relocate telemetry.Default; parent returns
when mode is off. internal/telemetry/dir.go:124-144 reads the relocated mode file.
The Worker wrote only fresh scratch mode bytes `off` plus LF before Go started.
No GOTELEMETRY setting or `go telemetry` command was used. No owner mode was read
for content or changed. Upload was additionally denied by the OS sandbox.

Every Go command, Go tool, go-run/test subprocess and compiler/linker child inherits
this explicit scratch environment:

```json
{
  "PATH": "/tmp/FSD-filetype029S/toolchain/bin:/usr/bin:/bin:/usr/sbin:/sbin",
  "HOME": "/tmp/FSD-filetype029S/home",
  "XDG_CONFIG_HOME": "/tmp/FSD-filetype029S/xdg-config",
  "XDG_CACHE_HOME": "/tmp/FSD-filetype029S/xdg-cache",
  "GOROOT": "/tmp/FSD-filetype029S/toolchain",
  "GOPATH": "/tmp/FSD-filetype029S/gopath",
  "GOMODCACHE": "/tmp/FSD-filetype029S/gomodcache",
  "GOCACHE": "/tmp/FSD-filetype029S/gocache",
  "GOTMPDIR": "/tmp/FSD-filetype029S/gotmp",
  "TMPDIR": "/tmp/FSD-filetype029S/gotmp",
  "GOENV": "off",
  "GOTOOLCHAIN": "local",
  "TEST_TELEMETRY_DIR": "/tmp/FSD-filetype029S/go-telemetry",
  "CGO_ENABLED": "0",
  "GOOS": "darwin",
  "GOARCH": "arm64",
  "GOPROXY": "off",
  "GOSUMDB": "off"
}
```

The runner wraps the scratch Go executable in `/usr/bin/sandbox-exec -f go.sb`:

```scheme
(version 1)
(allow default)
(deny file-write*)
(allow file-write* (subpath "/private/tmp/FSD-filetype029S") (subpath "/tmp/FSD-filetype029S"))
(allow file-write-data (literal "/dev/null"))
(deny network*)
```

The allowlist permits persistent writes only under the scratch path and its macOS
/private/tmp physical alias. /dev/null is a nonpersistent sink. stdout/stderr are
inherited pipes captured by the scratch harness. All network operations are denied;
pinned bytes were reused offline. This policy propagates to children. The runner
compares owner telemetry metadata against the original baseline before and after
each Go command and aborts on any delta. All twelve Go command receipts exited0.
After the last Go tool invocation, the same metadata snapshot remained identical.
No cleanup/retry over a breach occurred. The initial pre-Go baseline script exposed
a tracked broken symlink; baseline hashing was corrected to hash the link target
text rather than dereference it. No Go command had run and no owner state changed.

Only the following metadata was recorded for global telemetry, relative to
~/Library/Application Support/go/telemetry. Before and after share every value;
file contents were neither read nor published. Type d=directory, -=regular file.

| Relative path | Type | Size | mtime ns | Inode |
|---|---|---:|---:|---:|
| . | d | 128 | 1787406821705531875 | 83445533 |
| local | d | 448 | 1791291542555712203 | 83445534 |
| local/asm@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291445675486915 | 185081689 |
| local/compile@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291445612868258 | 185081618 |
| local/go@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291330666939315 | 185025553 |
| local/gofmt@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291445286623185 | 185081220 |
| local/link@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291449573719235 | 185083506 |
| local/local.2026-08-29.json | - | 708 | 1789722984029188774 | 121947942 |
| local/local.2026-09-19.json | - | 360 | 1790145942871301387 | 135212376 |
| local/local.2026-09-26.json | - | 708 | 1791291330682011425 | 185025555 |
| local/nm@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291542555805911 | 185087847 |
| local/upload.token | - | 0 | 1791291330667850601 | 185025554 |
| local/vet@go1.27.1-go1.27.1-darwin-arm64-2026-10-06.v1.count | - | 16384 | 1791291445859206249 | 185081928 |
| local/weekends | - | 2 | 1787406821692128813 | 83445535 |
| upload | d | 64 | 1787406821705524459 | 83445538 |

## Fresh build, boundaries and live helper

BUILD_A=PASS
BUILD_B=PASS
SHA256_A=e7907f75903da75b5a3649f8fc894ac304fadef17d126ca37f2b76cd2ec8e2d6
SHA256_B=e7907f75903da75b5a3649f8fc894ac304fadef17d126ca37f2b76cd2ec8e2d6
PRIOR_HASH_MATCH=YES
ARCH=arm64_ONLY
MINOS=13.0
HELPER_SOURCE_SHA256=73b1ed19129fef5abe6b1d8b901150887a4678d0ad4485bc75275601249e438e
EXTRA_NON_SYSTEM_DYLIB_OR_RESOURCE=NONE
NETWORK_RUNTIME=NONE_LIVE_HELPER;LSOF_NETWORK_EXIT1_EMPTY_NO_ERROR
NETWORK_SOCKET=NONE
DESCENDANTS=0

FACT: independent initially empty buildA/buildB source dirs contain copied exact
029R main.go, go.mod and go.sum. The old scratch module identity
fsd-filetype029r-scratch is intentionally retained to compare identical build
semantics. Both execute:

```text
go build -a -mod=readonly -trimpath -buildvcs=false -ldflags=-buildid= -o helper .
```

CGO_ENABLED=0, GOOS=darwin and GOARCH=arm64; both exit0 with empty stderr.
The -a flag independently rebuilds packages even with the shared scratch cache.
Artifact SHA256 is identical to the prior accepted partial artifact, so no mismatch
requires explanation. Exact `go version -m` reconfirms pin, CGO0, trimpath and arm64.
file/lipo show a non-fat arm64 executable. vtool shows MACOS minos13.0/sdk26.2;
13.0<=15.0. otool-L lists only /usr/lib/libSystem.B.dylib and
/usr/lib/libresolv.9.dylib, both compatibility/current version0.0.0. These are
system dependencies, not extra bundled libraries or classifier resources.

Fresh production-helper observations, env empty, no arguments, raw stdin+EOF:
PNG->classified/png/image/png; unknown->no_match; empty->no_match;
4096 zero bytes->no_match; 4097->failed. No-match/failed have all five metadata
fields null; classified has null confidence/modelVersion. All exits0, stderr0,
output<=4096. Fresh scratch call-count test proves Match called once at <=4096
and zero times at 4097/9000; specific empty sentinel and input-error tests pass.
The reused tests live only in scratch; no FSD test suite was run or modified.

One direct live helper blocked on stdin (PID68775) was inspected without a runtime sandbox.
lsof-all exit0/no error, descriptors pipes + executable/system mappings, no
IPv4/IPv6/Unix socket; lsof -a -p PID -i exit1/empty/no error. Full ps parent
closure shows zero descendants. EOF returns0/no stderr and the harness reaps it.
Empty helper working directory remains empty. No sampled bytes are persisted,
hashed, echoed or logged by the helper or probe harness.

## Proof05 — engineering redistribution notice inventory

LICENSE_NOTICE_CLOSURE=EVIDENCED
FILETYPE_NOTICE_FILES=github.com/h2non/filetype@v1.1.3/LICENSE
GO_NOTICE_FILES=Go1.27.1/LICENSE|Go1.27.1/PATENTS
THIRD_PARTY_LINKED_NOTICE_FILES=Go1.27.1/src/math/log.go:17-22
SYSTEM_DYLIB_NOTICE_SCOPE=SYSTEM_LIBRARY_NOT_BUNDLED;/usr/lib/libSystem.B.dylib|/usr/lib/libresolv.9.dylib

Engineering inventory only; no legal opinion, production bundling or integration.
The relevant Go notice covers the statically linked runtime/standard-library code.
Installed LICENSE resides in the Cellar version parent, not libexec; its exact
1453 bytes were copied read-only into scratch toolchain/LICENSE. PATENTS was
already in libexec (1303 bytes). Build tools themselves are not bundled in the helper.

| Material | Identity | Exact file SHA256 |
|---|---|---|
| filetype LICENSE | MIT; Copyright (c) Tomas Aparicio | 85ffa04d14965497779ceb017229dae1448f470c62db422c97a14a4ce66c95b7 |
| Go LICENSE | BSD 3 clause; Copyright 2009 The Go Authors. | 911f8f5782931320f5b8d1160a76365b83aea6447ee6c04fa6d5591467db9dad |
| Go PATENTS | Additional IP Rights Grant; Google | 96f408bfae65bf137fc2525d3ecb030271c50c1e90799f87abf8846d8dd505cc |
| math/log.go full source | SunPro inherited notice plus Go header | d8675d3d9c665ec0db5cc15478c03efb244301bfa1268d02ae1861bf6f2812ab |
| exact log.go lines17-22 with // and LF | Sun Microsystems, Inc., 1993; preserve notice | dbd7c05dff1546ded4c36c34669bfe70b4ed3a6a1d3bf03b131893d7af8cb116 |

FACT: `go list -deps -json .` yields77 packages:72 standard,4 filetype packages and
scratch main. It supplies662 selected standard-library compilation files. A
Mach-O DWARF line-program walk finds342 surviving source-mapped files (including
inline functions, Go runtime assembly, main and module). These are cross-checked
with complete `go tool nm` and targeted objdump, rather than treating package
presence as function linkage. Search every selected standard source and every
additional live mapped source for copyright, license, permission and inherited
source references. Inspect seven physical assembly include headers (Go-owned);
generated go_asm.h is compiler-generated type layout, not a third-party source.
No separate LICENSE/NOTICE/PATENTS files occur directly in these standard package
dirs. No vendored third-party package is in the helper dependency graph.

Twenty selected math source files carry explicit non-Go-Authors copyright.
Only math/log.go is live source-mapped. nm shows math.log at0x1000848e0 and
math.frexp at0x100084860; objdump explicitly maps the linked math.log code to
log.go:88-128 and its Go-owned Frexp/bits helpers. math/log10.go is inlined and
source-mapped with a Go-only header. The full live mapped math set is
bits.go, bits/bits.go, frexp.go, log.go, log10.go, unsafe.go.

LINKED_NOTICE_REQUIRED: filetype MIT, Go LICENSE/PATENTS inventory, Sun log.go
preservation notice. Exact Sun notice is reproduced below. It is not sufficient
to preserve Go's header alone.

SOURCE_PRESENT_BUT_NOT_LINKED: the other19 explicit third-party-notice files below
are selected compiler input but have no surviving DWARF source-code mappings or
linked function symbols; absent/inlined code was checked against the source
mapping, not nm alone. No source code from those functions survives this binary:

- Sun: math/acosh.go, asinh.go, atanh.go, cbrt.go, erf.go, exp.go (2004), expm1.go,
  j0.go, j1.go, jn.go, lgamma.go, log1p.go, remainder.go, sqrt.go.
- Stephen L. Moshier: math/atan.go, gamma.go, sin.go, tan.go, tanh.go.

Other inspected design/algorithm attributions (ChaCha8, Swiss Table/Abseil,
tcmalloc, pdqsort) have Go-Authors BSD headers and no additional inherited license
notice in the selected/live sources. Additional copied math/bits intrinsics have
Go-owned originals. runtime/softfloat64.go's Hacker's Delight references are not
live source-mapped. Platform mentions of BSD in syscall/runtime are not copyright
notices. These observations are scoped to this exact linked helper; a future
import/build change requires a new inventory.

SYSTEM_LIBRARY_NOT_BUNDLED: the two macOS dylib references do not redistribute
those system dylib bytes inside the helper. No system-library notice is added to
the helper redistribution inventory merely from those load commands. No toolchain,
SDK, unrelated platform source or upstream fixture redistribution is proposed.
No unresolved linked notice remains in this exact artifact inventory.

Exact notice material, preserved here for recovery:

```text
The MIT License

Copyright (c) Tomas Aparicio

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
```

```text
Copyright 2009 The Go Authors.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
   * Neither the name of Google LLC nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

```text
Additional IP Rights Grant (Patents)

"This implementation" means the copyrightable works distributed by
Google as part of the Go project.

Google hereby grants to You a perpetual, worldwide, non-exclusive,
no-charge, royalty-free, irrevocable (except as stated in this section)
patent license to make, have made, use, offer to sell, sell, import,
transfer and otherwise run, modify and propagate the contents of this
implementation of Go, where such license applies only to those patent
claims, both currently owned or controlled by Google and acquired in
the future, licensable by Google that are necessarily infringed by this
implementation of Go.  This grant does not include claims that would be
infringed only as a consequence of further modification of this
implementation.  If you or your agent or exclusive licensee institute or
order or agree to the institution of patent litigation against any
entity (including a cross-claim or counterclaim in a lawsuit) alleging
that this implementation of Go or any code incorporated within this
implementation of Go constitutes direct or contributory patent
infringement, or inducement of patent infringement, then any patent
rights granted to you under this License for this implementation of Go
shall terminate as of the date such litigation is filed.
```

```text
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunPro, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
```

## Proof18 — exact registered SET inventory

MATCHER_KEYS_COUNT=73
UNIQUE_REGISTERED_TYPES=73
TYPE_REGISTRY_COUNT=74
UNRECONCILED_TYPES=0
MATCHER_ORDER_SOURCE_DETERMINISTIC=NO

FACT: source registration in matchers/matchers.go:register ranges each category
Map, calls NewMatcher, and NewMatcher prepends keys. Category argument order is
explicit Archive,Document,Font,Audio,Video,Image,Application; observed priority
is reversed by prepending. Within-category order derives from Go map iteration,
so no source-declared stable order exists. `filetype.Match` returns the first
successful matcher from MatcherKeys. The earlier Advisor determinism statement
is contradicted by the exact selected source and cannot be credited.

Source inspection follows every category Map entry to its exact newType extension
and MIME (73 entries,73 declarations). Read-only scratch introspection imports the
pinned module, copies *filetype.MatcherKeys for reporting, ranges filetype.Types,
and sorts only those reporting copies. It never registers/modifies matchers/types,
orders the live MatcherKeys, or calls category matchers. Set equality holds for
source registration and runtime keys. Every runtime type is reconciled.
The extra registry entry is types/defaults.go Unknown=NewType("unknown", ""):
a sentinel with no matcher, not an added classifier format. There are no duplicate
registered keys or hidden aliases. woff/woff2 share application/font-woff and
ttf/otf share application/font-sfnt but are distinct registered extensions.
Convenience API aliases (e.g. Get=Match) are not registered types.

Category counts: {'application': 3, 'archive': 28, 'audio': 9, 'document': 6, 'font': 4, 'image': 13, 'video': 10}.
Sorted reporting set below; row order makes no matcher-priority claim.

| Extension | MIME | Source category |
|---|---|---|
| 3gp | video/3gpp | video |
| 7z | application/x-7z-compressed | archive |
| Z | application/x-compress | archive |
| aac | audio/aac | audio |
| aiff | audio/x-aiff | audio |
| amr | audio/amr | audio |
| ar | application/x-unix-archive | archive |
| avi | video/x-msvideo | video |
| bmp | image/bmp | image |
| bz2 | application/x-bzip2 | archive |
| cab | application/vnd.ms-cab-compressed | archive |
| cr2 | image/x-canon-cr2 | image |
| crx | application/x-google-chrome-extension | archive |
| dcm | application/dicom | archive |
| deb | application/vnd.debian.binary-package | archive |
| dex | application/vnd.android.dex | application |
| dey | application/vnd.android.dey | application |
| doc | application/msword | document |
| docx | application/vnd.openxmlformats-officedocument.wordprocessingml.document | document |
| dwg | image/vnd.dwg | image |
| elf | application/x-executable | archive |
| eot | application/octet-stream | archive |
| epub | application/epub+zip | archive |
| exe | application/vnd.microsoft.portable-executable | archive |
| flac | audio/x-flac | audio |
| flv | video/x-flv | video |
| gif | image/gif | image |
| gz | application/gzip | archive |
| heif | image/heif | image |
| ico | image/vnd.microsoft.icon | image |
| iso | application/x-iso9660-image | archive |
| jp2 | image/jp2 | image |
| jpg | image/jpeg | image |
| jxr | image/vnd.ms-photo | image |
| lz | application/x-lzip | archive |
| m4a | audio/m4a | audio |
| m4v | video/x-m4v | video |
| macho | application/x-mach-binary | archive |
| mid | audio/midi | audio |
| mkv | video/x-matroska | video |
| mov | video/quicktime | video |
| mp3 | audio/mpeg | audio |
| mp4 | video/mp4 | video |
| mpg | video/mpeg | video |
| nes | application/x-nintendo-nes-rom | archive |
| ogg | audio/ogg | audio |
| otf | application/font-sfnt | font |
| pdf | application/pdf | archive |
| png | image/png | image |
| ppt | application/vnd.ms-powerpoint | document |
| pptx | application/vnd.openxmlformats-officedocument.presentationml.presentation | document |
| ps | application/postscript | archive |
| psd | image/vnd.adobe.photoshop | image |
| rar | application/vnd.rar | archive |
| rpm | application/x-rpm | archive |
| rtf | application/rtf | archive |
| sqlite | application/vnd.sqlite3 | archive |
| swf | application/x-shockwave-flash | archive |
| tar | application/x-tar | archive |
| tif | image/tiff | image |
| ttf | application/font-sfnt | font |
| wasm | application/wasm | application |
| wav | audio/x-wav | audio |
| webm | video/webm | video |
| webp | image/webp | image |
| wmv | video/x-ms-wmv | video |
| woff | application/font-woff | font |
| woff2 | application/font-woff | font |
| xls | application/vnd.ms-excel | document |
| xlsx | application/vnd.openxmlformats-officedocument.spreadsheetml.sheet | document |
| xz | application/x-xz | archive |
| zip | application/zip | archive |
| zst | application/zstd | archive |

## Fixed-input determinism verdict

AMBIGUOUS_TRUNCATED_INPUT_NONDETERMINISM=YES
AMBIGUOUS_CFB_RESULT_SET=[["classified","doc","application/msword"],["classified","ppt","application/vnd.ms-powerpoint"],["classified","xls","application/vnd.ms-excel"]]
REALISTIC_DOC_RESULT_SET=NOT_APPLICABLE_PINNED_FIXTURE_ABSENT
REALISTIC_XLS_RESULT_SET=NOT_APPLICABLE_PINNED_FIXTURE_ABSENT
REALISTIC_PPT_RESULT_SET=NOT_APPLICABLE_PINNED_FIXTURE_ABSENT
OOXML_RESULT_SETS={"docx":[["classified","docx","application/vnd.openxmlformats-officedocument.wordprocessingml.document"]],"xlsx":[["classified","xlsx","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]],"pptx":[["classified","pptx","application/vnd.openxmlformats-officedocument.presentationml.presentation"]]}
PNG_RESULT_SET=[["classified","png","image/png"]]
GENERAL_DETERMINISM_CLAIM=NONE
WRAPPER_ORDER_REPAIR=NONE

FACT: the deliberate exact D0 CF 11 E0 prefix was supplied to20 fresh direct
helper processes. Its result SET contains classified doc,xls,ppt, never no_match.
The source doc/xls/ppt matchers all accept that prefix when length<=513. Their
long-input branches require distinct bytes512-513; nondeterministic initialization
order selects the first matching short signature.

Available realistic pinned fixtures (each20 fresh helper processes, each at most
the first4096 bytes): sample.png (file82966 bytes), sample.docx (11296),
sample.xlsx (8341), sample.pptx (31133). Result SET for each has exactly one
classified extension and that registered MIME. None alternates classified/no_match.
No legacy .doc/.xls/.ppt fixture exists in the exact module fixtures directory;
these three explicitly conditional requirements are NOT_APPLICABLE. No outside
fixture was acquired under the narrow module-only network authority. This does
not prove realistic legacy Office input stability in general.

Additional source-grounded SYNTHETIC4096 CFB cases insert EC A5 (doc),09 08 (xls),
A0 46 (ppt) at offsets512-513 with the same four-byte prefix. Each20 fresh
processes yields its one intended classified extension. These are synthetic
long-signature checks, not realistic legacy files and not replacements for missing
pinned fixtures. No timing/performance results are reported; this is a semantic
probe, not a benchmark.

ADVISORY: malformed/truncated overlapping signatures can produce different
inferred labels across fresh helper processes because upstream matcher
registration order is map-derived. Bounded realistic fixtures available in the
pin were single-valued in these probes; general determinism is not established.
No live key sorting, custom order, module patch/fork, category bypass or override
was used. The candidate was evaluated unchanged. Any integration design is a
separate BRAIN decision.

## Fresh requirement map and carry forward

All rows are FACT except scoped carry-forward explicitly stated below. E=EVIDENCED,
NA=NOT_APPLICABLE.24 obligations=21E+3NA+0UNPROVEN.

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | Exact authority/base/role/freshness | E | clean main fast-forward of3 BRAIN-only commits; expected533c22d; accepted gate029S; fetch0/0 |
| 2 | Inspect exact Go telemetry counter/parent/child before Go | E | source paths/lines above inspected before first invocation |
| 3 | Every Go/tool writable env scratch; no GOTELEMETRY/global commands | E | explicit env, inherited sandbox,12 receipts; no unsupported override |
| 4 | Metadata-only global before/after; no global state mutation | E | identical15 records,per-command guard; zero new/mtime/size/inode changes |
| 5 | Only exact pin/sums; authorized network ceiling | E | offline cache reuse; verify/download-json pinned sums; network denied |
| 6 | Fresh independent controlled builds A/B equal | E | -a identical source/flags; both0; equal hashes |
| 7 | Prior hash comparison/root cause | E | exact prior hash match YES; no mismatch |
| 8 | Native arm64/minos<=15/no extra bundled resource or library | E | file/lipo/vtool/otool and buildinfo |
| 9 | Fresh known/unknown/empty/4096/4097 smoke | E | direct fresh helper outputs above |
| 10 | >4096 rejected before Match | E | fresh call-count scratch test,readerror/sentinel tests |
| 11 | Live helper network/descendants | E | direct live lsof/ps;zero sockets/descendants;reaped |
| 12 | Exact filetype license notice identity/digest | E | MIT exact notice and SHA above |
| 13 | Actual Go runtime license/PATENTS material | E | exact installed Go LICENSE/PATENTS notices/digests |
| 14 | Linked inherited notices closed/separate unlinked/system scope | E | selected sources+DWARF+nm+objdump+includes;Sun log required;19 unlinked |
| 15 | Source registration and read-only introspection exact set | E | 73/73/74,unknown extra reconciled;0unreconciled |
| 16 | Source matcher-order contradiction resolved | E | map range+prepend+first-match;NO stable order |
| 17 | Deliberate ambiguous prefix across fresh processes | E | 20 fresh;SET{doc,xls,ppt};explicit advisory |
| 18 | Realistic pinned DOC fixture if present | NA | absent from exact pinned module;no substituted realistic claim |
| 19 | Realistic pinned XLS fixture if present | NA | absent from exact pinned module |
| 20 | Realistic pinned PPT fixture if present | NA | absent from exact pinned module |
| 21 | Available realistic PNG/OOXML bounded stability | E | each20 fresh;single-valued;no classified/no_match alternation |
| 22 | No order repair or general determinism claim | E | live module/cache unchanged;only report copies sorted |
| 23 | Prior STOP remains STOP;specified fresh evidence and carry limits | E | fresh closure above;unchanged binary/source;explicit scoped prior proofs |
| 24 | Product/repo allowlist;no provider/integration/next;fresh postflight | E | all1471 baseline tracked entries unchanged pre-finalization;clean repo;candidate/receipt review |

Carry-forward supported by unchanged exact helper source/binary and accepted
029R proof references: interpreter/resource/model absent,source-path authority
absent,modelVersion/confidence null,Slice03 process shape compatible,helper graph
zero network and no sampled-byte persistence. Fresh task029S independently
reconfirms the required containment/build/smoke/process/inventory/license and
fixed-input observations. No new FSD executable bytes changed. No full FSD test
suite, production source read by classifier, provider switch or integration work.

## Evidence pointers and return boundary

Scratch recovery references (essential conclusions/notices/inventory are included
above): env.json,go.sb,run_go.py,telemetry-before.json,telemetry-after.json,
baseline.json;buildA/helper,buildB/helper,buildA/main.go;logs/*.receipt.json and
stdout/stderr;logs/probes.json,logs/live.json;inspection/deps.json,
selected-std-sources.json,notice-scan.json,includes.json,inventory.json;
logs/dwarf.stdout,nm.stdout,log-symbols.stdout;inspection/file.txt,lipo.txt,
dylibs.txt,minos.txt,sun-notice.txt. No helper artifact or Go source is in the repo/app.

Prepublication source uses the captured canonical HEAD, not its own future commit.
Finalizer writes only the four authorized paths, appends one worker_return event,
leaves BRAIN classification pending and accepted PROJECT_STATE unchanged, creates
full CURRENT mirror and Desktop recovery with exact canonical Operator bytes.
Actual git diff--check,checker,push/fetch,clean0/0 and Desktop/current/source parity
receipts are required before terminal completion and are recorded in transport.

Proposed state delta: BRAIN may adjudicate this bounded feasibility closure with
explicit truncated-input advisory and missing-pinned-legacy-fixture limits.
The HOT's sole next proposal is the integration contract032. No next task is
started, no provider is production-selected, and no integration is authorized.
BRAIN owns acceptance and active-next. Return and stop.
