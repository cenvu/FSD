# Task056 Saved Live Comparison Backing Evidence Feasibility — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_SAVED_LIVE_COMPARISON_FEASIBILITY
HANDOFF_ID=handoffs/FSD_FSD2_SAVED_LIVE_COMPARISON_FEASIBILITY_056_D_20261018-211322.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=3b81377ca03e9e4478658051118bc42d4560f27f
REMOTE_HEAD=3b81377ca03e9e4478658051118bc42d4560f27f
LAST_VERIFIED_AT=2026-10-18T21:13:22+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/TEST_PLAN.md|docs/UX_UI_SPEC.md|docs/PRD.md|docs/PRODUCT_STATE.md|docs/database/schema.sql|FSD/Catalog/CatalogDatabase.swift|FSD/Catalog/CatalogMigrations.swift|FSD/Catalog/SnapshotWriter.swift|FSD/Catalog/RecoveryService.swift|FSD/Catalog/TransientSnapshotLifecycle.swift|FSD/Diff/ComparisonEngine.swift|FSD/Diff/ComparisonService.swift|FSD/Diff/ComparisonModels.swift|FSD/Diff/ComparisonProfileRepository.swift|FSD/Diff/ComparisonResultRepository.swift|FSD/Export/JSONSnapshotExporter.swift|FSD/UI/ComparisonWorkspaceModel.swift|FSD/UI/ComparisonBrowserModel.swift|FSDTests/ComparisonPersistenceTests.swift|FSDTests/ComparisonSnapshotStateTests.swift|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_ADR038_SAVED_LIVE_COMPARISON_FEASIBILITY_056
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_FEASIBILITY;PRODUCTION_RECEIPTS_SCHEMA_SAVE_REOPEN_MIGRATION_AND_CRASH_PROOF_PENDING
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK056_BACKING_FEASIBILITY_AND_PENDING_CONTRACTS)
NO_AUTO_NEXT=YES

## Task lock and safe re-anchor

PROJECT=FSD
TASK_ID=FSD2_SAVED_LIVE_COMPARISON_FEASIBILITY_056
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=3b81377ca03e9e4478658051118bc42d4560f27f
UPSTREAM_HEAD=3b81377ca03e9e4478658051118bc42d4560f27f
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ADR038_SAVED_METADATA_EVIDENCE_FEASIBILITY_ONLY
ALLOWED_PATHS=docs/DECISIONS.md_ADR038_ONLY|docs/ARCHITECTURE.md_SECTION8_AND_NEW_SECTION13|docs/TEST_PLAN.md_APPEND|docs/UX_UI_SPEC.md_SECTION14_ONLY|.ai-scratch/task056/|one_new_history|CURRENT|Worker_ledger_event|Desktop_transport
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_FILES|OWNER_CATALOG_MEDIA_DEVICES|SOURCE_ROOT_CONTENT|RELEASE_TAGS
SUCCESS_CRITERIA=LIFECYCLE_INVENTORY_ALTERNATIVES_EXACT_MAPPING_ATOMICITY_SYNTHETIC_LARGE_TREE_MIGRATION_PLAN_AND_FINALIZATION
VALIDATIONS=SQLITE_MEMORY_ONLY|DIFF_LINKS_HASHES|CANONICAL_PRE_POST|DESKTOP_PARITY|GIT_CLEAN_SYNCED
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

Initial clean main was 36874f077a4f276fed5a40c931ca5babc4256976. Non-destructive
fetch found one BRAIN-only upstream commit; full State/ledger/event diff was
inspected. git pull --ff-only origin main safely advanced to the exact expected
baseline above. Finalizer-entry fetch freshly reconfirmed equal HEAD/upstream,
0/0 and only the four authorized docs dirty. Origin:
https://github.com/cenvu/FSD.git. No reset/clean/stash/rebase/force or unknown work
removal. All 1510 protected tracked paths were captured before tracked mutation;
symlink hashes use link text without following source targets.

Accepted State authorizes exactly Task056 and accepts Task055 feasibility-only
at 36874f077a4f276fed5a40c931ca5babc4256976. Worker-local result is
PASS_WITH_ADVISORY; BRAIN classification remains pending. ADR038 is not finally
accepted. ADR036 real strong profiles stay empty; this Save design needs no
physical identity proof. No device/source-media/Owner catalog access occurred.

## Verified source and feasibility delta

FACT from baseline source/schema inspection:

- v9 snapshot kinds and capture facts cannot be converted in place; completed
  entry guards, comparison source/status/count/result and collision guards
  remain binding. Explicit whole-comparison disposal intentionally cascades
  evidence. Source code uses snapshot-backed comparison for all modes.
- Workspace close cancels/disposes live-side comparison state, then unreferenced
  transients. Startup marks abandoned running comparisons failed and only
  removes unreferenced transients; it does not wipe every referenced transient.
  Ordinary snapshot/snapshot comparisons persist. These are source observations,
  not an executed Swift lifecycle test in Task056.
- Profile ID/revision is stored, but full historical profile definition is not.
  Current profile name is joined at read time; warnings are re-derived. Some
  snapshot headers/aggregates and issue UPDATE/DELETE lack full DB immutability;
  the comparison status/count guard does not freeze every comparison column.
  Accepted runtime contracts remain unchanged. No production repair is made.
- Current snapshot JSON export is offline/streamed, not an implemented saved
  comparison export. Presentation is derived from stored results/flags/entries;
  inaccessible is an entry flag with uncertain evidence, not a new DB result enum.

Preferred candidate B: separate dedicated saved evidence copies of BOTH sides,
with new local IDs and exact parent/result/group/member remapping, frozen
profile/header/issues/summary/engine-warning contract, explicit operation
receipt, sealed ownership and restricted shared backing deletion. A (new user
snapshot copies) and C (retain original transients) were analyzed with their
compatibility/ownership/migration/maintenance costs; neither was executed or
claimed infeasible in all designs. B is a review proposal justified by isolated
FK/remapping/cleanup/rollback evidence, not a final schema selection.

Critical pending prerequisite: an additive completion receipt must freeze the
actual profile used and side/issue/summary facts atomically at completion.
Legacy v9 records without trustworthy receipt remain ineligible for exact Save;
no current-profile guess, historical backfill or rescan manufactures truth.
The synthetic fixture supplies future receipt records; production has none.

The proposed graph separates saved artifacts, sides, independent trees,
entries/issues, results, collision groups/members and operation receipts. It has
no outgoing FK into disposable originals, current volume/profile registry,
Collections or Drive Sets. Original numeric IDs are informational provenance
scoped by catalog/completion token, not a hardware identity or first-match key.
Both sides preserve orientation. Operation retry binds that full completion
identity, returns the same committed artifact after original disposal, and a
deleted receipt forbids resurrection. Shared backing is retained until its last
explicit saved-side reference is removed. Metadata only: no payloads/previews,
classification or source-content hash; existing metadata BLOBs use tagged encoding.

## Scoped documentation delta

- DECISIONS: refine ADR038 only; A/B/C analysis, dedicated candidate, observed
  completion truth gap, exact mappings, atomicity/retry/ownership and proof limits.
- ARCHITECTURE: reconcile only §8's inaccurate promotion/startup wording; add §13
  v9 lifecycle/FK/guard inventory, official SQLite/Python/Apple sources, proposed
  entities/indexes/mappings, transaction/recovery, bounds and migration sequence.
- TEST_PLAN: append §12 with all 47 expected/actual outcomes, 16 rollback
  boundaries, measured 10k/100k receipts and future production matrix.
- UX_UI_SPEC: §14 only, clarify explicit future Save truth, independent backing,
  receipt eligibility and unimplemented production flow.

No PRD/PRODUCT_STATE/MVP_PLAN/Snapshot Collections or accepted ADR semantics
changed. The current unsaved transient policy, snapshot/snapshot persistence,
source-read-only, last-complete, immutable capture/result, Collection/Unsorted
and proposed Drive Sets contracts are preserved.

## Executed synthetic evidence

python3 .ai-scratch/task056/harness.py — exit 0: 47 executed / 47 PASS / 0 FAIL.
Python 3.15.0 / SQLite 3.54.0; every connection :memory:, foreign_keys=ON asserted.
Source schema SHA256 4b65d6c285ebaa353eec8439453199ce90f42cb33d670a6bb7d7410e28cdf815.
Harness SHA256 379e6a26c818ee77d73999100b9938ca2644de217e892e281170d9bc7ef6e867.
The complete source below specifies generated inputs, expected outcomes,
metadata-copy assertions, FK/integrity checks and receipts. The candidate source
was extracted into ignored recovery-check and rerun before immutable creation;
47/47 result JSON matched byte-for-byte. No unexpected failing test occurred.

Every ordinary case checks full original-row metadata digest unchanged; explicit
synthetic cleanup and current-profile/header-change cases check their deliberate
expected deltas. Basic archives compare headers, every entry/issue/result/group/
member payload and remapped references. FK checks are empty and integrity is ok
for every case. Future Drive Sets are represented only by a nonmutated sentinel,
not an invented production schema. The 16 injected exceptions each roll back
all new graph state and permit known-failure retry. Cancellation/size/time limits
leave no partial ready save. Current-profile/header mutation fixtures demonstrate
why generated completion receipts are required. No Swift engine was executed.

| Case | Generated scenario | Expected = actual (PASS) |
|---|---|---|
| SV01 | snapshot-snapshot | exact complete archive |
| SV02 | live-user | exact complete archive |
| SV03 | live-live | exact complete archive |
| SV04 | status-failed | no saved artifact |
| SV05 | status-cancelled | no saved artifact |
| SV06 | status-running | no saved artifact |
| SV07 | mapping-closure | orientation/profile/parents/results/collisions/duplicate paths exact |
| SV08 | warnings | warnings and inaccessible evidence retained |
| SV09 | CL-offline-cleanup | offline archive survives original live cleanup |
| SV10 | snapshot-persistence | ordinary comparison retained |
| SV11 | kind-guard | transient conversion rejected |
| SV12 | original-guards | original terminal/capture evidence rejects mutation |
| SV13 | fail-artifact | rollback and known-failure retry exact |
| SV14 | fail-left_tree | rollback and known-failure retry exact |
| SV15 | fail-left_entries | rollback and known-failure retry exact |
| SV16 | fail-left_issues | rollback and known-failure retry exact |
| SV17 | fail-left_side | rollback and known-failure retry exact |
| SV18 | fail-right_tree | rollback and known-failure retry exact |
| SV19 | fail-right_entries | rollback and known-failure retry exact |
| SV20 | fail-right_issues | rollback and known-failure retry exact |
| SV21 | fail-right_side | rollback and known-failure retry exact |
| SV22 | fail-results | rollback and known-failure retry exact |
| SV23 | fail-groups | rollback and known-failure retry exact |
| SV24 | fail-members | rollback and known-failure retry exact |
| SV25 | fail-validated | rollback and known-failure retry exact |
| SV26 | fail-ready | rollback and known-failure retry exact |
| SV27 | fail-operation | rollback and known-failure retry exact |
| SV28 | fail-precommit | rollback and known-failure retry exact |
| SV29 | idempotent | uncertain-ack retry returns same committed artifact |
| SV30 | operation-conflict | operation ID cannot name different comparison |
| SV31 | cancel-batch | cancelled save leaves no partial graph |
| SV32 | cancel-precommit | cancelled save leaves no partial graph |
| SV33 | legacy-no-receipt | legacy comparison without receipt fails closed |
| SV34 | PF-current-profile-change | archive uses completion profile not current profile |
| SV35 | HD-current-header-change | archive uses completion header not mutable save-time header |
| SV36 | backing-fks | missing and referenced backing rejected |
| SV37 | shared-delete | shared trees retained until final explicit delete; receipt prevents resurrection |
| SV38 | archive-guards | published dedicated evidence immutable |
| SV39 | row-limit | budget rejection is atomic |
| SV40 | byte-limit | budget rejection is atomic |
| SV41 | time-limit | budget rejection is atomic |
| SV42 | page-edges | first/root/tied path/end pages deterministic |
| SV43 | memory-reopen | memory-copy reopen retries committed receipt exactly |
| SV44 | cross-side-fk | cross-side reference rejected before publication |
| SV45 | CL-retry-after-disposal | committed operation retry works after original disposal |
| SV46 | missing-entry-fk | missing entry FK rejected in unsealed construction |
| SV47 | generation-bound-operation | same numeric comparison ID with different completion token rejected |

Review strengthened old/new owner UPDATE guards, issue-stage injections,
tied-path paging, missing-entry FK, completion-generation conflict and exact
closure counts; reruns stayed green. No repeated ineffective implementation
attempt, automatic next task or model benchmark occurred.

## Measured large-entry runs and limits

One fresh process per command:
python3 .ai-scratch/task056/harness.py --large 10000
python3 .ai-scratch/task056/harness.py --large 100000
Both exited 0. Total entries across two trees, half per side; these are not
100k result rows. Streaming pages/max batch 256; no all-tree Python list/map.
Original digest unchanged; full copied/read counts, increasing keysets,
foreign_key_check=[] and integrity_check=ok at both sizes.

```json
{
  "label": "SYNTHETIC_PROTOTYPE",
  "total_entries": 10000,
  "processed": 10000,
  "read_processed": 10000,
  "batch_rows": 256,
  "max_batch": 256,
  "seed_seconds": 0.159792,
  "save_transaction_seconds": 0.381197,
  "read_seconds": 0.063329,
  "copied_rows": 10017,
  "serialized_metadata_bytes": 8481409,
  "checkpoints": 64,
  "query_plan": [
    "SEARCH saved_entries USING INDEX sqlite_autoindex_saved_entries_2 (tree=? AND origin_id>?)"
  ],
  "ru_maxrss_before": 28164096,
  "ru_maxrss_after": 45580288,
  "ru_maxrss_unit": "bytes",
  "platform": "darwin",
  "limits": "300000 copied rows;512MiB serialized metadata;60s elapsed budget;checkpoint each batch",
  "measurement_limit": "Process high-water includes original and archive in-memory SQLite, Python, validation and seed. Not Swift RSS, source throughput, disk/WAL size or crash durability.",
  "original_digest_unchanged": true,
  "fk_check": [],
  "integrity_check": "ok"
}
```

```json
{
  "label": "SYNTHETIC_PROTOTYPE",
  "total_entries": 100000,
  "processed": 100000,
  "read_processed": 100000,
  "batch_rows": 256,
  "max_batch": 256,
  "seed_seconds": 1.551805,
  "save_transaction_seconds": 4.856924,
  "read_seconds": 0.723615,
  "copied_rows": 100017,
  "serialized_metadata_bytes": 84961422,
  "checkpoints": 416,
  "query_plan": [
    "SEARCH saved_entries USING INDEX sqlite_autoindex_saved_entries_2 (tree=? AND origin_id>?)"
  ],
  "ru_maxrss_before": 69353472,
  "ru_maxrss_after": 223002624,
  "ru_maxrss_unit": "bytes",
  "platform": "darwin",
  "limits": "300000 copied rows;512MiB serialized metadata;60s elapsed budget;checkpoint each batch",
  "measurement_limit": "Process high-water includes original and archive in-memory SQLite, Python, validation and seed. Not Swift RSS, source throughput, disk/WAL size or crash durability.",
  "original_digest_unchanged": true,
  "fk_check": [],
  "integrity_check": "ok"
}
```

Memory numbers are process-wide Darwin ru_maxrss high-water (bytes), including
both original/archive memory SQLite, indexes, Python and validation. Not Swift
RSS or copier-only memory. Copy transaction includes validation/commit;
read_seconds includes integrity checks. Metadata-accounting bytes are not file/
WAL allocation. Source throughput, power-loss and process-crash durability are
not measured. The 300000-row/512MiB/60s cooperative experiment ceilings are not
approved product limits; per-row byte caps, disk headroom, busy/commit/rollback
bounds and deep deletion scale remain pending.

## Review, requirement accounting and remaining proof

Full four-document diff self-reviewed against actual schema/lifecycle/repository
source and named canonical product authorities. No independent review or BRAIN
acceptance is claimed. git diff --check PASS; validate.py PASS: 56 local Markdown
path/anchor destinations; 1510 protected tracked paths including 108 prior
historical handoffs preserved. ADR outside038 and UX outside§14 byte-identical;
architecture outside§8 retained plus append, test plan append-only. Accepted
State SHA256 0ee3e0278c3cd499469c7a93a77c10fdbd7b63ab302bafec1b5f6f8774d3476b; unchanged.

| Requirement | Execution evidence |
|---|---|
| R01 authority/bootstrap/reconcile | EVIDENCED — exact ACTION, safe FF, fresh 0/0, task lock/hash baseline |
| R02 named authorities/source read-only | EVIDENCED — HOT/kernel/Compact/skills, ADR/product/schema/source refs above |
| R03 v9 lifecycle/FK/guard inventory | EVIDENCED — architecture§13 actual tables/code/triggers and cleanup graph |
| R04 alternatives A/B/C | EVIDENCED — cost/ownership/compatibility/recovery table; only B prototype executed |
| R05 preferred design/proof boundary | EVIDENCED — B candidate; receipt prerequisite and final schema pending |
| R06 saved entities/keys/index/deletion | EVIDENCED — architecture ownership table and full DDL below; SV36/37/44/46 |
| R07 snapshot/entry/parent/source mapping | EVIDENCED — SV01–03/07/08, exact metadata payload/ref assertions |
| R08 comparison/profile/result/collision mapping | EVIDENCED — SV07/12/34/44; row counts/bits/sides/group/member values retained |
| R09 completion-time truth/legacy limits | EVIDENCED — source gap; SV33–35/47; no fabricated legacy receipt |
| R10 metadata-only/offline/source absent | EVIDENCED — no paths opened; SV09/45 dedicated rows after disposal |
| R11 minimum30 enumerated tests | EVIDENCED — 47 expected=actual PASS, complete runnable source |
| R12 every staged boundary rollback | EVIDENCED — SV13–28, 16 points including ready/receipt/precommit |
| R13 failure/cancel/FK/error cases | EVIDENCED — SV04–06/31/32/36/39–41/44/46; all integrity/FK checks |
| R14 operation ID/retry/reused identity | EVIDENCED — SV29/30/43/45/47; real durable acknowledgements pending |
| R15 deletion/shared ownership/no resurrection | EVIDENCED — SV36–38; actual file-backed delete recovery pending |
| R16 originals/organizers/last-complete preserved | EVIDENCED — ordinary-case row digest, SV10–12/37; no capture work |
| R17 10k/100k bounded synthetic measurements | EVIDENCED — exact receipts above, 256 pages, indexed seeks, raw high-water |
| R18 size/time/cancellation safeguards | EVIDENCED — experiment limits/SV31/32/39–41 and explicit production gaps |
| R19 additive migration/no backfill design | EVIDENCED — ADR024 future sequence, supported chains/newer refusal; no production migration |
| R20 atomic/recovery/cleanup contract | EVIDENCED — architecture single transaction/provenance/receipt/delete; crash/disk proof pending |
| R21 exact four-document/ADR boundaries | EVIDENCED — byte checks, §8/§14-only reconciliation; restricted files untouched |
| R22 complete scoped diff/source review | EVIDENCED — Worker self-review; independent production audit not claimed |
| R23 links/whitespace/protected history/State | EVIDENCED — 56 links,1510 paths,108 old handoffs,diff-check |
| R24 reproducible generated inputs/receipts | EVIDENCED — source extracted/rerun, result JSON parity; large raw receipts included |
| R25 no source access/implementation/next | EVIDENCED — memory-only code and physical allowed-path review; return only |
| R26 Xcode/production XCTest | NOT_APPLICABLE — docs and ignored scratch only; explicitly exempted |

Future production proof is a disclosed feasibility boundary, not a claim already
made without evidence. Canonical finalizer closure follows execution postflight:
new history/CURRENT/Worker projections/Desktop, prechecker, push/fetch and
clean/synced postchecker. Their actual receipts and publication SHA belong in
Desktop transport/tool output after execution, not an invented future SHA inside
this immutable prepublication record. Final completion waits for those checks.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=26
WORKER_REQUIREMENTS_EVIDENCED=25
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Worker proposal and unresolved boundaries

BRAIN may assess this feasibility-only result as PASS_WITH_ADVISORY, leaving
ADR038 Proposed / Owner Direction Approved / Technical Proof Pending. Final
B-vs-A choice/production schema/serializer, receipt creation/retention/guards,
actual Save/read/delete/UI/export/migration, file-backed crash/disk/busy/cancel/
shared-delete and Swift scale proof remain pending. Memory rollback/backup are
not physical crash/reopen. Ordinary unsupported legacy exact Save fails closed;
source media or a current profile must never repair missing historical evidence.
No physical identity is solved; ADR036 profiles remain empty, ADR037 final schema
and production migration stay pending. Existing manual E2E/VoiceOver and
Task041/047 privacy advisories are unchanged. Historical documentation outside
allowed sections remains read-only evidence, not new authority.

Worker owns evidence/proposal only. BRAIN owns review/classification/accepted
State/active next. The single HOT proposal is a return for BRAIN review. No
Task057 or other work is started.

## Reproducible harness — exact source

Save as .ai-scratch/task056/harness.py; run from repo root. Output stays beside
this source. The only database path is :memory:.

```python
"""Task056 SYNTHETIC_PROTOTYPE. All DBs :memory:, generated facts only.
Run at repo root. --large 10000 or --large 100000 runs a fresh-process size case.
No scanners, Owner catalogs, devices or source paths are opened.
"""
from pathlib import Path
import contextlib,hashlib,json,resource,sqlite3,sys,time
OUT=Path(__file__).resolve().parent
SCHEMA=Path('docs/database/schema.sql').read_text()
STAMP='2000-01-01T00:00:00Z'
PAGE=256
class Rejected(Exception): pass
class Injected(Exception): pass

def enc(value):
    if isinstance(value,sqlite3.Row):value=dict(value)
    return json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=False,default=lambda b:{'metadata_blob_hex':b.hex()})
def one(c,sql,args=()):
    r=c.execute(sql,args).fetchone();return None if r is None else r[0]
def row(c,sql,args=()):return c.execute(sql,args).fetchone()
def pages(c,sql,args=(),size=PAGE):
    cursor=0
    while True:
        batch=c.execute(sql,(*args,cursor,size)).fetchall()
        if not batch:break
        assert len(batch)<=size
        yield batch
        cursor=batch[-1]['id']
def eid(s,n):return s*1000000+n

DDL=[
"CREATE TABLE p_receipts(token TEXT NOT NULL PRIMARY KEY,cid INTEGER NOT NULL UNIQUE REFERENCES comparisons(id) ON DELETE CASCADE,comparison_json TEXT NOT NULL,profile_json TEXT NOT NULL,engine_contract TEXT NOT NULL)",
"CREATE TABLE p_headers(token TEXT NOT NULL REFERENCES p_receipts(token) ON DELETE CASCADE,side TEXT NOT NULL CHECK(side IN ('left','right')),snapshot_id INTEGER NOT NULL,header_json TEXT NOT NULL,PRIMARY KEY(token,side))",
"CREATE TABLE p_issues(token TEXT NOT NULL,side TEXT NOT NULL,id INTEGER NOT NULL,entry_origin INTEGER,payload TEXT NOT NULL,PRIMARY KEY(token,side,id),FOREIGN KEY(token,side) REFERENCES p_headers(token,side) ON DELETE CASCADE)",
"CREATE TABLE saved_artifacts(id TEXT NOT NULL PRIMARY KEY,completion_token TEXT NOT NULL,comparison_json TEXT NOT NULL,profile_json TEXT NOT NULL,engine_contract TEXT NOT NULL,state TEXT NOT NULL CHECK(state IN ('building','ready')),created_at TEXT NOT NULL)",
"CREATE TABLE saved_trees(id TEXT NOT NULL PRIMARY KEY,completion_token TEXT NOT NULL,side TEXT NOT NULL CHECK(side IN ('left','right')),origin_snapshot INTEGER NOT NULL,header_json TEXT NOT NULL,sealed INTEGER NOT NULL CHECK(sealed IN (0,1)))",
"CREATE TABLE saved_sides(artifact TEXT NOT NULL REFERENCES saved_artifacts(id) ON DELETE CASCADE,side TEXT NOT NULL CHECK(side IN ('left','right')),tree TEXT NOT NULL REFERENCES saved_trees(id) ON DELETE RESTRICT,PRIMARY KEY(artifact,side),UNIQUE(artifact,side,tree))",
"CREATE INDEX sides_by_tree ON saved_sides(tree,artifact)",
"""CREATE TABLE saved_entries(tree TEXT NOT NULL REFERENCES saved_trees(id) ON DELETE CASCADE,id TEXT NOT NULL,origin_id INTEGER NOT NULL,parent TEXT,path TEXT NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(tree,id),UNIQUE(tree,origin_id),UNIQUE(tree,path),FOREIGN KEY(tree,parent) REFERENCES saved_entries(tree,id) DEFERRABLE INITIALLY DEFERRED)""",
"CREATE INDEX saved_entries_parent ON saved_entries(tree,parent,id)",
"CREATE TABLE saved_issues(tree TEXT NOT NULL REFERENCES saved_trees(id) ON DELETE CASCADE,id INTEGER NOT NULL,entry TEXT,payload TEXT NOT NULL,PRIMARY KEY(tree,id),FOREIGN KEY(tree,entry) REFERENCES saved_entries(tree,id) DEFERRABLE INITIALLY DEFERRED)",
"CREATE INDEX saved_issues_entry ON saved_issues(tree,entry)",
"""CREATE TABLE saved_results(artifact TEXT NOT NULL REFERENCES saved_artifacts(id) ON DELETE CASCADE,id TEXT NOT NULL,origin_id INTEGER NOT NULL,parent TEXT,path TEXT NOT NULL,kind TEXT NOT NULL CHECK(kind IN ('matched','added','removed','changed','ignored','uncertain')),left_side TEXT NOT NULL DEFAULT 'left' CHECK(left_side='left'),left_tree TEXT NOT NULL,left_entry TEXT,right_side TEXT NOT NULL DEFAULT 'right' CHECK(right_side='right'),right_tree TEXT NOT NULL,right_entry TEXT,flags INTEGER NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(artifact,id),UNIQUE(artifact,origin_id),FOREIGN KEY(artifact,parent) REFERENCES saved_results(artifact,id) DEFERRABLE INITIALLY DEFERRED,FOREIGN KEY(artifact,left_side,left_tree) REFERENCES saved_sides(artifact,side,tree),FOREIGN KEY(artifact,right_side,right_tree) REFERENCES saved_sides(artifact,side,tree),FOREIGN KEY(left_tree,left_entry) REFERENCES saved_entries(tree,id),FOREIGN KEY(right_tree,right_entry) REFERENCES saved_entries(tree,id))""",
"CREATE INDEX saved_results_parent ON saved_results(artifact,parent)",
"CREATE INDEX saved_results_path ON saved_results(artifact,path,id)",
"CREATE INDEX saved_results_left ON saved_results(left_tree,left_entry)",
"CREATE INDEX saved_results_right ON saved_results(right_tree,right_entry)",
"CREATE TABLE saved_groups(artifact TEXT NOT NULL REFERENCES saved_artifacts(id) ON DELETE CASCADE,id TEXT NOT NULL,origin_id INTEGER NOT NULL,path TEXT NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(artifact,id),UNIQUE(artifact,path))",
"CREATE TABLE saved_members(artifact TEXT NOT NULL,group_id TEXT NOT NULL,side TEXT NOT NULL,tree TEXT NOT NULL,entry TEXT NOT NULL,payload TEXT NOT NULL,PRIMARY KEY(artifact,group_id,side,entry),FOREIGN KEY(artifact,group_id) REFERENCES saved_groups(artifact,id) ON DELETE CASCADE,FOREIGN KEY(artifact,side,tree) REFERENCES saved_sides(artifact,side,tree),FOREIGN KEY(tree,entry) REFERENCES saved_entries(tree,id))",
"CREATE INDEX saved_members_entry ON saved_members(tree,entry)",
"CREATE TABLE save_operations(id TEXT NOT NULL PRIMARY KEY,completion_token TEXT NOT NULL,request_cid INTEGER NOT NULL,artifact TEXT UNIQUE REFERENCES saved_artifacts(id) ON DELETE SET NULL,state TEXT NOT NULL CHECK(state IN ('committed','deleted')))",
# Sentinels assert isolation from future Drive Sets without assuming ADR037 schema.
"CREATE TABLE synthetic_drive_set_sentinel(id TEXT PRIMARY KEY,membership TEXT NOT NULL)",
"INSERT INTO synthetic_drive_set_sentinel VALUES('generated','manual-unverified-local-only')",
]

def install(c):
    for sql in DDL:c.execute(sql)
    # Completion receipt simulation. Existing v9 comparison truth is never updated.
    for table in ('p_receipts','p_headers','p_issues'):
        c.execute(f"CREATE TRIGGER {table}_immutable BEFORE UPDATE ON {table} BEGIN SELECT RAISE(ABORT,'immutable receipt'); END")
    c.execute("CREATE TRIGGER artifact_immutable BEFORE UPDATE ON saved_artifacts WHEN OLD.state='ready' BEGIN SELECT RAISE(ABORT,'ready artifact immutable'); END")
    c.execute("CREATE TRIGGER tree_immutable BEFORE UPDATE ON saved_trees WHEN OLD.sealed=1 BEGIN SELECT RAISE(ABORT,'sealed tree immutable'); END")
    for table,parent,col,state in [('saved_sides','saved_artifacts','artifact','state'),('saved_results','saved_artifacts','artifact','state'),('saved_groups','saved_artifacts','artifact','state'),('saved_members','saved_artifacts','artifact','state'),('saved_entries','saved_trees','tree','sealed'),('saved_issues','saved_trees','tree','sealed')]:
        ready="'ready'" if state=='state' else '1'
        for action in ('INSERT','UPDATE','DELETE'):
            ref='NEW' if action=='INSERT' else 'OLD'
            predicate=f"(SELECT {state} FROM {parent} WHERE id={ref}.{col})={ready}"
            if action=='UPDATE':predicate+=f" OR (SELECT {state} FROM {parent} WHERE id=NEW.{col})={ready}"
            c.execute(f"CREATE TRIGGER {table}_{action.lower()}_guard BEFORE {action} ON {table} WHEN {predicate} BEGIN SELECT RAISE(ABORT,'sealed evidence immutable'); END")
    c.execute("CREATE TRIGGER tree_delete_referenced BEFORE DELETE ON saved_trees WHEN EXISTS(SELECT 1 FROM saved_sides WHERE tree=OLD.id) BEGIN SELECT RAISE(ABORT,'referenced backing tree'); END")

@contextlib.contextmanager
def tx(c):
    c.execute('BEGIN IMMEDIATE')
    try:yield;c.execute('COMMIT')
    except BaseException:
        if c.in_transaction:c.execute('ROLLBACK')
        raise

def connect():
    c=sqlite3.connect(':memory:',isolation_level=None);c.row_factory=sqlite3.Row
    c.execute('PRAGMA foreign_keys=ON');assert one(c,'PRAGMA foreign_keys')==1
    return c

def putentry(c,s,n,path,parent=1,typ='file',inaccessible=0):
    name=path.rsplit('/',1)[-1] or 'SYNTHETIC'
    c.execute("""INSERT INTO entries(id,snapshot_id,parent_id,relative_path,case_preserving_path,case_folded_path,name,case_preserving_name,case_folded_name,item_type,logical_size_bytes,is_inaccessible,metadata_signature,sort_key,created_at)
       VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",(eid(s,n),s,eid(s,parent) if parent is not None else None,path,path,path.casefold(),name,name,name.casefold(),typ,n+s,inaccessible,b'generated-metadata-signature',str(n),STAMP))

def freeze(c,cid=1):
    comp=row(c,'SELECT * FROM comparisons WHERE id=?',(cid,));token='synthetic-generation:completion-'+str(cid)
    c.execute('INSERT INTO p_receipts VALUES(?,?,?,?,?)',(token,cid,enc(comp),enc(row(c,'SELECT * FROM comparison_profiles WHERE id=?',(comp['profile_id'],))),'synthetic-engine-contract-v1'))
    for side in ('left','right'):
        sid=comp[side+'_snapshot_id']
        c.execute('INSERT INTO p_headers VALUES(?,?,?,?)',(token,side,sid,enc(row(c,'SELECT * FROM snapshots WHERE id=?',(sid,)))))
        for issue in c.execute('SELECT * FROM scan_issues WHERE snapshot_id=? ORDER BY id',(sid,)):
            c.execute('INSERT INTO p_issues VALUES(?,?,?,?,?)',(token,side,issue['id'],issue['entry_id'],enc(issue)))
    return token

def fixture(kinds=('user','transient'),status='complete',n=9,receipt=True,tie=False):
    c=connect();c.executescript(SCHEMA);install(c)
    with tx(c):
        c.execute("INSERT INTO collections(id,name,normalized_name,created_at,updated_at) VALUES(1,'Generated','generated',?,?)",(STAMP,STAMP))
        for s in (1,2):
            c.execute("INSERT INTO volumes(id,display_name,first_seen_at,last_seen_at,created_at,updated_at) VALUES(?,'SYNTHETIC',?,?,?,?)",(s,STAMP,STAMP,STAMP,STAMP))
            c.execute("""INSERT INTO snapshots(id,volume_id,session_number,scan_root_name,status,scanner_version,schema_version,normalization_version,snapshot_kind,source_case_sensitivity,display_name,capture_policy_json,started_at,created_at,updated_at,collection_id,mount_path_at_capture,volume_display_name_at_capture,warning_count,inaccessible_items,total_files)
              VALUES(?,?,1,'SYNTHETIC','scanning','generated',9,'fsd-normalizer-v1_app-1.0_os-1',?,'unknown','Generated','{}',?,?,?,?,?,'SYNTHETIC',1,1,?)""",(s,s,kinds[s-1],STAMP,STAMP,STAMP,1 if kinds[s-1]=='user' else None,'/synthetic/not-opened',n-3))
            for args in [(1,'',None,'directory',0),(2,'a',1,'directory',0),(3,'b',1,'directory',0),(4,'a/dup',2,'file',0),(5,'b/dup',3,'file',0),(6,'a/DUP',2,'file',0),(7,'onlyRight',1,'file',0),(8,'onlyLeft',1,'file',0),(9,'.DS_Store',1,'file',0),(10,'blocked',1,'file',1)]:
                if args[0]==(8 if s==2 else 7):continue
                putentry(c,s,*args)
            for extra in range(11,n+2):putentry(c,s,extra,f'bulk/{extra:09d}',1)
            c.execute("INSERT INTO scan_issues(snapshot_id,entry_id,relative_path,severity,source,message,was_skipped,created_at) VALUES(?,?,'blocked','warning','reader','generated inaccessible',1,?)",(s,eid(s,10),STAMP))
            c.execute("UPDATE snapshots SET status='complete_with_warnings',completed_at=? WHERE id=?",(STAMP,s))
        c.execute("INSERT INTO comparisons(id,left_snapshot_id,right_snapshot_id,profile_id,profile_version,status,started_at,created_at) VALUES(1,1,2,1,1,'running',?,?)",(STAMP,STAMP))
        spec=[('', 'matched',1,1,0),('b/dup','changed',5,5,2),('onlyRight','added',None,7,0),('onlyLeft','removed',8,None,0),('.DS_Store','ignored',9,9,0),('blocked','uncertain',10,10,0),('a/dup','uncertain',None,None,0)]
        c.execute("INSERT INTO comparison_collision_groups(id,comparison_id,result_path,created_at) VALUES(1,1,'a/dup',?)",(STAMP,))
        for side,s in [('left',1),('right',2)]:
            for k in (4,6):c.execute('INSERT INTO comparison_collision_members(group_id,side,entry_id,created_at) VALUES(1,?,?,?)',(side,eid(s,k),STAMP))
        for i,(path,kind,left,right,flags) in enumerate(spec,1):
            c.execute('INSERT INTO comparison_results(id,comparison_id,parent_result_id,result_path,display_name,result_type,left_entry_id,right_entry_id,difference_flags,created_at) VALUES(?,1,?,?,?,?,?,?,?,?)',(i,None if i==1 else 1,path,path.rsplit('/',1)[-1] or 'SYNTHETIC',kind,eid(1,left) if left else None,eid(2,right) if right else None,flags,STAMP))
        if tie:c.execute("INSERT INTO comparison_results(id,comparison_id,result_path,display_name,result_type,left_entry_id,created_at) VALUES(8,1,'.DS_Store','.DS_Store','ignored',1000009,?)",(STAMP,))
        if status!='running':c.execute('UPDATE comparisons SET status=?,matched_count=1,changed_count=1,added_count=1,removed_count=1,uncertain_count=2,completed_at=? WHERE id=1',(status,STAMP))
        if receipt:freeze(c)
    return c

LEGACY=['volumes','collections','snapshots','entries','scan_issues','comparison_profiles','comparisons','comparison_results','comparison_collision_groups','comparison_collision_members','synthetic_drive_set_sentinel']
def digest(c,tables=LEGACY):
    h=hashlib.sha256()
    for table in tables:
        h.update(table.encode())
        for r in c.execute('SELECT * FROM '+table+' ORDER BY rowid'):h.update(enc(r).encode());h.update(b'\n')
    return h.hexdigest()
def archive_digest(c):
    return digest(c,['saved_artifacts','saved_trees','saved_sides','saved_entries','saved_issues','saved_results','saved_groups','saved_members','save_operations'])

def checks(c):
    assert not c.execute('PRAGMA foreign_key_check').fetchall()
    assert one(c,'PRAGMA integrity_check')=='ok'

def save(c,op='op1',cid=1,fail=None,cancel=None,row_limit=300000,byte_limit=512*1024*1024,time_limit=60,share=None,request_token='synthetic-generation:completion-1'):
    start=time.perf_counter();stats={'entries':0,'rows':0,'bytes':0,'max_batch':0,'checkpoints':0}
    def checkpoint(stage):
        stats['checkpoints']+=1
        if fail==stage:raise Injected(stage)
        if cancel==stage:raise Rejected('cancelled '+stage)
        if time.perf_counter()-start>time_limit:raise Rejected('time budget')
    def account(batch):
        stats['max_batch']=max(stats['max_batch'],len(batch));stats['rows']+=len(batch)
        stats['bytes']+=sum(len(enc(r).encode()) for r in batch)
        if stats['rows']>row_limit or stats['bytes']>byte_limit:raise Rejected('size budget')
        checkpoint('batch')
    with tx(c):
        prior=row(c,'SELECT * FROM save_operations WHERE id=?',(op,))
        if prior:
            if prior['completion_token']!=request_token or prior['request_cid']!=cid:raise Rejected('operation ID conflict')
            if prior['state']=='deleted':raise Rejected('previously deleted; no resurrection')
            assert one(c,"SELECT COUNT(*) FROM saved_artifacts WHERE id=? AND state='ready'",(prior['artifact'],))==1
            return prior['artifact'],stats
        comp=row(c,'SELECT * FROM comparisons WHERE id=?',(cid,))
        if not comp or comp['status']!='complete':raise Rejected('not completed')
        capsule=row(c,'SELECT * FROM p_receipts WHERE cid=?',(cid,))
        if not capsule:raise Rejected('missing completion receipt')
        if capsule['token']!=request_token:raise Rejected('completion generation conflict')
        frozen=json.loads(capsule['comparison_json']);profile=json.loads(capsule['profile_json'])
        if frozen['status']!='complete' or frozen['profile_id']!=profile['id'] or frozen['profile_version']!=profile['version']:raise Rejected('invalid receipt')
        for field in ('id','left_snapshot_id','right_snapshot_id','profile_id','profile_version','status','matched_count','added_count','removed_count','changed_count','uncertain_count'):
            if frozen[field]!=comp[field]:raise Rejected('original receipt conflict')
        aid='saved:'+op;token=capsule['token']
        account([dict(capsule)])
        c.execute("INSERT INTO saved_artifacts VALUES(?,?,?,?,?,'building',?)",(aid,token,capsule['comparison_json'],capsule['profile_json'],capsule['engine_contract'],STAMP));checkpoint('artifact')
        trees={}
        for side in ('left','right'):
            header=row(c,'SELECT * FROM p_headers WHERE token=? AND side=?',(token,side))
            if not header:raise Rejected('missing side receipt')
            account([dict(header)])
            sid=header['snapshot_id'];snapshot=row(c,'SELECT * FROM snapshots WHERE id=?',(sid,))
            if not snapshot or snapshot['status'] not in ('complete','complete_with_warnings'):raise Rejected('ineligible side')
            tid=op+':'+side
            if share:
                found=row(c,"SELECT t.* FROM saved_trees t JOIN saved_sides s ON s.tree=t.id WHERE s.artifact=? AND s.side=?",(share,side))
                if not found or found['completion_token']!=token or found['header_json']!=header['header_json'] or found['origin_snapshot']!=sid or found['sealed']!=1:raise Rejected('share provenance mismatch')
                tid=found['id']
            else:
                c.execute('INSERT INTO saved_trees VALUES(?,?,?,?,?,0)',(tid,token,side,sid,header['header_json']));checkpoint(side+'_tree')
                for batch in pages(c,'SELECT * FROM entries WHERE snapshot_id=? AND id>? ORDER BY id LIMIT ?',(sid,)):
                    account(batch)
                    c.executemany('INSERT INTO saved_entries VALUES(?,?,?,?,?,?)',((tid,tid+':e'+str(r['id']),r['id'],tid+':e'+str(r['parent_id']) if r['parent_id'] is not None else None,r['relative_path'],enc(r)) for r in batch));stats['entries']+=len(batch)
                checkpoint(side+'_entries')
                for batch in pages(c,'SELECT * FROM p_issues WHERE token=? AND side=? AND id>? ORDER BY id LIMIT ?',(token,side)):
                    account(batch)
                    c.executemany('INSERT INTO saved_issues VALUES(?,?,?,?)',((tid,r['id'],tid+':e'+str(r['entry_origin']) if r['entry_origin'] is not None else None,r['payload']) for r in batch))
                checkpoint(side+'_issues')
                # Exactly one root, all parents resolve inside this tree; no path-key remapping.
                if one(c,'SELECT COUNT(*) FROM saved_entries WHERE tree=? AND parent IS NULL AND path=\'\'',(tid,))!=1:raise Rejected('root mismatch')
                c.execute('UPDATE saved_trees SET sealed=1 WHERE id=?',(tid,))
            trees[side]=tid;c.execute('INSERT INTO saved_sides VALUES(?,?,?)',(aid,side,tid));checkpoint(side+'_side')
        for batch in pages(c,'SELECT * FROM comparison_results WHERE comparison_id=? AND id>? ORDER BY id LIMIT ?',(cid,)):
            account(batch)
            for r in batch:
                c.execute('INSERT INTO saved_results(artifact,id,origin_id,parent,path,kind,left_tree,left_entry,right_tree,right_entry,flags,payload) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',(aid,aid+':r'+str(r['id']),r['id'],aid+':r'+str(r['parent_result_id']) if r['parent_result_id'] is not None else None,r['result_path'],r['result_type'],trees['left'],trees['left']+':e'+str(r['left_entry_id']) if r['left_entry_id'] is not None else None,trees['right'],trees['right']+':e'+str(r['right_entry_id']) if r['right_entry_id'] is not None else None,r['difference_flags'],enc(r)))
        checkpoint('results')
        for batch in pages(c,'SELECT * FROM comparison_collision_groups WHERE comparison_id=? AND id>? ORDER BY id LIMIT ?',(cid,)):
            account(batch)
            for r in batch:c.execute('INSERT INTO saved_groups VALUES(?,?,?,?,?)',(aid,aid+':g'+str(r['id']),r['id'],r['result_path'],enc(r)))
        checkpoint('groups')
        for batch in pages(c,'SELECT m.* FROM comparison_collision_members m JOIN comparison_collision_groups g ON g.id=m.group_id WHERE g.comparison_id=? AND m.id>? ORDER BY m.id LIMIT ?',(cid,)):
            account(batch)
            for r in batch:c.execute('INSERT INTO saved_members VALUES(?,?,?,?,?,?)',(aid,aid+':g'+str(r['group_id']),r['side'],trees[r['side']],trees[r['side']]+':e'+str(r['entry_id']),enc(r)))
        checkpoint('members')
        counts={r['kind']:r['n'] for r in c.execute('SELECT kind,COUNT(*) n FROM saved_results WHERE artifact=? GROUP BY kind',(aid,))}
        for kind in ('matched','added','removed','changed','uncertain'):
            if counts.get(kind,0)!=frozen[kind+'_count']:raise Rejected('count mismatch')
        for old,new in [('comparison_results','saved_results'),('comparison_collision_groups','saved_groups')]:
            if one(c,'SELECT COUNT(*) FROM '+old+' WHERE comparison_id=?',(cid,))!=one(c,'SELECT COUNT(*) FROM '+new+' WHERE artifact=?',(aid,)):raise Rejected('closure row count mismatch')
        if one(c,'SELECT COUNT(*) FROM comparison_collision_members m JOIN comparison_collision_groups g ON g.id=m.group_id WHERE g.comparison_id=?',(cid,))!=one(c,'SELECT COUNT(*) FROM saved_members WHERE artifact=?',(aid,)):raise Rejected('member count mismatch')
        if one(c,'SELECT COUNT(*) FROM saved_sides WHERE artifact=?',(aid,))!=2:raise Rejected('side mismatch')
        if c.execute('PRAGMA foreign_key_check').fetchone():raise Rejected('FK validation')
        checkpoint('validated')
        c.execute("UPDATE saved_artifacts SET state='ready' WHERE id=?",(aid,));checkpoint('ready')
        c.execute("INSERT INTO save_operations VALUES(?,?,?,?,'committed')",(op,token,cid,aid));checkpoint('operation');checkpoint('precommit')
    stats['transaction_seconds']=round(time.perf_counter()-start,6)
    return aid,stats

BOUNDARIES=['artifact','left_tree','left_entries','left_issues','left_side','right_tree','right_entries','right_issues','right_side','results','groups','members','validated','ready','operation','precommit']

def dispose(c):
    # Equivalent completed live-side disposal predicate; no production code executed.
    with tx(c):c.execute("DELETE FROM comparisons WHERE id IN(SELECT c.id FROM comparisons c JOIN snapshots l ON l.id=c.left_snapshot_id JOIN snapshots r ON r.id=c.right_snapshot_id WHERE l.snapshot_kind='transient' OR r.snapshot_kind='transient')")
    with tx(c):c.execute("DELETE FROM snapshots WHERE snapshot_kind='transient' AND id NOT IN(SELECT left_snapshot_id FROM comparisons UNION SELECT right_snapshot_id FROM comparisons)")

def delete_saved(c,aid):
    with tx(c):
        c.execute("UPDATE save_operations SET state='deleted' WHERE artifact=?",(aid,))
        # Gather only this artifact's two tree IDs, never all archives.
        trees=[r[0] for r in c.execute('SELECT tree FROM saved_sides WHERE artifact=?',(aid,))]
        c.execute('DELETE FROM saved_artifacts WHERE id=?',(aid,))
        for tree in trees:
            if not one(c,'SELECT 1 FROM saved_sides WHERE tree=? LIMIT 1',(tree,)):c.execute('DELETE FROM saved_trees WHERE id=?',(tree,))

def exact_copy(c,aid):
    a=row(c,'SELECT * FROM saved_artifacts WHERE id=?',(aid,));assert a['state']=='ready'
    f=json.loads(a['comparison_json']);p=json.loads(a['profile_json']);assert (p['id'],p['version'])==(f['profile_id'],f['profile_version'])
    for side in ('left','right'):
        t=row(c,'SELECT t.* FROM saved_trees t JOIN saved_sides s ON s.tree=t.id WHERE s.artifact=? AND s.side=?',(aid,side));assert t['origin_snapshot']==f[side+'_snapshot_id']
        assert t['header_json']==one(c,'SELECT header_json FROM p_headers WHERE token=? AND side=?',(a['completion_token'],side))
        assert one(c,'SELECT COUNT(*) FROM saved_entries WHERE tree=?',(t['id'],))==one(c,'SELECT COUNT(*) FROM entries WHERE snapshot_id=?',(t['origin_snapshot'],))
        for saved in c.execute('SELECT * FROM saved_entries WHERE tree=? ORDER BY origin_id',(t['id'],)):
            original=row(c,'SELECT * FROM entries WHERE id=?',(saved['origin_id'],));assert enc(original)==saved['payload']
            assert saved['parent']==(t['id']+':e'+str(original['parent_id']) if original['parent_id'] is not None else None)
        for issue in c.execute('SELECT * FROM saved_issues WHERE tree=?',(t['id'],)):
            assert issue['payload']==one(c,'SELECT payload FROM p_issues WHERE token=? AND side=? AND id=?',(a['completion_token'],side,issue['id']))
    for r in c.execute('SELECT * FROM saved_results WHERE artifact=? ORDER BY origin_id',(aid,)):
        original=row(c,'SELECT * FROM comparison_results WHERE id=?',(r['origin_id'],));assert enc(original)==r['payload']
        for side in ('left','right'):
            assert r[side+'_entry']==(r[side+'_tree']+':e'+str(original[side+'_entry_id']) if original[side+'_entry_id'] is not None else None)
    for r in c.execute('SELECT * FROM saved_groups WHERE artifact=?',(aid,)):
        assert r['payload']==enc(row(c,'SELECT * FROM comparison_collision_groups WHERE id=?',(r['origin_id'],)))
    for r in c.execute('SELECT * FROM saved_members WHERE artifact=?',(aid,)):
        original=json.loads(r['payload'])
        assert r['payload']==enc(row(c,'SELECT * FROM comparison_collision_members WHERE id=?',(original['id'],)))
        assert r['entry']==r['tree']+':e'+str(original['entry_id'])
    return True

def offline(c,aid,expected=7):
    a=row(c,"SELECT * FROM saved_artifacts WHERE id=? AND state='ready'",(aid,));assert a
    assert one(c,'SELECT COUNT(*) FROM saved_sides WHERE artifact=?',(aid,))==2
    n=0;last=('','')
    while True:
        batch=c.execute('SELECT * FROM saved_results WHERE artifact=? AND (path,id)>(?,?) ORDER BY path,id LIMIT 3',(aid,*last)).fetchall()
        if not batch:break
        for r in batch:
            for side in ('left','right'):
                if r[side+'_entry'] is not None:assert row(c,'SELECT payload FROM saved_entries WHERE tree=? AND id=?',(r[side+'_tree'],r[side+'_entry']))
        n+=len(batch);last=(batch[-1]['path'],batch[-1]['id'])
    assert n==expected;return n

def reject(fn,exc=Rejected,contains=''):
    try:fn()
    except exc as e:
        assert contains in str(e),(contains,str(e));return
    raise AssertionError('expected rejection')

RESULTS=[]
def case(label,expected,fn,**fixture_args):
    c=fixture(**fixture_args);before=digest(c)
    try:
        actual=fn(c);assert actual==expected,(expected,actual);checks(c)
        # Cleanup and deliberate current-profile/header changes have their own expected assertions.
        unchanged=digest(c)==before
        if not label.startswith(('CL','PF','HD')):assert unchanged,'original data changed'
        RESULTS.append(dict(id=f'SV{len(RESULTS)+1:02}',case=label,label='SYNTHETIC_PROTOTYPE',expected=expected,actual=actual,result='PASS',original_unchanged=unchanged,fk_check=[],integrity_check='ok'))
    except Exception as e:RESULTS.append(dict(id=f'SV{len(RESULTS)+1:02}',case=label,expected=expected,result='FAIL',error=repr(e)))
    finally:c.close()

def run_cases():
    def basic(c):
        a,_=save(c);assert exact_copy(c,a);return 'exact complete archive'
    for label,kinds in [('snapshot-snapshot',('user','user')),('live-user',('user','transient')),('live-live',('transient','transient'))]:case(label,'exact complete archive',basic,kinds=kinds)
    for state in ('failed','cancelled','running'):
        def ineligible(c):reject(lambda:save(c),contains='not completed');assert one(c,'SELECT COUNT(*) FROM saved_artifacts')==0;return 'no saved artifact'
        case('status-'+state,'no saved artifact',ineligible,status=state)
    def mappings(c):
        a,_=save(c);assert exact_copy(c,a)
        assert one(c,"SELECT COUNT(*) FROM saved_members WHERE artifact=?",(a,))==4
        assert one(c,"SELECT COUNT(*) FROM saved_results WHERE artifact=? AND kind='uncertain'",(a,))==2
        assert one(c,"SELECT COUNT(*) FROM saved_entries WHERE path LIKE '%dup' OR path LIKE '%DUP'")==6
        return 'orientation/profile/parents/results/collisions/duplicate paths exact'
    case('mapping-closure','orientation/profile/parents/results/collisions/duplicate paths exact',mappings)
    def warnings(c):
        a,_=save(c);assert exact_copy(c,a)
        assert one(c,'SELECT COUNT(*) FROM saved_issues')==2
        assert sum(json.loads(r[0])['is_inaccessible'] for r in c.execute('SELECT payload FROM saved_entries'))==2
        return 'warnings and inaccessible evidence retained'
    case('warnings','warnings and inaccessible evidence retained',warnings)
    def clean(c):
        a,_=save(c);user_before=digest(c,['collections','synthetic_drive_set_sentinel'])
        dispose(c);assert one(c,'SELECT COUNT(*) FROM comparisons')==0
        assert one(c,"SELECT COUNT(*) FROM snapshots WHERE snapshot_kind='transient'")==0
        assert one(c,"SELECT COUNT(*) FROM snapshots WHERE snapshot_kind='user'")==1
        assert offline(c,a)==7 and digest(c,['collections','synthetic_drive_set_sentinel'])==user_before
        return 'offline archive survives original live cleanup'
    case('CL-offline-cleanup','offline archive survives original live cleanup',clean)
    def persistent(c):dispose(c);assert one(c,'SELECT COUNT(*) FROM comparisons')==1;return 'ordinary comparison retained'
    case('snapshot-persistence','ordinary comparison retained',persistent,kinds=('user','user'))
    def kindguard(c):reject(lambda:c.execute("UPDATE snapshots SET snapshot_kind='user' WHERE id=2"),sqlite3.IntegrityError);return 'transient conversion rejected'
    case('kind-guard','transient conversion rejected',kindguard)
    def guards(c):
        for sql in ["UPDATE comparisons SET matched_count=99 WHERE id=1","UPDATE comparisons SET left_snapshot_id=2 WHERE id=1","UPDATE comparison_results SET difference_flags=99 WHERE id=2","DELETE FROM comparison_results WHERE id=1","DELETE FROM comparison_collision_members WHERE group_id=1","UPDATE entries SET name='changed' WHERE id=1000004"]:reject(lambda sql=sql:c.execute(sql),sqlite3.IntegrityError)
        return 'original terminal/capture evidence rejects mutation'
    case('original-guards','original terminal/capture evidence rejects mutation',guards)
    for boundary in BOUNDARIES:
        def fail(c,boundary=boundary):
            before=archive_digest(c);reject(lambda:save(c,fail=boundary),Injected,boundary)
            assert archive_digest(c)==before and one(c,"SELECT COUNT(*) FROM saved_artifacts WHERE state='ready'")==0
            a,_=save(c);assert exact_copy(c,a);return 'rollback and known-failure retry exact'
        case('fail-'+boundary,'rollback and known-failure retry exact',fail)
    def retry(c):
        a,_=save(c);before=archive_digest(c);b,_=save(c);assert a==b and archive_digest(c)==before
        return 'uncertain-ack retry returns same committed artifact'
    case('idempotent','uncertain-ack retry returns same committed artifact',retry)
    def opconflict(c):save(c);reject(lambda:save(c,cid=999),contains='operation ID conflict');return 'operation ID cannot name different comparison'
    case('operation-conflict','operation ID cannot name different comparison',opconflict)
    for stage in ('batch','precommit'):
        def cancel(c,stage=stage):
            before=archive_digest(c);reject(lambda:save(c,cancel=stage),contains='cancelled');assert archive_digest(c)==before;return 'cancelled save leaves no partial graph'
        case('cancel-'+stage,'cancelled save leaves no partial graph',cancel)
    def missing(c):
        reject(lambda:save(c),contains='missing completion receipt');return 'legacy comparison without receipt fails closed'
    case('legacy-no-receipt','legacy comparison without receipt fails closed',missing,receipt=False)
    def profile(c):
        c.execute("UPDATE comparison_profiles SET name='Later',version=2,ignore_rules_json='[]' WHERE id=1")
        a,_=save(c);p=json.loads(one(c,'SELECT profile_json FROM saved_artifacts WHERE id=?',(a,)))
        assert p['name']=='Fast Metadata' and p['version']==1;return 'archive uses completion profile not current profile'
    case('PF-current-profile-change','archive uses completion profile not current profile',profile)
    def headers(c):
        c.execute("UPDATE snapshots SET warning_count=99,total_files=999,display_name='Later' WHERE id=2")
        a,_=save(c);h=json.loads(one(c,"SELECT t.header_json FROM saved_trees t JOIN saved_sides s ON s.tree=t.id WHERE s.artifact=? AND s.side='right'",(a,)))
        assert h['warning_count']==1 and h['display_name']=='Generated';return 'archive uses completion header not mutable save-time header'
    case('HD-current-header-change','archive uses completion header not mutable save-time header',headers)
    def missingfk(c):
        a,_=save(c);reject(lambda:c.execute('DELETE FROM saved_trees WHERE id=?',('op1:left',)),sqlite3.IntegrityError)
        with tx(c):
            c.execute("INSERT INTO saved_artifacts VALUES('bad','bad','{}','{}','test','building',?)",(STAMP,))
            reject(lambda:c.execute("INSERT INTO saved_sides VALUES('bad','left','missing')"),sqlite3.IntegrityError)
            c.execute("DELETE FROM saved_artifacts WHERE id='bad'")
        return 'missing and referenced backing rejected'
    case('backing-fks','missing and referenced backing rejected',missingfk)
    def sharing(c):
        a,_=save(c);b,_=save(c,'op2',share=a);assert one(c,'SELECT COUNT(*) FROM saved_trees')==2
        delete_saved(c,a);assert offline(c,b)==7 and one(c,'SELECT COUNT(*) FROM saved_trees')==2
        reject(lambda:save(c),contains='previously deleted');delete_saved(c,b)
        assert one(c,'SELECT COUNT(*) FROM saved_trees')==0 and one(c,'SELECT COUNT(*) FROM saved_entries')==0
        assert one(c,'SELECT COUNT(*) FROM save_operations WHERE state=\'deleted\' AND artifact IS NULL')==2
        return 'shared trees retained until final explicit delete; receipt prevents resurrection'
    case('shared-delete','shared trees retained until final explicit delete; receipt prevents resurrection',sharing)
    def sealed(c):
        a,_=save(c)
        for sql in ["UPDATE saved_artifacts SET profile_json='{}'","UPDATE saved_entries SET payload='{}'","DELETE FROM saved_results","DELETE FROM saved_members","UPDATE saved_trees SET header_json='{}'"]:reject(lambda sql=sql:c.execute(sql),sqlite3.IntegrityError)
        return 'published dedicated evidence immutable'
    case('archive-guards','published dedicated evidence immutable',sealed)
    for label,kw in [('row-limit',{'row_limit':1}),('byte-limit',{'byte_limit':1}),('time-limit',{'time_limit':-1})]:
        def limit(c,kw=kw):
            before=archive_digest(c);reject(lambda:save(c,**kw));assert archive_digest(c)==before;return 'budget rejection is atomic'
        case(label,'budget rejection is atomic',limit)
    def empty_page(c):
        a,_=save(c);assert not c.execute('SELECT * FROM saved_results WHERE artifact=? AND (path,id)>(?,?) ORDER BY path,id LIMIT 3',(a,'zzzz','zzzz')).fetchall()
        assert one(c,"SELECT COUNT(*) FROM saved_results WHERE artifact=? AND path='.DS_Store'",(a,))==2
        assert offline(c,a,8)==8;return 'first/root/tied path/end pages deterministic'
    case('page-edges','first/root/tied path/end pages deterministic',empty_page,tie=True)
    def memory_reopen(c):
        a,_=save(c);other=connect();c.backup(other);before=archive_digest(other);again,_=save(other);assert a==again and archive_digest(other)==before;offline(other,a);checks(other);other.close()
        return 'memory-copy reopen retries committed receipt exactly'
    case('memory-reopen','memory-copy reopen retries committed receipt exactly',memory_reopen)
    def fk_cross(c):
        # Exercise side ownership in unsealed construction, before ready guards.
        a,_=save(c)
        with tx(c):
            c.execute("INSERT INTO saved_artifacts SELECT 'wrong',completion_token,comparison_json,profile_json,engine_contract,'building',created_at FROM saved_artifacts WHERE id=?",(a,))
            c.execute("INSERT INTO saved_sides SELECT 'wrong',side,tree FROM saved_sides WHERE artifact=?",(a,))
            reject(lambda:c.execute("INSERT INTO saved_results(artifact,id,origin_id,path,kind,left_tree,left_entry,right_tree,flags,payload) VALUES('wrong','wrong:r1',1,'','matched','op1:right','op1:right:e2000001','op1:right',0,'{}')"),sqlite3.IntegrityError)
            c.execute("DELETE FROM saved_artifacts WHERE id='wrong'")
        return 'cross-side reference rejected before publication'
    case('cross-side-fk','cross-side reference rejected before publication',fk_cross)
    def after_cleanup(c):
        a,_=save(c);dispose(c);before=archive_digest(c)
        b,_=save(c);assert a==b and archive_digest(c)==before and offline(c,a)==7
        return 'committed operation retry works after original disposal'
    case('CL-retry-after-disposal','committed operation retry works after original disposal',after_cleanup)
    def missing_entry(c):
        a,_=save(c)
        with tx(c):
            c.execute("INSERT INTO saved_artifacts SELECT 'missing',completion_token,comparison_json,profile_json,engine_contract,'building',created_at FROM saved_artifacts WHERE id=?",(a,))
            c.execute("INSERT INTO saved_sides SELECT 'missing',side,tree FROM saved_sides WHERE artifact=?",(a,))
            reject(lambda:c.execute("INSERT INTO saved_results(artifact,id,origin_id,path,kind,left_tree,left_entry,right_tree,flags,payload) VALUES('missing','missing:r1',1,'','matched','op1:left','no-such-entry','op1:right',0,'{}')"),sqlite3.IntegrityError)
            c.execute("DELETE FROM saved_artifacts WHERE id='missing'")
        return 'missing entry FK rejected in unsealed construction'
    case('missing-entry-fk','missing entry FK rejected in unsealed construction',missing_entry)
    def generation(c):
        save(c)
        reject(lambda:save(c,request_token='synthetic-generation:new-completion-1'),contains='operation ID conflict')
        return 'same numeric comparison ID with different completion token rejected'
    case('generation-bound-operation','same numeric comparison ID with different completion token rejected',generation)

    receipt=dict(label='SYNTHETIC_PROTOTYPE',python=sys.version.split()[0],sqlite=sqlite3.sqlite_version,connections=':memory: only',schema_sha256=hashlib.sha256(SCHEMA.encode()).hexdigest(),executed=len(RESULTS),passed=sum(r['result']=='PASS' for r in RESULTS),failed=sum(r['result']=='FAIL' for r in RESULTS),cases=RESULTS)
    OUT.joinpath('results.json').write_text(json.dumps(receipt,indent=2)+'\n')
    for r in RESULTS:print(r['id'],r['case'],r['result'],r.get('error',r.get('actual')))
    print('TOTAL',receipt['executed'],'PASS',receipt['passed'],'FAIL',receipt['failed'])
    return receipt['failed']

def large(total):
    assert total in (10000,100000)
    n=total//2
    start=time.perf_counter();c=fixture(n=n);seed_seconds=time.perf_counter()-start
    assert one(c,'SELECT COUNT(*) FROM entries')==total
    before=digest(c);rss_before=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    aid,stats=save(c,row_limit=300000,byte_limit=512*1024*1024,time_limit=60)
    assert stats['entries']==total and stats['max_batch']<=PAGE and digest(c)==before
    # Streaming read of both archived trees in keyset pages and SQL indexed origin mapping.
    read_count=0;read_start=time.perf_counter()
    for t in c.execute('SELECT tree FROM saved_sides WHERE artifact=? ORDER BY side',(aid,)):
        last=0
        while True:
            batch=c.execute('SELECT * FROM saved_entries WHERE tree=? AND origin_id>? ORDER BY origin_id LIMIT ?',(t['tree'],last,PAGE)).fetchall()
            if not batch:break
            assert len(batch)<=PAGE
            for r in batch:
                assert r['origin_id']>last;last=r['origin_id'];read_count+=1
    assert read_count==total;checks(c)
    plan=[r[3] for r in c.execute('EXPLAIN QUERY PLAN SELECT * FROM saved_entries WHERE tree=? AND origin_id>? ORDER BY origin_id LIMIT ?',('op1:left',0,PAGE))]
    assert any('SEARCH' in r and 'INDEX' in r for r in plan) and not any('TEMP B-TREE' in r for r in plan)
    rss_after=resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    receipt=dict(label='SYNTHETIC_PROTOTYPE',total_entries=total,processed=stats['entries'],read_processed=read_count,batch_rows=PAGE,max_batch=stats['max_batch'],seed_seconds=round(seed_seconds,6),save_transaction_seconds=stats['transaction_seconds'],read_seconds=round(time.perf_counter()-read_start,6),copied_rows=stats['rows'],serialized_metadata_bytes=stats['bytes'],checkpoints=stats['checkpoints'],query_plan=plan,ru_maxrss_before=rss_before,ru_maxrss_after=rss_after,ru_maxrss_unit='bytes' if sys.platform=='darwin' else 'KiB',platform=sys.platform,limits='300000 copied rows;512MiB serialized metadata;60s elapsed budget;checkpoint each batch',measurement_limit='Process high-water includes original and archive in-memory SQLite, Python, validation and seed. Not Swift RSS, source throughput, disk/WAL size or crash durability.',original_digest_unchanged=True,fk_check=[],integrity_check='ok')
    OUT.joinpath('large-'+str(total)+'.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2));c.close()

if __name__=='__main__':
    if len(sys.argv)==3 and sys.argv[1]=='--large':large(int(sys.argv[2]))
    else:raise SystemExit(bool(run_cases()))
```
