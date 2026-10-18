# Task054 Physical Drive Identity Technical Feasibility — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_PHYSICAL_DRIVE_IDENTITY_FEASIBILITY
HANDOFF_ID=handoffs/FSD_FSD2_PHYSICAL_DRIVE_IDENTITY_FEASIBILITY_054_D_20261018-195648.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=65a133b901286549613315ddcb0a0e9c0763f18f
REMOTE_HEAD=65a133b901286549613315ddcb0a0e9c0763f18f
LAST_VERIFIED_AT=2026-10-18T19:56:48+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/PRD.md|docs/UX_UI_SPEC.md|docs/PRODUCT_STATE.md|docs/TEST_PLAN.md|docs/database/schema.sql|FSD/Provider/FilesystemDetector.swift|FSD/Catalog/SnapshotWriter.swift|FSD/Catalog/SnapshotHistoryRepository.swift|FSD/Catalog/CatalogMigrations.swift|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_ADR036_PHYSICAL_IDENTITY_FEASIBILITY_054
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_FEASIBILITY;HARDWARE_PROOF_AND_REAL_STRONG_PROFILE_PENDING;PRODUCTION_INTEGRATION_NOT_AUTHORIZED
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK054_FEASIBILITY_AND_PROOF_BOUNDARY)
NO_AUTO_NEXT=YES

## Task lock and re-anchor

PROJECT=FSD
TASK_ID=FSD2_PHYSICAL_DRIVE_IDENTITY_FEASIBILITY_054
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=65a133b901286549613315ddcb0a0e9c0763f18f
UPSTREAM_HEAD=65a133b901286549613315ddcb0a0e9c0763f18f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ONE_ADR036_RESEARCH_SYNTHETIC_FEASIBILITY_AND_FUTURE_DESIGN_TASK
ALLOWED_PATHS=docs/DECISIONS.md_ADR036_ONLY|docs/ARCHITECTURE.md_IDENTITY_AND_RELATED_STATUS|docs/TEST_PLAN.md_IDENTITY_AND_RELATED_STATUS|.ai-scratch/task054/|one_new_historical_handoff|handoffs/CURRENT_HANDOFF.md|STATE/TASK_LEDGER.tsv_WORKER_FIELDS|STATE/EVENTS.jsonl_APPEND|Desktop_04_FSD_BRAIN.md_TRANSPORT
FORBIDDEN_PATHS=PRODUCTION_SOURCE_XCODE_TESTS_FIXTURES_DEPENDENCIES|SCHEMA_MIGRATIONS|STATE/PROJECT_STATE.md|STATE/RULE_PROMOTION_LEDGER.tsv|PRIOR_HISTORY|PRD_MUTATION|ADR037_038_OR_ACCEPTED_ADR_SEMANTICS|SOURCE_MEDIA_DEVICES_OWNER_CATALOG_SYSTEM_SETTINGS|RELEASE_TAGS
SUCCESS_CRITERIA=OFFICIAL_API_INVENTORY|DETERMINISTIC_FAIL_CLOSED_CONTRACT|REPRODUCIBLE_SYNTHETIC_NEGATIVES|HONEST_HARDWARE_MATRIX|FUTURE_SCHEMA_PLAN_ONLY|SCOPED_DOC_REVIEW_AND_FINALIZATION
VALIDATIONS=SYNTHETIC_RESOLVER|FULL_SCOPED_DOC_DIFF_REVIEW|MARKDOWN_PATH_ANCHOR|GIT_DIFF_CHECK|PROTECTED_HASHES|CONTROL_PLANE_PRE_POST|DESKTOP_PARITY|GIT_PUBLICATION_SYNC
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

The first non-destructive fetch found clean local `main` at ff4520f30890acc1bb10a344863b4fec88f532f5,
two BRAIN-only commits behind origin/main. Their diff was inspected (State,
ledger, events only); `git pull --ff-only origin main` safely fast-forwarded to
the exact expected baseline above. No task mutation preceded reconciliation.
Fresh fetch before this handoff reconfirmed baseline/upstream equality and 0/0.
Origin is `https://github.com/cenvu/FSD.git`. Accepted State explicitly authorizes
ACTION(Task054), preserving Task053 as last accepted. Worker result is
**PASS_WITH_ADVISORY**, awaiting BRAIN classification; no technical ADR acceptance
or subsequent-task authority is authored here.

## Verified feasibility delta

- **DECISIONS / ADR-036 only:** defines deterministic conflict/manual/ambiguity/
  strong/unknown precedence, provenance/collision rules, revision-bound local
  correction, immutable history and action gates. No approved real hardware
  profile exists, so real `UniqueStrongMatch` and automatic association remain
  unavailable. Manual association never creates hardware verification.
- **ARCHITECTURE §11:** official inventory E1–E8 with exact Apple URLs and SDK
  declarations, evidence dependency table, topology/threat model, source/schema-v9
  findings and bounded future migration/integration plan. Disk Arbitration media
  UUID and IOMedia UUID are one derived origin at the pinned Apple revision.
  Serial subject may be bridge/reader; whole/leaf is not universal physical mapping.
  The inspected contracts do not establish a universal collision-resistant
  persistent physical identifier. SDK 26.2 inspection does not prove macOS 15
  runtime or hardware behavior.
- **TEST_PLAN §10:** explicit S01–S32 expected/actual matrix, all five proof labels
  and H01–H14 future hardware matrix. Every empirical result is NO/pending.
  Related stale P15 status is reconciled with accepted Task036/v9; historical
  test counts and accepted semantics are retained, not rerun or reaccepted.

Current source facts: detector UUID → stringified file resource ID → mount-path
fallback; `ensureVolume` uses `LIMIT 1` over nonunique UUID/fingerprint indexes;
availability is only recorded-path existence. These cannot establish physical
identity or close accepted F2. The duplicate-row code risk is **FACT from source**,
not an observed Owner hardware incident. No production repair is in scope.

Future logical model separates stable local drive IDs, observed volume/partition/
media and transport subjects, revision-scoped topology, MountSession, append-only
provenance/evidence, resolution/collision/manual events and immutable admission
receipts. Later annotations are explicitly retrospective. Legacy v9 captures
remain unknown; no registry/UUID/path backfill. Transaction/FK/RESTRICT/tombstone,
versioned migration, rollback/reopen and interruption/last-complete requirements
are specified, not implemented. Existing ADR-023/024/028, terminal comparisons,
Collections/Unsorted, source/root authority and read-only protections remain binding.

## Synthetic execution and bounded correction

Final command: `python3 .ai-scratch/task054/resolver.py` (exit 0), also captured
with stdout redirected to `.ai-scratch/task054/synthetic.stdout`.
**32 executed / 32 PASS / 0 FAIL**. Each case compares exact expected outcome,
target, candidate set and auto eligibility, asserts input nonmutation, reverses
fact and catalog order and asserts identical output. Only S21 is auto eligible,
under a hypothetical two-origin profile and all simulated capture gates. Real
profile mode remains pending even with matching two strings (S19).

During scoped review, S29 was strengthened to supply explicit changed path/BSD
values. That exposed a prototype bug: absent slot lookup and absent origin group
both compared as None, accidentally qualifying session fields. The root cause was
inspected; qualification now requires explicit membership in the hypothetical
slot map before comparing the group. The final 32-case rerun passes. This is a
scratch-only correction; there was no product change or repeated blind patch.

Generated inputs and full actual results are in ignored `inputs.json` and
`results.json`; the runnable source below reconstructs both without hardware,
live catalogs or source paths. The embedded source was independently recovered
under ignored task scratch and rerun: 32/32 PASS with byte-identical generated
inputs/results. The prototype deliberately does not implement
untrusted API parsing, persisted collision quarantine, topology discovery,
observation reducers, manual-event persistence or migration. Those remain explicit
future production gates. Input immutability proves only that these synthetic
objects were not modified; it is not an executed snapshot/database trigger test.

## Proof boundary, review and advisories

**DOCUMENTED:** exact Apple contracts/declarations and the pinned media-UUID
source dependency. **SYNTHETICALLY_TESTED:** the deterministic 32 cases below.
**EMPIRICALLY_VERIFIED:** none. **TECHNICAL_PROOF_PENDING:** real identity profile,
reconnect/clone/reader/bridge/provider behavior, macOS-floor runtime, observer
safety and future schema/product integration. **UNSUPPORTED_OR_UNKNOWN:** unproved
multi-store/RAID/virtual/network/multi-LUN physical mapping and unvalidated provider
paths. Finite future hardware trials cannot prove universal uniqueness or defeat
intentional identifier forgery. No live probe/enumeration, media access, mount,
unmount/eject, source payload or Owner catalog access occurred.

ADR-036 stays **Proposed / Owner Direction Approved / Technical Proof Pending**.
ADR-037/038 bytes/status and all accepted ADRs are unchanged. This Worker performs
scoped document/code review, not independent product acceptance; BRAIN review is
pending and future safety/schema implementation will require its applicable audit.
Read-only PRD drift is advisory: §2 Drive Set pre-decision text, §6.1 legacy raw
identity wording, and §8.1 provider-not-selected wording relative to accepted P15.
Existing architecture §8's older transient-promotion wording remains outside this
identity task; ADR-038 already governs the proposed separate durable-save direction.
No unrelated document or product scope was broadened.

Full three-document diff review checked claims against official evidence/current
source, manual vs verified outcomes, correlated UUIDs, no first/MRU match,
snapshot/accepted-history protection, matrix completeness, future transaction/
deletion constraints and unchanged ADR037/038. Execution postflight passed:
`git diff --check` exit 0; `python3 .ai-scratch/task054/validate.py` PASS;
39 local Markdown destinations/anchors; 110 protected hashes preserved;
accepted State SHA-256 `7b8dce618bae9932d27c244867b61fbb75b3d80fbcfbaeec671195afe5ad7004`. Only the three authorized substantive
docs differ. Production source/schema/migrations/tests/Xcode/dependencies/PRD,
RULE_PROMOTION_LEDGER and prior historical handoffs are untouched. No Xcode build
or production XCTest is required or claimed. No Task055 or other work started.

## Requirement/evidence accounting

| # | Requirement | Outcome | Evidence |
|---:|---|---|---|
| 1 | Exact Task054 Worker scope and canonical ACTION | EVIDENCED | Owner prompt; accepted State ACTION; task lock. |
| 2 | Non-destructive fetch and baseline reconciliation | EVIDENCED | Initial ff4520f was two BRAIN commits behind; fast-forward to expected 65a133b; fresh 0/0, clean baseline. |
| 3 | Required authority and skills read | EVIDENCED | Kernel/Owner policy, Compact, HOT, State, both skills; relevant PRD/UX/Product State/ADR/dependencies/architecture/test/schema/source reviewed read-only. |
| 4 | DA callbacks/descriptions and SDK declarations | EVIDENCED | Architecture E1/E2; installed SDK 26.2 headers; official guides and pinned Apple sources. |
| 5 | Identifier object, availability, persistence and uniqueness limits | EVIDENCED | Architecture inventory E2–E8; optional fields; no universal physical/collision/reconnect guarantee. |
| 6 | Provenance independence and topology limits | EVIDENCED | E4 directly derives DA media UUID from IOMedia UUID; reader/bridge/partition/whole-disk subjects separated. |
| 7 | Threat and ambiguity model | EVIDENCED | Architecture threat table; accidental/forged IDs, cloned tokens, topology and stale observation risks. |
| 8 | PhysicalDrive/Volume/Partition/MountSession/capture facts | EVIDENCED | ADR-036 concepts retained; architecture proposed subject graph and capture receipt. |
| 9 | Five deterministic outcomes and candidates | EVIDENCED | ADR-036 ordered precedence; real profile set empty; synthetic slots explicitly hypothetical. |
| 10 | Conflicts, duplicate IDs and no first/MRU winner | EVIDENCED | ADR conflict/ambiguity distinction; S07/08/18/25/26/27/30; persisted quarantine specified as future gate. |
| 11 | Explicit manual association/correction and contradiction | EVIDENCED | Revision-bound local choice, append/supersede/revoke design; S14–17/S32; never hardware verification. |
| 12 | History immutability and availability vs identity | EVIDENCED | Legacy unknown/no backfill; immutable source facts; independent availability/root/capture gates; S23 input-only simulation. |
| 13 | Automatic action prohibitions and Auto Capture OFF | EVIDENCED | ADR policy; S07/S14/S19–25/S28/S31; only hypothetical S21 eligible; no production automation. |
| 14 | Scratch-only generated deterministic prototype | EVIDENCED | Pure resolver below; no device, live catalog, source-root or OS storage API; ignored scratch only. |
| 15 | All required synthetic scenarios executed | EVIDENCED | S01–S32 exact inputs/expected/actual in harness and JSON; final command exit 0; 32/32/0. |
| 16 | Reproducibility and nonmutation/order independence | EVIDENCED | Complete harness embedded below, deterministic generated JSON; input immutability and reversal assertions per case. |
| 17 | Synthetic vs empirical proof boundary | EVIDENCED | Every empirical cell NO; two-token profile hypothetical; no hardware verification or observer execution claim. |
| 18 | Future hardware matrix and five proof labels | EVIDENCED | Test Plan H01–H14 covers required filesystems/devices/readers/bridges/LUNs/restarts/collisions; separate safety authorization required. |
| 19 | Read-only v9 source/schema inspection and proposed model | EVIDENCED | Detector/writer/history/models/migrations/schema inspected; local subject/evidence/session/resolution/manual/receipt design only. |
| 20 | Migration/transaction/FK/deletion/recovery design | EVIDENCED | Architecture staged plan; additive versioned migration, atomic writes, guards, RESTRICT/tombstones, no legacy backfill or auto recovery capture. |
| 21 | Only authorized substantive docs; related status reconciliation | EVIDENCED | DECISIONS only ADR-036; ARCHITECTURE/TEST_PLAN targeted identity and P15 status; PRD/ADR037/038 unchanged. |
| 22 | Full scoped document diff review and protected history | EVIDENCED | Self code/document review; 110 protected file hashes, ADR prefix before 036 and suffix from 037 byte-identical; product/schema/tests untouched. |
| 23 | Whitespace, Markdown and fresh execution postflight | EVIDENCED | git diff --check exit 0; validate.py PASS with 39 local destinations/anchors; exact three substantive paths; no next task. |
| 24 | Xcode build and production XCTest | NOT_APPLICABLE | Documentation and ignored pure synthetic harness only; exact task does not require them. |

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=24
WORKER_REQUIREMENTS_EVIDENCED=23
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

The accounting proves execution of this feasibility task, including documenting
pending empirical work; it does not count pending hardware or implementation as
verified. Finalizer closure follows this execution postflight: one immutable
historical handoff, full CURRENT mirror, Worker ledger/event, preserved prior
BRAIN fields, exact Desktop Operator/CURRENT transport, canonical prepublication
checker, authorized commit/push/fetch and postpublication clean/synced checker.
Those results/publication SHA are recorded after they occur in Desktop's fresh
Git receipt; this prepublication immutable source does not claim future execution
or self-reference its own future publication SHA. BRAIN alone classifies/accepts.
Proposed State delta: consider accepting Task054 feasibility with hardware/profile
advisory; retain F2 and ADR-036 technical proof pending. No active-next is set.

## Official source and SDK recovery digests

SDK root: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`; version 26.2.
Official pinned URLs are in architecture E1–E8. Apple modern Markdown pages for
workspace/Foundation were fetched directly where web-rendered text was unavailable.
The old kIOMediaUUIDKey web endpoint was unavailable; SDK and pinned Apple IOMedia.h
supply its exact declaration instead. Registry-entry HTML/search and SDK verified
the reboot limit; its `.md` URL returned 404 and is not treated as evidence.

- SDK `System/Library/Frameworks/DiskArbitration.framework/Headers/DADisk.h`: `9feb1b52a032899adaa80333f136bd63b530448ad22589e34eff8e5a521d6993`
- SDK `System/Library/Frameworks/DiskArbitration.framework/Headers/DiskArbitration.h`: `2282e429b3669f53af7fc4f28058975b792e181fc0425c2bc49069ad776ab95d`
- SDK `System/Library/Frameworks/DiskArbitration.framework/Headers/DASession.h`: `faf94ae4f95542de7fd78b282cd2057af34e6aaab0db0197f1aa67480637a905`
- SDK `System/Library/Frameworks/Kernel.framework/Headers/IOKit/storage/IOMedia.h`: `f8d96b002ec37bdc32e8b715394b8324e399f73ede88ac5d2d9770780e7a3bab`
- SDK `System/Library/Frameworks/Kernel.framework/Headers/IOKit/storage/IOStorageDeviceCharacteristics.h`: `eb054c1ac78d6d893b1c60221aeedad4edddec735836a76924aef722469b2be4`
- SDK `System/Library/Frameworks/IOKit.framework/Headers/IOKitLib.h`: `553869588e8c0b162b232e294dea2579cfd739d83e772a0b8a79e2be91a5816e`
- SDK `System/Library/Frameworks/AppKit.framework/Headers/NSWorkspace.h`: `be46224f91d11b7d0e25a0ed80dda5c1a9e52c404038a5a7ebfc25794befff30`
- SDK `System/Library/Frameworks/Foundation.framework/Headers/NSURL.h`: `97981c4e8ad70b8fc8c33c22e73b448a9ce9ad0ddfb7304d85a67d0843365f6d`
- Apple `DiskArbitration@a542bda934211dc3c301bfdcc7f21349c4164a85:DiskArbitration/DADisk.h`: `ffd421e9d3163f86ac07ddf569caa9e55072b69a981197fe8a8633edfec65aa4`
- Apple `DiskArbitration@a542bda934211dc3c301bfdcc7f21349c4164a85:diskarbitrationd/DADisk.c`: `667bf7ee7c26b8879bbedc439d9e9dc94d70d5e7d2c2051db1e4d2ea051393ad`
- Apple `IOStorageFamily@7edb88fbae296fb7c8ce2f64e115e116e566d51c:IOMedia.h`: `f8d96b002ec37bdc32e8b715394b8324e399f73ede88ac5d2d9770780e7a3bab`
- Apple `IOStorageFamily@7edb88fbae296fb7c8ce2f64e115e116e566d51c:IOStorageDeviceCharacteristics.h`: `eb054c1ac78d6d893b1c60221aeedad4edddec735836a76924aef722469b2be4`

## Complete isolated synthetic harness recovery

Save this exact fenced source to ignored `.ai-scratch/task054/resolver.py` and run
`python3 .ai-scratch/task054/resolver.py`. It writes only generated scratch JSON.
Source SHA-256: `c759096419648ed5277b46882dc90dfdf2fdd9a9bd188ed55f390199c82665c1`.

```python
"""Task054 pure synthetic model. No OS/device/catalog API; no approved real profile."""
import copy
import json
from pathlib import Path


def fact(key, value, group=None, scope="device", api="generated", subject="S"):
    return dict(key=key, value=value, group=group, scope=scope, api=api, subject=subject)


def identity(f):
    return f["scope"], f["key"]


def tokens(facts):
    # Names, paths, BSD nodes and reader identity never select a physical drive.
    return {(identity(f), f["value"]) for f in facts
            if f["value"] and f["scope"] in ("device", "volume", "partition")}


def resolve(observation, catalog, policy="pending", manual=None, opt_in=False,
            available=True, root_proven=False, authorized=False, idle=True):
    facts = observation["facts"]
    obs = tokens(facts)
    candidates = sorted(d for d, fs in catalog.items() if obs & tokens(fs))
    result, target = "Unknown", None
    # Conflicting aliases for the same subject/key fail closed.
    by_key = {}
    for f in facts:
        if f["scope"] in ("device", "volume", "partition") and f["value"]:
            by_key.setdefault((f["subject"], identity(f)), set()).add(f["value"])
    contradiction = any(len(v) > 1 for v in by_key.values())
    manual_target = manual["target"] if manual else None
    relevant = set(candidates) | ({manual_target} if manual_target in catalog else set())
    # Only explicitly hypothetical profile slots are qualified stable comparators.
    slots = {("device", "token_a"): "A", ("device", "token_b"): "B"}
    def qualified(fs):
        if policy != "hypothetical":
            return {}
        return {identity(f): f["value"] for f in fs
                if f["value"] and identity(f) in slots and slots[identity(f)] == f["group"]}
    qobs = qualified(facts)
    for d in relevant:
        prior = qualified(catalog[d])
        contradiction |= any(qobs[k] != prior[k] for k in qobs.keys() & prior.keys())
    if manual and (manual["revision"] != observation["revision"] or manual_target not in catalog):
        contradiction = True
    if contradiction:
        result = "Conflict"
    elif manual:
        result, target = "ManualAssociation", manual_target
    elif len(candidates) > 1:
        result = "Ambiguous"
    elif len(candidates) == 1:
        d = candidates[0]
        prior = qualified(catalog[d])
        if len(qobs) == 2 and all(prior.get(k) == v for k, v in qobs.items()):
            result, target = "UniqueStrongMatch", d
    auto = (result == "UniqueStrongMatch" and opt_in and available and
            root_proven and authorized and idle)
    return dict(result=result, target=target, candidates=candidates, auto=bool(auto))


def fixtures():
    a, b = fact("token_a", "a1", "A"), fact("token_b", "b1", "B")
    a2, b2 = fact("token_a", "a2", "A"), fact("token_b", "b2", "B")
    u = fact("uuid", "U", "filesystem", "volume")
    name = fact("name", "CAM", scope="presentation")
    path = fact("path", "/synthetic/CAM", scope="session")
    bsd = fact("bsd", "disk99s1", scope="session")
    reader = fact("serial", "reader1", scope="reader")
    rows = []
    def add(label, fs, cat, expected, target=None, candidates=(), auto=False, **kw):
        rows.append(dict(id=f"S{len(rows)+1:02}", label=label,
                         observation=dict(revision="r1", facts=fs), catalog=cat,
                         options=kw, expected=dict(result=expected, target=target,
                                                   candidates=list(candidates), auto=auto)))
    add("same name different devices", [name,a2], {"D1":[name,a],"D2":[name,a2]}, "Unknown", candidates=["D2"])
    add("mount path reused", [path,a2], {"D1":[path,a]}, "Unknown")
    add("BSD node reused", [bsd,a2], {"D1":[bsd,a]}, "Unknown")
    add("BSD changes", [a,b,fact("bsd","disk88",scope="session")], {"D1":[a,b,bsd]}, "Unknown", candidates=["D1"])
    add("missing UUID", [], {"D1":[u]}, "Unknown")
    add("single unverified UUID", [u], {"D1":[u]}, "Unknown", candidates=["D1"])
    add("cloned UUID two records", [u], {"D1":[u],"D2":[u]}, "Ambiguous", candidates=["D1","D2"], opt_in=True)
    add("split qualified evidence", [a,b2], {"D1":[a,b],"D2":[a2,b2]}, "Conflict", candidates=["D1","D2"], policy="hypothetical")
    add("partition one of device", [a,b,fact("uuid","P1",scope="partition")], {"D1":[a,b]}, "Unknown", candidates=["D1"])
    add("partition two of device", [a,b,fact("uuid","P2",scope="partition")], {"D1":[a,b]}, "Unknown", candidates=["D1"])
    add("same reader different cards", [reader,u], {"D1":[reader,u],"D2":[reader,u]}, "Ambiguous", candidates=["D1","D2"])
    add("reader serial only", [reader], {"D1":[reader],"D2":[reader]}, "Unknown")
    add("reconnect changed path pending", [a,b,fact("path","/synthetic/NEW",scope="session")], {"D1":[a,b,path]}, "Unknown", candidates=["D1"])
    add("current revision manual", [u], {"D1":[u]}, "ManualAssociation", "D1", ["D1"], manual=dict(target="D1",revision="r1"), opt_in=True)
    add("manual later contradiction", [a,b2], {"D1":[a,b]}, "Conflict", candidates=["D1"], policy="hypothetical",manual=dict(target="D1",revision="r1"))
    add("stale manual revision", [u], {"D1":[u]}, "Conflict", candidates=["D1"],manual=dict(target="D1",revision="old"))
    add("manual correction to another local record", [u], {"D1":[u],"D2":[u]}, "ManualAssociation", "D2", ["D1","D2"],manual=dict(target="D2",revision="r1"))
    add("aliases share origin no corroboration", [fact("uuid","U","media","partition","DA"),fact("uuid","U","media","partition","IOKit")], {"D1":[fact("uuid","U","media","partition")]}, "Unknown", candidates=["D1"],policy="hypothetical")
    add("two device fields real profile pending", [a,b], {"D1":[a,b]}, "Unknown", candidates=["D1"],opt_in=True,available=True,root_proven=True,authorized=True)
    add("hypothetical strong default OFF", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical",root_proven=True,authorized=True)
    add("hypothetical strong opt in all gates", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],True,policy="hypothetical",opt_in=True,root_proven=True,authorized=True)
    add("hypothetical strong no root authority", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical",opt_in=True,authorized=True)
    add("hypothetical strong unavailable", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical",opt_in=True,available=False,root_proven=True,authorized=True)
    add("hypothetical strong no capture authorization", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical",opt_in=True,root_proven=True)
    add("hypothetical strong duplicate device tokens", [a,b], {"D1":[a,b],"D2":[a,b]}, "Ambiguous",candidates=["D1","D2"],policy="hypothetical",opt_in=True)
    add("contradictory aliases same subject", [u,fact("uuid","V","filesystem","volume")], {"D1":[u]}, "Conflict",candidates=["D1"])
    add("unknown lineage not qualified", [fact("token_a","a1"),b], {"D1":[a,b]}, "Unknown",candidates=["D1"],policy="hypothetical")
    add("unknown no association even opted in", [], {"D1":[a,b]}, "Unknown",opt_in=True,root_proven=True,authorized=True)
    add("hypothetical reconnect changed BSD path", [a,b,fact("path","/synthetic/NEW",scope="session"),fact("bsd","disk88s2",scope="session")], {"D1":[a,b,path,bsd]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical")
    add("hypothetical qualified mismatch", [a,b2], {"D1":[a,b]}, "Conflict",candidates=["D1"],policy="hypothetical")
    add("hypothetical strong busy", [a,b], {"D1":[a,b]}, "UniqueStrongMatch","D1",["D1"],policy="hypothetical",opt_in=True,root_proven=True,authorized=True,idle=False)
    add("manual missing target", [], {"D1":[a,b]}, "Conflict",manual=dict(target="absent",revision="r1"))
    return rows


if __name__ == "__main__":
    home = Path(__file__).resolve().parent
    rows = fixtures()
    (home / "inputs.json").write_text(json.dumps(rows, indent=2)+"\n")
    results = []
    for row in rows:
        before = copy.deepcopy(row)
        actual = resolve(row["observation"], row["catalog"], **row["options"])
        assert actual == row["expected"], (row["id"], row["expected"], actual)
        assert before == row, "input mutated"
        reversed_obs = dict(row["observation"], facts=list(reversed(row["observation"]["facts"])))
        reversed_cat = {k:list(reversed(v)) for k,v in reversed(list(row["catalog"].items()))}
        assert actual == resolve(reversed_obs, reversed_cat, **row["options"]), "order dependent"
        if actual["result"] != "UniqueStrongMatch":
            assert not actual["auto"]
        results.append(dict(id=row["id"],label=row["label"],expected=row["expected"],actual=actual,status="PASS"))
    (home / "results.json").write_text(json.dumps(results,indent=2)+"\n")
    for r in results:
        print(r["id"],r["label"],"expected="+r["expected"]["result"],"actual="+r["actual"]["result"],"auto="+str(r["actual"]["auto"]),r["status"])
    print(f"TOTAL={len(results)} PASS={len(results)} FAIL=0; input immutability and order reversal checked per case; HARDWARE_PROOF=PENDING")
```
