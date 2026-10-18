# Task055 Drive Sets Relational Model and SQLite Feasibility — Worker return

## HOT

HMD_SCHEMA=FSD_HANDOFF_MARKDOWN
HMD_VERSION=1.0.0
PROJECT=FSD
WORKSTREAM_ID=FSD2_DRIVE_SETS_SCHEMA_FEASIBILITY
HANDOFF_ID=handoffs/FSD_FSD2_DRIVE_SETS_SCHEMA_FEASIBILITY_055_D_20261018-204459.md
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
LOCAL_HEAD=1b903385d1093b52dec3661a238e09063ce7b9a2
REMOTE_HEAD=1b903385d1093b52dec3661a238e09063ce7b9a2
LAST_VERIFIED_AT=2026-10-18T20:44:59+07:00
AUTHORITY_PTRS=AGENTS.md|docs/BRAIN_OPERATOR.md|docs/AGENT.md|STATE/PROJECT_STATE.md|STATE/TASK_LEDGER.tsv|STATE/EVENTS.jsonl|handoffs/CURRENT_HANDOFF.md|.agents/skills/fsd-task-execution/SKILL.md|.agents/skills/fsd-handoff-finalizer/SKILL.md|docs/DECISIONS.md|docs/SNAPSHOT_COLLECTIONS.md|docs/PRD.md|docs/UX_UI_SPEC.md|docs/ARCHITECTURE.md|docs/TEST_PLAN.md|docs/MVP_PLAN.md|docs/database/schema.sql|FSD/Catalog/CatalogDatabase.swift|FSD/Catalog/CatalogMigrations.swift|FSD/Catalog/SnapshotCollectionRepository.swift|FSD/Model/SnapshotModels.swift|scripts/check_control_plane.py
CURRENT_PHASE=POST_V0_1_FSD2_FOUNDATION
CURRENT_GATE=FSD2_ADR037_DRIVE_SETS_SCHEMA_FEASIBILITY_055
STATUS=WORKER_COMPLETE_PENDING_BRAIN
BLOCKER=NONE_FOR_SYNTHETIC_FEASIBILITY;PRODUCTION_SCHEMA_MIGRATION_AND_IDENTITY_PROOF_PENDING
PROPOSED_NEXT=WAIT(BRAIN_REVIEW_TASK055_RELATIONAL_FEASIBILITY_AND_PENDING_BOUNDARIES)
NO_AUTO_NEXT=YES

## Task lock and re-anchor

PROJECT=FSD
TASK_ID=FSD2_DRIVE_SETS_SCHEMA_FEASIBILITY_055
ROLE=WORKER
REPO=/Users/cenvu/DEV/FSD
BRANCH=main
BASE_HEAD=1b903385d1093b52dec3661a238e09063ce7b9a2
UPSTREAM_HEAD=1b903385d1093b52dec3661a238e09063ce7b9a2
ACCEPTED_STATE=STATE/PROJECT_STATE.md
SCOPE=ADR037_RELATIONAL_FEASIBILITY_ONLY
ALLOWED_PATHS=docs/DECISIONS.md_ADR037_ONLY|docs/ARCHITECTURE.md|docs/TEST_PLAN.md|docs/PRD.md_SECTION2_ONLY|.ai-scratch/task055/|one_new_history|CURRENT|Worker_ledger_event|Desktop_transport
FORBIDDEN_PATHS=ALL_OTHER_TRACKED_FILES|OWNER_MEDIA_CATALOG_DEVICES|SOURCE_ROOTS|RELEASE_TAGS
SUCCESS_CRITERIA=DETERMINISTIC_RELATIONAL_CONTRACT_SQLITE_NEGATIVES_MIGRATION_PLAN_REVIEW_PUBLICATION
VALIDATIONS=PYTHON_SQLITE_SYNTHETIC|DIFF|LINKS|HASHES|PRE_POST_CHECKER|DESKTOP_PARITY|CLEAN_SYNCED
NEXT_BOUNDARY=RETURN_TO_BRAIN_ONLY

Initial clean main was 809ebaec1818e5093491bf0b2e1a8d7bf0d078ce. Non-destructive
fetch found one BRAIN-only upstream commit changing accepted State, ledger and
events. Its full diff was inspected, then git pull --ff-only origin main safely
advanced to the exact expected base above. Fresh finalizer-entry fetch confirmed
local/upstream equality and 0/0; only the four authorized docs were dirty.
Origin: https://github.com/cenvu/FSD.git. No reset/clean/stash/rebase/force.
Accepted State authorizes exactly Task055; Task054 is accepted feasibility-only
PASS_WITH_ADVISORY at 809ebaec1818e5093491bf0b2e1a8d7bf0d078ce. Zero real strong
hardware profiles are approved. This return is Worker-local PASS_WITH_ADVISORY;
classification remains pending BRAIN and no accepted State is changed.

## Verified relational delta — FACT unless labelled pending

- DECISIONS: only proposed ADR-037 refined. Stable catalog-local IDs, empty sets,
  many-to-many pair PK, set-to-membership CASCADE only, drive RESTRICT/tombstone,
  explicit/manual-unverified admission, conflict/revoke no-retarget, name policy
  alternatives, transactions, revision/idempotency, bounded reads and migration
  boundaries. ADR-019/020/036/038 and all accepted semantics remain unchanged.
- ARCHITECTURE: append-only §12 inventories real schema-v9/Collection/migration
  code and official SQLite/Python Q1–Q7 URLs, candidate entities/DDL/constraints,
  complete deletion graph, Unicode alternatives and explicit future sequence.
  Existing volume ID is not upgraded to physical identity. Final table shape,
  PhysicalDrive creation policy and production migration remain pending.
- TEST_PLAN: append-only §11 records all DS01–38 expected/actual outcomes and
  requirements-to-future-production matrix, failure correction, evidence limits
  and read-only cross-document advisories. No production PASS is claimed.
- PRD: only §2 replaces pre-direction wording with dated 2026-10-18 Owner target;
  preserves snapshot Collections, zero-or-one membership and NULL Unsorted.
  Direction does not accept schema/identity or remove existing requirements.

PhysicalDrive is a local catalog record; a manual label/association does not
verify hardware. Unknown/Ambiguous/Conflict observations never supply membership.
Offline manual local-record selection is separate from resolving a live device.
All membership remains explicit, including after any hypothetical strong match;
mounts authorize no capture. No profile or Auto Capture enabled; default OFF.

Future migration is additive, explicit ADR-024 transactions with FK/expected
object verification. Existing supported old catalogs first follow accepted steps
to v9; legacy physical identity stays unknown, without UUID/path/name/file-ID
backfill or history rewrite. Tombstones preserve membership/history. Set deletion
has no edge into snapshots/entries/Collections/volumes/comparison evidence.
The exact final schema/version, normalization parity, migration paths,
association persistence, crash durability, contention and scale require separate
review/authorization and production evidence. No version is reserved here.

## Executed synthetic evidence and correction

Command: python3 .ai-scratch/task055/harness.py — final exit 0.
38 executed / 38 PASS / 0 FAIL; SYNTHETIC_PROTOTYPE.
Python 3.15.0 / SQLite 3.54.0 / Unicode 17.0.0.
All SQLite connections :memory:; FK asserted ON; no catalog filename accepted.
Source schema SHA256: 4b65d6c285ebaa353eec8439453199ce90f42cb33d670a6bb7d7410e28cdf815.
Runnable harness SHA256: 0fd7d96f59506e14725a904d63fac39465cb1b810c0dbf0401167ca2c9177553.

Every case seeds generated schema-v9 rows (including cloned volume UUID,
complete snapshots/entries, Collection/NULL, terminal comparison/result and
synthetic saved sentinel), then verifies all legacy table row values unchanged,
FK check empty, integrity_check ok and exact new-object definitions. Existing
SQL objects remain unchanged after additive prototype setup. The sentinel is
not ADR-038 implementation. DS29 traverses 257 sets at 17+1 without skips or
duplicates; measured plan SEARCH drive_sets USING INDEX sqlite_autoindex_drive_sets_2
(normalized_name>?). DS30 finds covering seeks in both membership directions.
DS37 walks real FK metadata; cascade closure from set is only set plus pairs.
The complete explicit expected/actual table is published in TEST_PLAN §11;
source below contains each generated input, assertion and expected outcome.

Initial run: 37 PASS / 1 FAIL (DS33). Deliberate index removal correctly caused
same-version verification failure; the restore selected DDL[5], the membership
TABLE instead of the index. Actual error: table drive_set_memberships already
exists. Inspected root cause; restored by the exact index statement name instead
of positional assumption, reran all 38 successfully. Initial results retained
in ignored initial-results.json. No product failure, schema repair or unknown
catalog was involved. No repeated blind patch or three-failure trigger occurred.

Prototype boundaries: memory-copy reopen is not process crash/disk/WAL proof;
stale revision is not concurrent contention; Python Unicode cases are not
Foundation parity; manually seeded stubs and policy-gate tests are not ADR-036
resolver/event persistence; no real Swift migration or historical v4–v8 catalogs
were executed. Ordinary production create retry, bulk correction and cursor
invalidation remain explicit future gates, not claimed tests.

## Execution review, requirements and limits

Full four-document diff reviewed against current canonical authorities and
actual relevant v9/Collection source. No independent review or BRAIN acceptance
is claimed. Fresh git diff --check passed. validate.py passed 51 local Markdown
path/anchor destinations; all 1509 protected tracked paths preserved (symlinks
hashed as link text without dereference), including 107 prior historical
handoffs, accepted State/rule ledger and production/schema/tests. ADR text
outside 037 is byte-identical; PRD outside §2 is byte-identical; old ARCHITECTURE
and TEST_PLAN text is unchanged. Accepted State SHA256:
d47a568d07c2c983d49bce9db54f69f66783a34704d3fbcf0f8daee6cb69696c.

Baseline receipt construction first encountered an existing broken fixture
symlink and Git's quoted Unicode filenames. No protected writes occurred;
corrected by non-dereferenced symlink hashing and git ls-files -z. The successful
baseline was captured before any tracked mutation. These were read-only
inventory handling defects, not source-device inspection.

| Requirement | Execution accounting / evidence |
|---|---|
| R01 authority/Git/bootstrap | EVIDENCED — exact ACTION, safe FF, task lock, baseline/fresh fetch |
| R02 mandatory scoped authorities/source | EVIDENCED — HOT, kernel/Compact/skills, named ADR/product/Collection/schema/migration/model refs |
| R03 official relational research | EVIDENCED — ARCHITECTURE Q1–Q7 exact official links |
| R04 binding separate grouping/local IDs | EVIDENCED — ADR037; DS01–07/25/36 |
| R05 keys/FKs/index/deletion | EVIDENCED — candidate DDL; DS04–06/20–22/30/36/37 |
| R06 no weak/automatic hardware membership | EVIDENCED — DS14–18/38 gate; empty real profile set explicit |
| R07 offline/correct/revoke/tombstone | EVIDENCED — DS13/19/22 surrogate and pending event persistence design |
| R08 atomic/concurrency/idempotency | EVIDENCED — DS23/28/31/35; real contention/create receipt future gates |
| R09 Unicode/duplicate alternatives | EVIDENCED — DS08–11/34/35; Foundation parity pending |
| R10 bounded listing/order | EVIDENCED — DS29/30; limits/cursor mutation and scale gates explicit |
| R11 ADR024 migration/recovery proposal | EVIDENCED — architecture sequence; DS24/26/27/33 bounded surrogates |
| R12 legacy unknown/no backfill | EVIDENCED — DS25 and every-case old-row digest |
| R13 at least20 enumerated executed tests | EVIDENCED — 38/38 expected/actual with complete reproducible source |
| R14 snapshots/Collections/evidence retained | EVIDENCED — every-case digest/DS32/37; actual ADR038 proof pending |
| R15 negative rollback/integrity | EVIDENCED — DS23/24/35, every-case FK/integrity |
| R16 requirements and future proof matrix | EVIDENCED — TEST_PLAN §11; no runtime migration/hardware PASS |
| R17 four-document scope/advisories | EVIDENCED — exact diff; PRD§2 only; restricted docs untouched |
| R18 complete scoped semantic diff review | EVIDENCED — Worker self-review of all four diffs; no independent acceptance claim |
| R19 whitespace/paths/anchors/history/State | EVIDENCED — diff-check/validate.py; hashes and byte-boundaries above |
| R20 source/media/privacy/no next | EVIDENCED — memory-only code, exact scope, no device/catalog/source roots; return boundary |
| R21 reproducible isolated proof | EVIDENCED — complete source embedded below and recovered into scratch/rerun before freeze |
| R22 Xcode/production XCTest | NOT_APPLICABLE — documentation and ignored experiment only; user explicitly exempts |

Future production/hardware proof is a documented feasibility boundary, not an
unproven claim of implementation. Canonical finalization closure checks run
AFTER this execution postflight: exact handoff/CURRENT/Operator parity,
Worker-only ledger/event, checker prepublication, push/fetch, checker clean/synced
postpublication. Their actual outcomes and publication SHA belong to Desktop's
fresh receipt and tool outputs, not an invented future SHA/checker PASS in this
immutable prepublication record. Completion waits for those physical checks.

WORKER_EXECUTION_GUARD=FSD_WORKER_EXECUTION_V1
WORKER_PREFLIGHT=PASS
WORKER_REQUIREMENTS_TOTAL=22
WORKER_REQUIREMENTS_EVIDENCED=21
WORKER_REQUIREMENTS_NOT_APPLICABLE=1
WORKER_REQUIREMENTS_UNPROVEN=0
WORKER_POSTFLIGHT=PASS
NEXT_TASK_STARTED=NO

## Read-only advisories and Worker proposal

ADR037 remains Proposed / Owner Direction Approved / Technical Proof Pending.
Migration/creation policy, final production schema, Unicode parity,
crash/concurrency/scale/integrated UI and actual hardware identity are pending.
SNAPSHOT_COLLECTIONS §9's v3 wording is the Collection-wave version; cumulative
schema is v9. Its legacy defaults/Auto Capture prose is not physical identity
proof. MVP_PLAN matrix-absence prose predates Task054/055, but complete Wave A
proof is still absent. PRD§6.1/§8.1 and ARCHITECTURE§8 legacy drift stays advisory.
These restricted/out-of-scope sections are untouched. Existing Task041/047
privacy residuals and manual E2E/VoiceOver deferrals remain unresolved.

Proposed state delta only: BRAIN may assess this documentation/synthetic
feasibility evidence as PASS_WITH_ADVISORY while leaving ADR037 and all production
and hardware proof pending. No automatic further action or Task056 is started.
Worker owns RAW/REPORT/proposal; BRAIN alone owns review/classification/accepted
State/active next. One proposal exists in HOT; stop at return to BRAIN.

## Reproducible harness — exact source

Save the following as .ai-scratch/task055/harness.py and run from repository root.
It writes results.json beside itself and opens only :memory: connections.

```python
"""Task055 SYNTHETIC_PROTOTYPE. Generated facts only; never opens a catalog.
Reads repository schema DDL as text; all SQLite connections are :memory:.
Run from repo root: python3 .ai-scratch/task055/harness.py
"""
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import unicodedata

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
SCHEMA = (ROOT / 'docs/database/schema.sql').read_text()
STAMP = '2000-01-01T00:00:00Z'
TARGET = 10  # synthetic sentinel only; no production version reserved
DDL = [
    """CREATE TABLE physical_drives (
      id TEXT NOT NULL PRIMARY KEY CHECK(length(id)=32 AND id NOT GLOB '*[^0-9a-f]*'),
      label TEXT NOT NULL, origin TEXT NOT NULL CHECK(origin='manual_local_unverified'),
      identity_state TEXT NOT NULL CHECK(identity_state IN ('unknown','manual_unverified','conflict')),
      availability TEXT NOT NULL CHECK(availability IN ('offline','online','unknown')),
      tombstoned_at TEXT)""",
    """CREATE TRIGGER physical_drives_no_delete BEFORE DELETE ON physical_drives
       BEGIN SELECT RAISE(ABORT,'PhysicalDrive tombstone required'); END""",
    """CREATE TRIGGER physical_drives_id_immutable BEFORE UPDATE OF id ON physical_drives
       WHEN NEW.id IS NOT OLD.id BEGIN SELECT RAISE(ABORT,'Immutable local ID'); END""",
    """CREATE TABLE drive_sets (
       id TEXT NOT NULL PRIMARY KEY CHECK(length(id)=32 AND id NOT GLOB '*[^0-9a-f]*'),
       name TEXT NOT NULL CHECK(length(trim(name)) BETWEEN 1 AND 256),
       normalized_name TEXT NOT NULL UNIQUE CHECK(length(normalized_name)>0),
       normalization_version TEXT NOT NULL CHECK(normalization_version='synthetic-nfc-casefold-v1'),
       revision INTEGER NOT NULL DEFAULT 1 CHECK(revision>=1),
       created_at TEXT NOT NULL, updated_at TEXT NOT NULL)""",
    """CREATE TRIGGER drive_sets_id_immutable BEFORE UPDATE OF id ON drive_sets
       WHEN NEW.id IS NOT OLD.id BEGIN SELECT RAISE(ABORT,'Immutable local ID'); END""",
    """CREATE TABLE drive_set_memberships (
       set_id TEXT NOT NULL REFERENCES drive_sets(id) ON DELETE CASCADE ON UPDATE RESTRICT,
       physical_drive_id TEXT NOT NULL REFERENCES physical_drives(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
       added_at TEXT NOT NULL, admission TEXT NOT NULL CHECK(admission='explicit_local_selection'),
       PRIMARY KEY(set_id,physical_drive_id))""",
    "CREATE INDEX memberships_by_drive ON drive_set_memberships(physical_drive_id,set_id)",
    """CREATE TRIGGER memberships_active_insert BEFORE INSERT ON drive_set_memberships
       WHEN (SELECT tombstoned_at FROM physical_drives WHERE id=NEW.physical_drive_id) IS NOT NULL
       BEGIN SELECT RAISE(ABORT,'Tombstoned drive'); END""",
    """CREATE TRIGGER memberships_active_update BEFORE UPDATE ON drive_set_memberships
       WHEN (SELECT tombstoned_at FROM physical_drives WHERE id=NEW.physical_drive_id) IS NOT NULL
       BEGIN SELECT RAISE(ABORT,'Tombstoned drive'); END""",
]

def uid(n): return f'{n:032x}'

def connect():
    c = sqlite3.connect(':memory:', isolation_level=None)
    c.execute('PRAGMA foreign_keys=ON')
    assert c.execute('PRAGMA foreign_keys').fetchone() == (1,)
    return c

def rows(c, sql, args=()): return c.execute(sql, args).fetchall()

def tx(c, fn):
    c.execute('BEGIN IMMEDIATE')
    try:
        value = fn()
        c.execute('COMMIT')
        return value
    except BaseException:
        if c.in_transaction: c.execute('ROLLBACK')
        raise

def legacy(c):
    c.executescript(SCHEMA)  # fresh generated memory only; outside transaction
    c.execute("INSERT INTO volumes(id,display_name,persistent_uuid,first_seen_at,last_seen_at,created_at,updated_at) VALUES(1,'SYNTHETIC','cloned',?,?,?,?)", (STAMP,)*4)
    c.execute("INSERT INTO volumes(id,display_name,persistent_uuid,first_seen_at,last_seen_at,created_at,updated_at) VALUES(2,'SYNTHETIC','cloned',?,?,?,?)", (STAMP,)*4)
    c.execute("INSERT INTO collections(id,name,normalized_name,created_at,updated_at) VALUES(1,'Synthetic','synthetic',?,?)", (STAMP,)*2)
    for i, collection in [(1,1),(2,None)]:
        c.execute("""INSERT INTO snapshots(id,volume_id,session_number,scan_root_name,status,scanner_version,schema_version,normalization_version,snapshot_kind,source_case_sensitivity,display_name,capture_policy_json,started_at,created_at,updated_at,collection_id)
          VALUES(?,?,?,'SYNTHETIC','scanning','synthetic',9,'fsd-normalizer-v1_app-1.0_os-1','user','unknown','Synthetic','{}',?,?,?,?)""", (i,i,1,STAMP,STAMP,STAMP,collection))
        c.execute("""INSERT INTO entries(id,snapshot_id,parent_id,relative_path,case_preserving_path,case_folded_path,name,case_preserving_name,case_folded_name,item_type,sort_key,created_at)
           VALUES(?,?,NULL,'','','','SYNTHETIC','SYNTHETIC','synthetic','directory','0',?)""", (i,i,STAMP))
        c.execute("UPDATE snapshots SET status='complete' WHERE id=?", (i,))
    c.execute("INSERT INTO comparisons(id,left_snapshot_id,right_snapshot_id,profile_id,status,started_at,created_at) VALUES(1,1,2,1,'running',?,?)", (STAMP,)*2)
    c.execute("INSERT INTO comparison_results(id,comparison_id,result_path,display_name,result_type,left_entry_id,right_entry_id,created_at) VALUES(1,1,'','SYNTHETIC','matched',1,2,?)", (STAMP,))
    c.execute("UPDATE comparisons SET status='complete',matched_count=1 WHERE id=1")
    # ADR038 saved artifact shape is unresolved: sentinel only, not its proposed schema.
    c.execute('CREATE TABLE synthetic_saved_evidence(id INTEGER PRIMARY KEY, comparison_id INTEGER REFERENCES comparisons(id) ON DELETE RESTRICT, payload TEXT NOT NULL)')
    c.execute("INSERT INTO synthetic_saved_evidence VALUES(1,1,'generated sentinel')")

def migration(c, fail=False):
    v = rows(c,'SELECT MAX(version) FROM schema_migrations')[0][0]
    if v not in (9,TARGET): raise ValueError('unsupported version')
    if v == TARGET:
        verify(c)
        return
    def body():
        for i, sql in enumerate(DDL):
            c.execute(sql)  # not executescript: no implicit commit before script
            if fail and i==3: raise RuntimeError('injected partial DDL failure')
        c.execute('INSERT INTO schema_migrations VALUES(?,?)',(TARGET,STAMP))
        verify(c)
    tx(c,body)

def verify(c):
    for sql in DDL:
        kind = 'trigger' if 'CREATE TRIGGER' in sql else 'index' if 'CREATE INDEX' in sql else 'table'
        name = sql.split()[2]
        actual = rows(c,'SELECT sql FROM sqlite_master WHERE type=? AND name=?',(kind,name))
        assert len(actual)==1 and ' '.join(actual[0][0].split())==' '.join(sql.split()), name
    assert not rows(c,'PRAGMA foreign_key_check')
    assert rows(c,'PRAGMA integrity_check')==[('ok',)]

def digest(c, tables):
    data={t: rows(c,'SELECT * FROM "'+t+'" ORDER BY rowid') for t in tables}
    return hashlib.sha256(json.dumps(data,sort_keys=True).encode()).hexdigest()

def base():
    c=connect(); legacy(c)
    tables=[r[0] for r in rows(c,"SELECT name FROM sqlite_master WHERE type='table' AND name!='schema_migrations' ORDER BY name")]
    before=digest(c,tables)
    objects=rows(c,"SELECT type,name,sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY type,name")
    migration(c)
    assert digest(c,tables)==before
    for obj in objects: assert obj in rows(c,"SELECT type,name,sql FROM sqlite_master ORDER BY type,name")
    return c,tables,before

def norm(name):
    text=name.strip()
    if not text or len(text)>256: raise ValueError('invalid name')
    return text,unicodedata.normalize('NFC',text).casefold()

def create(c,n,name):
    text,key=norm(name)
    tx(c,lambda:c.execute('INSERT INTO drive_sets(id,name,normalized_name,normalization_version,created_at,updated_at) VALUES(?,?,?,\'synthetic-nfc-casefold-v1\',?,?)',(uid(n),text,key,STAMP,STAMP)))

def drive(c,n):
    c.execute("INSERT INTO physical_drives VALUES(?,?,'manual_local_unverified','manual_unverified','offline',NULL)",(uid(n),'SYNTHETIC'))

def add(c,s,d,explicit=True,observed='ManualAssociation'):
    if not explicit or observed not in ('ManualAssociation','LocalRecordSelection'):
        raise ValueError('observation never admits membership')
    def body():
        if rows(c,'SELECT tombstoned_at FROM physical_drives WHERE id=?',(uid(d),)) != [(None,)]:
            raise ValueError('missing or tombstoned')
        # Targeted conflict handler, never REPLACE or broad OR IGNORE.
        changed=c.execute("INSERT INTO drive_set_memberships VALUES(?,?,?,'explicit_local_selection') ON CONFLICT(set_id,physical_drive_id) DO NOTHING",(uid(s),uid(d),STAMP)).rowcount
        if changed:c.execute('UPDATE drive_sets SET revision=revision+1 WHERE id=?',(uid(s),))
        return changed
    return tx(c,body)

def rename(c,s,name,revision):
    text,key=norm(name)
    def body():
        changed=c.execute('UPDATE drive_sets SET name=?,normalized_name=?,revision=revision+1,updated_at=? WHERE id=? AND revision=?',(text,key,STAMP,uid(s),revision)).rowcount
        if changed!=1:raise ValueError('stale or missing')
    tx(c,body)

def reject(fn, error, contains=''):
    try:fn()
    except error as e:
        assert contains in str(e),str(e)
        return
    raise AssertionError('expected rejection did not occur')

RESULTS=[]
def case(number,expected,fn):
    c,tables,before=base()
    try:
        actual=fn(c)
        if isinstance(actual,str): assert actual==expected,(actual,expected)
        verify(c)
        assert digest(c,tables)==before,'legacy facts changed'
        RESULTS.append({'id':f'DS{number:02}','label':'SYNTHETIC_PROTOTYPE','expected':expected,'actual':actual,'result':'PASS','legacy_digest_unchanged':True,'fk_check':[],'integrity_check':'ok'})
    except Exception as e:
        RESULTS.append({'id':f'DS{number:02}','expected':expected,'result':'FAIL','error':repr(e)})
    finally:c.close()

def prepared(c):
    create(c,1,'Alpha');create(c,2,'Beta');drive(c,1);drive(c,2)

def simple(c,sql,args=()): return rows(c,sql,args)

def empty(c):
    create(c,1,'Empty');assert rows(c,'SELECT COUNT(*) FROM drive_set_memberships')==[(0,)];return 'empty set created'
case(1,'empty set created',empty)
def multiple(c):
    prepared(c);assert len(rows(c,'SELECT id FROM drive_sets'))==2;return 'two stable set IDs'
case(2,'two stable set IDs',multiple)
def many(c):
    prepared(c)
    for s,d in [(1,1),(1,2),(2,1)]:add(c,s,d)
    assert rows(c,'SELECT set_id,physical_drive_id FROM drive_set_memberships ORDER BY 1,2')==[(uid(1),uid(1)),(uid(1),uid(2)),(uid(2),uid(1))]
    return 'many-to-many exact three pairs'
case(3,'many-to-many exact three pairs',many)
def duplicate(c):
    prepared(c);add(c,1,1)
    reject(lambda:c.execute("INSERT INTO drive_set_memberships VALUES(?,?,?,'explicit_local_selection')",(uid(1),uid(1),STAMP)),sqlite3.IntegrityError,'UNIQUE')
    return 'duplicate PK rejected'
case(4,'duplicate PK rejected',duplicate)
for number,which in [(5,'set'),(6,'drive')]:
    def missing(c,which=which):
        prepared(c)
        reject(lambda:c.execute("INSERT INTO drive_set_memberships VALUES(?,?,?,'explicit_local_selection')",(uid(99 if which=='set' else 1),uid(99 if which=='drive' else 1),STAMP)),sqlite3.IntegrityError,'FOREIGN KEY')
        return 'missing '+which+' FK rejected'
    case(number,'missing '+which+' FK rejected',missing)
def renamed(c):
    prepared(c);add(c,1,1);rename(c,1,'Renamed',2)
    assert rows(c,'SELECT id,name,revision FROM drive_sets WHERE id=?',(uid(1),))==[(uid(1),'Renamed',3)]
    assert rows(c,'SELECT set_id FROM drive_set_memberships')==[(uid(1),)]
    return 'rename preserves IDs and membership'
case(7,'rename preserves IDs and membership',renamed)
for number,name in [(8,'ALPHA'),(9,'Cafe\u0301'),(10,'STRASSE')]:
    def names(c,number=number,name=name):
        create(c,1,{8:'Alpha',9:'Café',10:'Straße'}[number])
        reject(lambda:create(c,2,name),sqlite3.IntegrityError,'UNIQUE')
        return 'normalized duplicate rejected'
    case(number,'normalized duplicate rejected',names)
def alternatives(c):
    c.execute('CREATE TABLE alternative_names(id INTEGER PRIMARY KEY,name TEXT COLLATE NOCASE)')
    c.executemany('INSERT INTO alternative_names VALUES(?,?)',[(1,'é'),(2,'É'),(3,'same'),(4,'same')])
    assert rows(c,"SELECT 'é'='É' COLLATE NOCASE")==[(0,)]
    assert len(rows(c,'SELECT * FROM alternative_names'))==4
    return 'allow-duplicate alternative permits four; NOCASE misses non-ASCII'
case(11,'allow-duplicate alternative permits four; NOCASE misses non-ASCII',alternatives)
def remove(c):
    prepared(c);add(c,1,1);assert c.execute('DELETE FROM drive_set_memberships WHERE set_id=? AND physical_drive_id=?',(uid(1),uid(1))).rowcount==1
    assert len(rows(c,'SELECT * FROM physical_drives'))==2
    return 'membership removed only'
case(12,'membership removed only',remove)
def offline(c):
    prepared(c);add(c,1,1);c.execute("UPDATE physical_drives SET availability='online' WHERE id=?",(uid(1),));c.execute("UPDATE physical_drives SET availability='offline' WHERE id=?",(uid(1),))
    assert len(rows(c,'SELECT * FROM drive_set_memberships'))==1
    return 'offline membership retained'
case(13,'offline membership retained',offline)
for number,state in [(14,'Unknown'),(15,'Ambiguous'),(16,'Conflict'),(17,'UniqueStrongMatch')]:
    def unresolved(c,state=state):
        prepared(c);reject(lambda:add(c,1,1,False,state),ValueError)
        assert rows(c,'SELECT COUNT(*) FROM drive_set_memberships')==[(0,)]
        return state+' observation admits nothing'
    case(number,state+' observation admits nothing',unresolved)
def manual(c):
    prepared(c);add(c,1,1)
    assert rows(c,'SELECT origin,identity_state FROM physical_drives WHERE id=?',(uid(1),))==[('manual_local_unverified','manual_unverified')]
    return 'manual local membership remains unverified'
case(18,'manual local membership remains unverified',manual)
def revoke(c):
    prepared(c);add(c,1,1);c.execute("UPDATE physical_drives SET identity_state='conflict' WHERE id=?",(uid(1),))
    assert rows(c,'SELECT physical_drive_id FROM drive_set_memberships')==[(uid(1),)]
    assert rows(c,'SELECT identity_state FROM physical_drives WHERE id=?',(uid(1),))==[('conflict',)]
    return 'contradiction flags local record; no retarget'
case(19,'contradiction flags local record; no retarget',revoke)
def delete_set(c):
    many(c);c.execute('DELETE FROM drive_sets WHERE id=?',(uid(1),))
    assert rows(c,'SELECT set_id,physical_drive_id FROM drive_set_memberships')==[(uid(2),uid(1))]
    assert len(rows(c,'SELECT * FROM physical_drives'))==2
    return 'only deleted set and its two pairs removed'
case(20,'only deleted set and its two pairs removed',delete_set)
def delete_drive(c):
    prepared(c);add(c,1,1)
    reject(lambda:c.execute('DELETE FROM physical_drives WHERE id=?',(uid(1),)),sqlite3.IntegrityError,'tombstone')
    return 'drive hard delete prohibited'
case(21,'drive hard delete prohibited',delete_drive)
def tombstone(c):
    prepared(c);add(c,1,1);c.execute('UPDATE physical_drives SET tombstoned_at=? WHERE id=?',(STAMP,uid(1)))
    reject(lambda:add(c,2,1),ValueError)
    assert len(rows(c,'SELECT * FROM drive_set_memberships'))==1
    reject(lambda:c.execute("INSERT INTO drive_set_memberships VALUES(?,?,?,'explicit_local_selection')",(uid(2),uid(1),STAMP)),sqlite3.IntegrityError,'Tombstoned')
    return 'tombstone retains pair; new admissions rejected'
case(22,'tombstone retains pair; new admissions rejected',tombstone)
def rollback(c):
    prepared(c)
    def body():
        c.execute("UPDATE drive_sets SET name='Temporary' WHERE id=?",(uid(1),))
        c.execute("INSERT INTO drive_set_memberships VALUES(?,?,?,'explicit_local_selection')",(uid(1),uid(99),STAMP))
    reject(lambda:tx(c,body),sqlite3.IntegrityError,'FOREIGN KEY')
    assert rows(c,'SELECT name FROM drive_sets WHERE id=?',(uid(1),))==[('Alpha',)]
    return 'whole failed mutation rolled back'
case(23,'whole failed mutation rolled back',rollback)
def failed_migration(c):
    other=connect();legacy(other)
    before=rows(other,'SELECT type,name,sql FROM sqlite_master ORDER BY type,name')
    reject(lambda:migration(other,True),RuntimeError,'injected')
    assert rows(other,'SELECT MAX(version) FROM schema_migrations')==[(9,)]
    assert rows(other,'SELECT type,name,sql FROM sqlite_master ORDER BY type,name')==before
    migration(other);verify(other);other.close()
    return 'partial DDL and version roll back; retry succeeds'
case(24,'partial DDL and version roll back; retry succeeds',failed_migration)
def legacy_unknown(c):
    assert rows(c,'SELECT COUNT(*) FROM physical_drives')==[(0,)]
    assert rows(c,'SELECT volume_identifier_at_capture,device_identifier FROM snapshots ORDER BY id')==[(None,None),(None,None)]
    assert rows(c,'SELECT collection_id FROM snapshots ORDER BY id')==[(1,),(None,)]
    return 'legacy cloned UUIDs create zero drives; unknown and Unsorted preserved'
case(25,'legacy cloned UUIDs create zero drives; unknown and Unsorted preserved',legacy_unknown)
def reopen(c):
    prepared(c);add(c,1,1)
    other=connect();c.backup(other);before=list(other.iterdump());migration(other);migration(other)
    assert list(other.iterdump())==before;verify(other);other.close()
    return 'committed memory-copy reopen and repeated migration unchanged'
case(26,'committed memory-copy reopen and repeated migration unchanged',reopen)
def newer(c):
    other=connect();legacy(other);other.execute('INSERT INTO schema_migrations VALUES(999,?)',(STAMP,))
    before=list(other.iterdump());reject(lambda:migration(other),ValueError)
    assert list(other.iterdump())==before;other.close()
    return 'newer version rejected unchanged'
case(27,'newer version rejected unchanged',newer)
def stale(c):
    prepared(c);rename(c,1,'New',1);reject(lambda:rename(c,1,'Stale',1),ValueError)
    assert rows(c,'SELECT name FROM drive_sets WHERE id=?',(uid(1),))==[('New',)]
    return 'stale revision rejected'
case(28,'stale revision rejected',stale)
def pages(c):
    for n in range(1,258):create(c,n,'Name '+str(n%5)+' '+str(n))
    cursor=('', '');seen=[];plans=[]
    while True:
        sql='SELECT normalized_name,id FROM drive_sets WHERE (normalized_name,id)>(?,?) ORDER BY normalized_name,id LIMIT ?'
        page=rows(c,sql,(*cursor,18));plans=rows(c,'EXPLAIN QUERY PLAN '+sql,(*cursor,18))
        assert len(page)<=18
        if not page:break
        seen.extend(page[:17]);cursor=page[:17][-1]
    assert seen==rows(c,'SELECT normalized_name,id FROM drive_sets ORDER BY normalized_name,id')
    assert len(seen)==len(set(seen))==257
    detail=' | '.join(str(x[3]) for x in plans)
    assert 'SEARCH' in detail and 'INDEX' in detail and 'TEMP B-TREE' not in detail,detail
    return {'pages':'257 rows without duplicate/skip; 17+1 bound','plan':detail}
case(29,'257 rows without duplicate/skip; indexed seek; 17+1 bound',pages)
def membership_plan(c):
    prepared(c);add(c,1,1);add(c,1,2);add(c,2,1)
    for sql,args in [('SELECT physical_drive_id FROM drive_set_memberships WHERE set_id=? AND physical_drive_id>? ORDER BY physical_drive_id LIMIT 3',(uid(1),'')),('SELECT set_id FROM drive_set_memberships WHERE physical_drive_id=? AND set_id>? ORDER BY set_id LIMIT 3',(uid(1),''))]:
        detail=' | '.join(r[3] for r in rows(c,'EXPLAIN QUERY PLAN '+sql,args))
        assert 'SEARCH' in detail and 'COVERING INDEX' in detail and 'TEMP B-TREE' not in detail,detail
    return 'both membership directions use covering indexed seek'
case(30,'both membership directions use covering indexed seek',membership_plan)
def idempotent(c):
    prepared(c);assert add(c,1,1)==1;assert add(c,1,1)==0
    assert rows(c,'SELECT revision FROM drive_sets WHERE id=?',(uid(1),))==[(2,)]
    for _ in range(2):c.execute('DELETE FROM drive_set_memberships WHERE set_id=? AND physical_drive_id=?',(uid(1),uid(1)))
    for _ in range(2):c.execute('DELETE FROM drive_sets WHERE id=?',(uid(1),))
    return 'repeat add/remove/delete is exact no-op after first'
case(31,'repeat add/remove/delete is exact no-op after first',idempotent)
def immutable(c):
    reject(lambda:c.execute("UPDATE snapshots SET mount_path_at_capture='/synthetic' WHERE id=1"),sqlite3.IntegrityError)
    reject(lambda:c.execute("UPDATE entries SET name='changed' WHERE id=1"),sqlite3.IntegrityError)
    reject(lambda:c.execute("DELETE FROM comparison_results WHERE id=1"),sqlite3.IntegrityError)
    return 'existing capture/entry/terminal evidence guards reject mutation'
case(32,'existing capture/entry/terminal evidence guards reject mutation',immutable)
def drift(c):
    c.execute('DROP INDEX memberships_by_drive');reject(lambda:migration(c),AssertionError)
    c.execute(next(sql for sql in DDL if sql.startswith('CREATE INDEX memberships_by_drive')))
    return 'same-version missing index fails; exact index restored in isolated test'
case(33,'same-version missing index fails; exact index restored in isolated test',drift)
def blanks(c):
    for name in ['', ' \t\n', 'x'*257]:reject(lambda:create(c,1,name),ValueError)
    return 'blank and overlong names rejected'
case(34,'blank and overlong names rejected',blanks)
def rename_collision(c):
    prepared(c);reject(lambda:rename(c,1,'BETA',1),sqlite3.IntegrityError,'UNIQUE')
    assert rows(c,'SELECT name,revision FROM drive_sets WHERE id=?',(uid(1),))==[('Alpha',1)]
    return 'rename collision rolls back label and revision'
case(35,'rename collision rolls back label and revision',rename_collision)
def nulls(c):
    prepared(c)
    reject(lambda:c.execute("INSERT INTO drive_set_memberships VALUES(NULL,?,?,'explicit_local_selection')",(uid(1),STAMP)),sqlite3.IntegrityError,'NOT NULL')
    reject(lambda:c.execute('UPDATE physical_drives SET id=? WHERE id=?',(uid(99),uid(1))),sqlite3.IntegrityError,'Immutable')
    reject(lambda:c.execute('UPDATE drive_sets SET id=? WHERE id=?',(uid(99),uid(1))),sqlite3.IntegrityError,'Immutable')
    return 'NULL membership and stable ID rewrite rejected'
case(36,'NULL membership and stable ID rewrite rejected',nulls)
def cascade_graph(c):
    names=[r[0] for r in rows(c,"SELECT name FROM sqlite_master WHERE type='table'")]
    edges=[]
    for child in names:
        for fk in rows(c,'PRAGMA foreign_key_list("'+child+'")'):
            if fk[6]=='CASCADE':edges.append((fk[2],child))
    reachable={'drive_sets'}
    while True:
        nxt=reachable|{b for a,b in edges if a in reachable}
        if nxt==reachable:break
        reachable=nxt
    assert reachable=={'drive_sets','drive_set_memberships'},reachable
    return 'set deletion cascade reaches memberships only'
case(37,'set deletion cascade reaches memberships only',cascade_graph)
def no_inference(c):
    prepared(c)
    generated={'label':'Alpha','mount_path':'/synthetic/reused','bsd':'disk99','uuid':'cloned','collection_id':1}
    reject(lambda:add(c,1,1,False,'Unknown'),ValueError)
    assert generated['collection_id']==1 and rows(c,'SELECT COUNT(*) FROM drive_set_memberships')==[(0,)]
    return 'matching labels/path/BSD/UUID/Collection imply no membership'
case(38,'matching labels/path/BSD/UUID/Collection imply no membership',no_inference)

receipt={'label':'SYNTHETIC_PROTOTYPE','python':sys.version.split()[0],'sqlite':sqlite3.sqlite_version,'unicode':unicodedata.unidata_version,'connections':':memory: only','schema_sha256':hashlib.sha256(SCHEMA.encode()).hexdigest(),'executed':len(RESULTS),'passed':sum(x['result']=='PASS' for x in RESULTS),'failed':sum(x['result']=='FAIL' for x in RESULTS),'cases':RESULTS,'limits':['No production migration or Swift/XCTest execution','Memory-copy reopen is not process-crash, disk durability or power-loss proof','PhysicalDrive is a minimal manually created unverified stub, not ADR036 identity implementation','Saved evidence is a sentinel, not ADR038 schema or runtime proof','No hardware/source/catalog access; no concurrency contention measurement']}
OUT.joinpath('results.json').write_text(json.dumps(receipt,indent=2,ensure_ascii=False)+'\n')
for result in RESULTS:print(result['id'],result['result'],result.get('actual',result.get('error')))
print(json.dumps({k:v for k,v in receipt.items() if k!='cases'},indent=2))
raise SystemExit(1 if receipt['failed'] else 0)
```
