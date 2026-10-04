#!/usr/bin/env python3
"""Read-only FSD Worker closure checks. PASS proves mechanics, never acceptance."""

import argparse
import csv
import hashlib
import io
import json
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


TASK_HEADER = "TASK_ID STATUS SCOPE EXECUTOR TECHNICAL_SHA WORKER_RESULT BRAIN_CLASSIFICATION HANDOFF NOTE".split()
RULE_HEADER = "DATE TASK_ID CANDIDATE CLASSIFICATION ACTION STATUS NOTE".split()
STATE_KEYS = "STATE_VERSION PROJECT CURRENT_PHASE ACTIVE_WORKSTREAM STATUS CURRENT_GATE BLOCKERS LAST_ACCEPTED_TASK LAST_ACCEPTED_HEAD AUTHORITY_PTRS PARKED_PRODUCT_WORKSTREAM EXACTLY_ONE_NEXT_DECISION".split()
EVENT_KEYS = {"ts", "actor", "event_type", "task_id", "result", "commit", "ref", "note"}
SHA = re.compile(r"[0-9a-f]{40}")
HANDOFF = re.compile(r"handoffs/FSD_[A-Z0-9_-]+_[FARCTDL]_[0-9]{8}-[0-9]{6}\.md")
TASK = re.compile(r"[A-Z0-9_]+")
RESULTS = {"PASS", "PASS_WITH_ADVISORY", "REPAIR", "STOP"}
CLASSIFICATIONS = RESULTS | {"OWNER_DECISION", "PENDING_BRAIN"}
GUARD_KEYS = (
    "WORKER_EXECUTION_GUARD", "WORKER_PREFLIGHT", "WORKER_REQUIREMENTS_TOTAL",
    "WORKER_REQUIREMENTS_EVIDENCED", "WORKER_REQUIREMENTS_NOT_APPLICABLE",
    "WORKER_REQUIREMENTS_UNPROVEN", "WORKER_POSTFLIGHT", "NEXT_TASK_STARTED",
)
BEGIN = b"# BRAIN OPERATOR BEGIN\n"
END = b"# BRAIN OPERATOR END\n"
BOOTSTRAP_TASK = "FSD_STATE_PLANE_AND_FINALIZER_003"
# Only these two accepted facts are supplied by the one-time migration directive.
# This is provenance validation for initialization, not reusable Worker authority.
BOOTSTRAP_ACCEPTED = {
    "FSD_BRAIN_OPERATOR_DISCOVERY_AND_BASELINE_001": "481d0b17ff748c983d37e0ca4de0f62fd75d59e5",
    "FSD_BRAIN_OPERATOR_CORE_LAYER_002": "49cc62de55304b1152b876a467a18bfa0080050c",
}
REQUIRED = [
    "AGENTS.md", "docs/BRAIN_OPERATOR.md", "docs/AGENT.md",
    "STATE/PROJECT_STATE.md", "STATE/EVENTS.jsonl", "STATE/TASK_LEDGER.tsv",
    "STATE/RULE_PROMOTION_LEDGER.tsv", "handoffs/CURRENT_HANDOFF.md",
    ".agents/skills/fsd-task-execution/SKILL.md",
    ".agents/skills/fsd-independent-review/SKILL.md",
    ".agents/skills/fsd-handoff-finalizer/SKILL.md",
    "scripts/check_control_plane.py",
]


class CheckError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise CheckError(message)


def concrete(value, label):
    require(bool(value.strip()) and value.strip().upper() not in
            {"TODO", "TBD", "UNSET", "PENDING", "UNKNOWN", "PLACEHOLDER"}
            and not re.search(r"<[^>]+>", value), f"placeholder: {label}")


def timestamp(value):
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise CheckError(f"invalid timestamp: {value}") from exc
    require(parsed.utcoffset() is not None, "timestamp needs timezone")
    return parsed


def fields(text):
    result = {}
    for line in text.splitlines():
        match = re.fullmatch(r"([A-Z][A-Z0-9_]*)=(.*)", line)
        if match:
            key, value = match.groups()
            require(key not in result, f"duplicate field: {key}")
            result[key] = value
    return result


def table(text, header, label):
    rows = list(csv.reader(io.StringIO(text), delimiter="\t", strict=True))
    require(bool(rows) and rows[0] == header, f"invalid {label} header")
    require(len(rows) == len(text.splitlines()) and all(
        not any(char in cell for char in "\r\n\t") for row in rows for cell in row),
        f"{label} requires one physical line per row")
    require(all(len(row) == len(header) for row in rows[1:]), f"invalid {label} row width")
    require(all(all(cell.strip() for cell in row) for row in rows[1:]), f"empty {label} cell")
    return [dict(zip(header, row)) for row in rows[1:]]


class Checker:
    def __init__(self, args):
        self.args = args
        self.root = args.repo.resolve()
        self.receipt = {"proof": "MECHANICS_ONLY;NO_BRAIN_OR_PRODUCT_ACCEPTANCE", "checks": []}

    def git(self, *args, optional=False):
        run = subprocess.run(["git", "-C", str(self.root), *args], capture_output=True)
        if run.returncode:
            if optional:
                return None
            raise CheckError(f"git command failed: {' '.join(args)}: {run.stderr.decode().strip()}")
        return run.stdout

    def ref(self, value):
        path = Path(value)
        require(not path.is_absolute() and ".." not in path.parts, f"unsafe ref: {value}")
        target = self.root / path
        require(target.resolve().is_relative_to(self.root), f"ref escapes repo: {value}")
        require(target.is_file() and not target.is_symlink(), f"missing/nonregular ref: {value}")
        return target

    def text(self, path):
        return self.ref(path).read_text(encoding="utf-8")

    def base_bytes(self, path):
        return self.git("show", f"{self.args.base}:{path}", optional=True)

    def git_identity(self):
        root = self.git("rev-parse", "--show-toplevel").decode().strip()
        require(Path(root).resolve() == self.root, "--repo is not the physical Git root")
        require(bool(SHA.fullmatch(self.args.base)), "--base requires a full SHA")
        self.git("merge-base", "--is-ancestor", self.args.base, "HEAD")
        branch = self.git("branch", "--show-current").decode().strip()
        origin = self.git("remote", "get-url", "origin").decode().strip()
        require(branch == self.args.expect_branch, "unexpected branch")
        require(origin == self.args.expect_origin, "unexpected canonical origin")
        upstream = self.git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}").decode().strip()
        require(upstream == f"origin/{branch}", "unexpected upstream")
        head = self.git("rev-parse", "HEAD").decode().strip()
        remote = self.git("rev-parse", "@{upstream}").decode().strip()
        ahead, behind = map(int, self.git("rev-list", "--left-right", "--count", "HEAD...@{upstream}").split())
        status = self.git("status", "--porcelain=v1").decode()
        fetch_path = Path(self.git("rev-parse", "--git-path", "FETCH_HEAD").decode().strip())
        if not fetch_path.is_absolute():
            fetch_path = self.root / fetch_path
        require(fetch_path.is_file(), "no FETCH_HEAD receipt; finalizer must fetch")
        age = time.time() - fetch_path.stat().st_mtime
        require(0 <= age <= self.args.max_fetch_age_seconds, "stale/future FETCH_HEAD receipt")
        require(any(line.split("\t")[0] == remote for line in fetch_path.read_text().splitlines()),
                "FETCH_HEAD does not contain configured upstream SHA")
        self.receipt["git"] = dict(root=root, branch=branch, origin=origin, head=head,
                                   upstream=upstream, upstream_head=remote, ahead=ahead,
                                   behind=behind, clean=not status, status=status,
                                   fetch_age_seconds=round(age, 3),
                                   freshness="LOCAL_FETCH_RECEIPT_ONLY;FINALIZER_FETCH_REQUIRED")
        require(not self.args.require_clean or not status, "primary worktree not clean")
        require(not self.args.require_synced or (ahead, behind) == (0, 0), "local/upstream not 0/0")
        self.receipt["checks"].append("git_identity_freshness")

    def scope_and_history(self):
        allowed = set(self.args.allow_path)
        require(bool(allowed), "task must supply exact --allow-path entries")
        for path in allowed:
            require(not Path(path).is_absolute() and ".." not in Path(path).parts
                    and not any(char in path for char in "*?[]"), "allow-path must be exact repo-relative path")
        changed = set(filter(None, self.git("diff", "--no-renames", "--name-only", "-z", self.args.base, "--").decode().split("\0")))
        untracked = set(filter(None, self.git("ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")))
        changed |= untracked
        require(changed <= allowed, f"outside allowed paths: {sorted(changed - allowed)}")
        baseline = set(filter(None, self.git("ls-tree", "-r", "--name-only", "-z", self.args.base, "--", "handoffs").decode().split("\0")))
        old_history = {path for path in baseline if HANDOFF.fullmatch(path)}
        for path in old_history:
            require(self.ref(path).read_bytes() == self.base_bytes(path), f"historical bytes changed: {path}")
        actual = set()
        for path in (self.root / "handoffs").rglob("*"):
            value = path.relative_to(self.root).as_posix()
            require(path.is_file() and not path.is_symlink(), f"nonflat handoff path: {value}")
            require(value == "handoffs/CURRENT_HANDOFF.md" or HANDOFF.fullmatch(value), f"invalid historical name: {value}")
            if HANDOFF.fullmatch(value):
                actual.add(value)
        require(len(actual - old_history) == 1, "closure requires exactly one new historical handoff")
        require(not (self.root / "AI_HANDOFFS").exists() and not (self.root / "CURRENT.md").exists(),
                "legacy AI_HANDOFFS/CURRENT.md convention present")
        self.new_handoff = (actual - old_history).pop()
        self.receipt.update(changed_paths=sorted(changed), historical_preserved=len(old_history), new_handoff=self.new_handoff)
        self.receipt["checks"].append("exact_scope_flat_history_immutable")

    def state_and_ledgers(self):
        for path in REQUIRED:
            self.ref(path)
        state = fields(self.text("STATE/PROJECT_STATE.md"))
        require(set(state) == set(STATE_KEYS), "invalid PROJECT_STATE fields")
        for key in STATE_KEYS:
            concrete(state[key], f"PROJECT_STATE.{key}")
        require(state["PROJECT"] == "FSD", "unexpected STATE project")
        require(re.fullmatch(r"\d+\.\d+\.\d+", state["STATE_VERSION"]), "invalid STATE_VERSION")
        require(SHA.fullmatch(state["LAST_ACCEPTED_HEAD"]), "invalid LAST_ACCEPTED_HEAD")
        self.git("cat-file", "-e", state["LAST_ACCEPTED_HEAD"] + "^{commit}")
        decision = state["EXACTLY_ONE_NEXT_DECISION"]
        require(re.fullmatch(r"(?:ACTION|WAIT)\([A-Za-z0-9_./:-]+\)|DONE|NO_WORK_NEEDED|OWNER_DECISION|STOP", decision),
                "PROJECT_STATE must contain exactly one concrete next decision")
        for value in state["AUTHORITY_PTRS"].split("|"):
            self.ref(value)
        rows = table(self.text("STATE/TASK_LEDGER.tsv"), TASK_HEADER, "TASK_LEDGER")
        ledger = {row["TASK_ID"]: row for row in rows}
        require(len(rows) == len(ledger), "duplicate TASK_ID")
        require(self.args.task_id in ledger and TASK.fullmatch(self.args.task_id), "current TASK_ID missing/invalid")
        for row in rows:
            require(TASK.fullmatch(row["TASK_ID"]), "invalid ledger TASK_ID")
            require(row["BRAIN_CLASSIFICATION"] in CLASSIFICATIONS, "invalid BRAIN_CLASSIFICATION")
            require(row["WORKER_RESULT"] in RESULTS, "closure requires concrete WORKER_RESULT")
            require(SHA.fullmatch(row["TECHNICAL_SHA"]), "closure requires concrete TECHNICAL_SHA")
            self.git("cat-file", "-e", row["TECHNICAL_SHA"] + "^{commit}")
            require(HANDOFF.fullmatch(row["HANDOFF"]), "closure requires concrete flat HANDOFF")
            self.ref(row["HANDOFF"])
            for key in TASK_HEADER:
                concrete(row[key], f"TASK_LEDGER.{key}")
        current = ledger[self.args.task_id]
        require(current["BRAIN_CLASSIFICATION"] == "PENDING_BRAIN", "Worker cannot author accepted current-task BRAIN classification")
        require(current["STATUS"] != "ACCEPTED", "Worker cannot mark current task accepted")
        require(current["HANDOFF"] == self.new_handoff, "current task must own the one new handoff")
        require(state["LAST_ACCEPTED_TASK"] in ledger, "accepted task missing from ledger")
        accepted = ledger[state["LAST_ACCEPTED_TASK"]]
        require(accepted["BRAIN_CLASSIFICATION"] in {"PASS", "PASS_WITH_ADVISORY"}
                or (accepted["EXECUTOR"] == "REVIEWER" and accepted["STATUS"] == "ACCEPTED"
                    and accepted["BRAIN_CLASSIFICATION"] == "REPAIR"),
                "last accepted task lacks accepted classification")
        # A self-containing return records a known basis SHA, while BRAIN may
        # later accept its publication snapshot. Prove ancestry and artifact
        # presence instead of requiring those distinct SHA roles to be equal.
        self.git("merge-base", "--is-ancestor", accepted["TECHNICAL_SHA"], state["LAST_ACCEPTED_HEAD"])
        accepted_source = self.git("show", f"{state['LAST_ACCEPTED_HEAD']}:{accepted['HANDOFF']}", optional=True)
        require(accepted_source == self.ref(accepted["HANDOFF"]).read_bytes(), "accepted snapshot lacks exact accepted handoff")
        prior = self.base_bytes("STATE/TASK_LEDGER.tsv")
        old_state = self.base_bytes("STATE/PROJECT_STATE.md")
        self.bootstrap = prior is None and old_state is None
        if self.bootstrap:
            require(self.args.task_id == BOOTSTRAP_TASK, "STATE bootstrap only authorized by Stage-C directive")
            require(set(ledger) == set(BOOTSTRAP_ACCEPTED) | {BOOTSTRAP_TASK}, "bootstrap task inventory differs from directive")
            for task, sha in BOOTSTRAP_ACCEPTED.items():
                require(ledger[task]["BRAIN_CLASSIFICATION"] == "PASS_WITH_ADVISORY"
                        and ledger[task]["TECHNICAL_SHA"] == sha, "bootstrap acceptance differs from supplied BRAIN facts")
            require(state["LAST_ACCEPTED_TASK"] == "FSD_BRAIN_OPERATOR_CORE_LAYER_002"
                    and state["EXACTLY_ONE_NEXT_DECISION"] == f"ACTION({BOOTSTRAP_TASK})", "Worker altered bootstrap accepted decision")
            seed = dict(STATE_VERSION="1.0.0", PROJECT="FSD",
                        CURRENT_PHASE="STATE_PLANE_IMPLEMENTATION", ACTIVE_WORKSTREAM="FSD_CONTROL_PLANE",
                        STATUS="PRODUCT_WORK_PAUSED;STAGE_C_AUTHORIZED",
                        CURRENT_GATE="STAGE_C_WORKER_RETURN_AND_BRAIN_ADJUDICATION",
                        BLOCKERS="NONE_FOR_AUTHORIZED_CONTROL_PLANE_SCOPE",
                        PARKED_PRODUCT_WORKSTREAM="PHASE_1_5_MAGIKA_RUNTIME")
            require(all(state[key] == value for key, value in seed.items()), "Worker altered supplied bootstrap accepted state")
        else:
            require(prior is not None and old_state is not None, "partial STATE baseline")
            require(self.ref("STATE/PROJECT_STATE.md").read_bytes() == old_state, "Worker changed BRAIN-owned PROJECT_STATE")
            old_rows = table(prior.decode(), TASK_HEADER, "base TASK_LEDGER")
            for row in old_rows:
                require(row["TASK_ID"] in ledger, "prior ledger task removed")
                now = ledger[row["TASK_ID"]]
                require(now["BRAIN_CLASSIFICATION"] == row["BRAIN_CLASSIFICATION"], "Worker changed BRAIN classification")
                require(row["TASK_ID"] == self.args.task_id or now == row, "Worker changed another task row")
            old_ids = {row["TASK_ID"] for row in old_rows}
            require(set(ledger) - old_ids <= {self.args.task_id}, "Worker added unrelated task")
        rules = table(self.text("STATE/RULE_PROMOTION_LEDGER.tsv"), RULE_HEADER, "RULE_PROMOTION_LEDGER")
        for row in rules:
            datetime.strptime(row["DATE"], "%Y-%m-%d")
            require(row["TASK_ID"] in ledger and row["CLASSIFICATION"] == "RULE"
                    and row["STATUS"] == "ACCEPTED", "invalid accepted rule promotion")
            for key in RULE_HEADER:
                concrete(row[key], f"RULE_PROMOTION_LEDGER.{key}")
        require(len({(row["TASK_ID"], row["CANDIDATE"]) for row in rules}) == len(rules), "duplicate rule promotion")
        old_rules = self.base_bytes("STATE/RULE_PROMOTION_LEDGER.tsv")
        if not self.bootstrap:
            require(old_rules == self.ref("STATE/RULE_PROMOTION_LEDGER.tsv").read_bytes(), "Worker changed accepted rule promotions")
        else:
            require({row["CANDIDATE"] for row in rules} == {"ROOT_DISCOVERABLE_KERNEL", "STABLE_BRAIN_COMPACT", "FULL_DESKTOP_FALLBACK", "NO_MODEL_BENCHMARK", "STATE_PLANE"}, "bootstrap promotions differ from directive")
        self.ledger = ledger
        self.receipt.update(task_rows=len(rows), rule_rows=len(rules), next_decision_count=1)
        self.receipt["checks"].append("state_schemas_refs_ownership_placeholders")

    def events(self):
        data = self.ref("STATE/EVENTS.jsonl").read_bytes()
        require(data.endswith(b"\n"), "EVENTS must end with LF")
        old = self.base_bytes("STATE/EVENTS.jsonl")
        require(old is None or data.startswith(old), "EVENTS is not append-only against base")
        events = []
        for number, line in enumerate(data.decode().splitlines(), 1):
            event = json.loads(line, object_pairs_hook=unique_json_object)
            require(isinstance(event, dict) and set(event) == EVENT_KEYS, f"invalid event schema at line {number}")
            for key in EVENT_KEYS - {"commit", "ref"}:
                require(isinstance(event[key], str) and bool(event[key].strip()), f"invalid event {key}")
            timestamp(event["ts"])
            require(event["actor"] in {"BRAIN", "WORKER", "OWNER"}, "invalid event actor")
            require(event["task_id"] in self.ledger, "event references unknown task")
            require(event["commit"] is None or (isinstance(event["commit"], str) and SHA.fullmatch(event["commit"])), "invalid event commit/null")
            if event["commit"] is not None:
                self.git("cat-file", "-e", event["commit"] + "^{commit}")
            require(event["ref"] is None or isinstance(event["ref"], str), "invalid event ref/null")
            if event["ref"] is not None:
                self.ref(event["ref"])
            if event["actor"] == "WORKER":
                require(event["event_type"] == "worker_return" and event["result"] in RESULTS, "Worker event cannot claim acceptance")
            events.append(event)
        prior_count = len(old.decode().splitlines()) if old else 0
        added = events[prior_count:]
        returns = [e for e in events if e["task_id"] == self.args.task_id and e["event_type"] == "worker_return"]
        require(len(returns) == 1, "closure requires exactly one worker_return event for task")
        event = returns[0]
        require(event["actor"] == "WORKER" and event["result"] == self.ledger[self.args.task_id]["WORKER_RESULT"]
                and event["ref"] == self.new_handoff, "worker_return/ledger mismatch")
        if self.bootstrap:
            require(len(events) == 4, "bootstrap requires three migration events plus one Worker return")
            for e in events[:2]:
                require(e["actor"] == "BRAIN" and e["event_type"] == "stage_accepted"
                        and e["task_id"] in BOOTSTRAP_ACCEPTED and e["result"] == "PASS_WITH_ADVISORY"
                        and e["commit"] == BOOTSTRAP_ACCEPTED[e["task_id"]], "invalid supplied acceptance event")
            require({e["task_id"] for e in events[:2]} == set(BOOTSTRAP_ACCEPTED), "missing migration acceptance")
            e = events[2]
            require(e["actor"] == "BRAIN" and e["event_type"] == "stage_authorized"
                    and e["task_id"] == BOOTSTRAP_TASK and e["result"] == "AUTHORIZED", "invalid supplied Stage-C authorization")
        else:
            require(all(e["actor"] == "WORKER" and e["task_id"] == self.args.task_id for e in added), "Worker fabricated non-Worker transition")
        self.receipt["event_rows"] = len(events)
        self.receipt["checks"].append("events_jsonl_append_only_return")

    def current(self):
        current = self.ref("handoffs/CURRENT_HANDOFF.md").read_bytes()
        prefix, blank, payload = current.split(b"\n", 2)
        require(prefix.startswith(b"UPDATED_AT: ") and blank == b"", "CURRENT requires UPDATED_AT plus blank line")
        timestamp(prefix.decode()[len("UPDATED_AT: "):])
        require(payload == self.ref(self.new_handoff).read_bytes(), "CURRENT/source byte parity failed")
        hot = fields(payload.decode().split("## HOT\n", 1)[1].split("\n## ", 1)[0])
        required = "HMD_SCHEMA HMD_VERSION PROJECT WORKSTREAM_ID HANDOFF_ID REPO BRANCH LOCAL_HEAD REMOTE_HEAD LAST_VERIFIED_AT AUTHORITY_PTRS CURRENT_PHASE CURRENT_GATE STATUS BLOCKER PROPOSED_NEXT NO_AUTO_NEXT".split()
        require(set(required) <= set(hot), "required HOT refs/fields missing")
        for key in required:
            concrete(hot[key], f"HOT.{key}")
        require(hot["HANDOFF_ID"] == self.new_handoff and hot["PROJECT"] == "FSD"
                and hot["NO_AUTO_NEXT"] == "YES", "invalid HOT identity")
        require(hot["REPO"] == str(self.root) and hot["BRANCH"] == self.args.expect_branch, "HOT Git identity mismatch")
        for key in ("LOCAL_HEAD", "REMOTE_HEAD"):
            require(SHA.fullmatch(hot[key]), f"invalid HOT {key}")
        timestamp(hot["LAST_VERIFIED_AT"])
        for ref in hot["AUTHORITY_PTRS"].split("|"):
            self.ref(ref)
        assignments = re.findall(r"^PROPOSED_NEXT=(.+)$", payload.decode(), re.M)
        require(len(assignments) == 1, "handoff requires exactly one Worker proposal")
        for name in ("BRAIN_REVIEW", "BRAIN_CLASSIFICATION", "BRAIN_ACCEPTED_STATE", "BRAIN_ACTIVE_NEXT"):
            require(not re.search(rf"^{name}=", payload.decode(), re.M), "Worker handoff authors BRAIN-owned fields")
        self.receipt["checks"].append("current_updated_at_exact_source_hot")
        self.worker_execution_guard(payload.decode())

    def worker_execution_guard(self, source):
        # Only the new handoff is checked. Declarations prove structure, not
        # skill loading, performed reasoning, or BRAIN acceptance.
        guard = {}
        for key in GUARD_KEYS:
            matches = re.findall(rf"^{key}=(.*)$", source, re.M)
            require(len(matches) == 1, f"missing/duplicate Worker guard field: {key}")
            guard[key] = matches[0]
        block = "\n".join(f"{key}={guard[key]}" for key in GUARD_KEYS)
        require(block in source, "Worker guard must be one contiguous ordered block")
        require(guard["WORKER_EXECUTION_GUARD"] == "FSD_WORKER_EXECUTION_V1",
                "invalid Worker guard version")
        require(guard["WORKER_PREFLIGHT"] in {"PASS", "FAIL"}, "invalid Worker preflight")
        require(guard["WORKER_POSTFLIGHT"] in {"PASS", "FAIL"}, "invalid Worker postflight")
        require(guard["NEXT_TASK_STARTED"] == "NO", "NEXT_TASK_STARTED must be NO")
        counts = {}
        for key in GUARD_KEYS[2:6]:
            require(re.fullmatch(r"[0-9]+", guard[key]),
                    f"Worker guard requires non-negative integer: {key}")
            counts[key] = int(guard[key])
        total, evidenced, not_applicable, unproven = (counts[key] for key in GUARD_KEYS[2:6])
        require(total == evidenced + not_applicable + unproven,
                "Worker guard requirement arithmetic mismatch")
        result = self.ledger[self.args.task_id]["WORKER_RESULT"]
        if result in {"PASS", "PASS_WITH_ADVISORY"}:
            require(unproven == 0, "PASS Worker guard has UNPROVEN requirements")
            require(guard["WORKER_PREFLIGHT"] == "PASS", "PASS requires passing preflight")
            require(guard["WORKER_POSTFLIGHT"] == "PASS", "PASS requires passing postflight")
            require(total == evidenced + not_applicable, "PASS requirement arithmetic mismatch")
        self.receipt["worker_execution_guard"] = guard
        self.receipt["checks"].append("worker_execution_guard_structure_only")

    def operator_and_desktop(self):
        operator = self.ref("docs/BRAIN_OPERATOR.md").read_bytes()
        version = re.findall(rb"^VERSION=([^\n]+)$", operator, re.M)
        require(len(version) == 1 and operator.endswith(b"\n"), "invalid canonical Operator version/bytes")
        for key in (b"STATE_PLANE=", b"BRAIN_DIRECT_STATE_WRITE_ALLOWED=YES"):
            require(key in operator, "Operator lacks STATE policy")
        desktop = self.args.desktop.expanduser()
        if not desktop.exists():
            require(not self.args.require_desktop, "required Desktop fallback absent")
            self.receipt["desktop"] = "ABSENT;PARITY_NOT_CHECKED"
            return
        packet = desktop.read_bytes()
        require(packet.count(b"\n" + BEGIN) == 1 and packet.count(b"\n" + END) == 1, "Desktop needs unique standalone Operator markers")
        start = packet.index(b"\n" + BEGIN) + 1 + len(BEGIN)
        end = packet.index(b"\n" + END) + 1
        require(start <= end and packet[start:end] == operator, "Desktop Operator exact-byte parity failed")
        # Projection metadata must be outside the payload, not matched inside policy.
        outside = packet[:start - len(BEGIN)] + packet[end + len(END):]
        digest = hashlib.sha256(operator).hexdigest()
        metadata = {"BRAIN_OPERATOR_PATH": "docs/BRAIN_OPERATOR.md",
                    "BRAIN_OPERATOR_VERSION": version[0].decode(),
                    "BRAIN_OPERATOR_SHA256": digest, "BRAIN_OPERATOR_PROJECTION": "EXACT"}
        for key, value in metadata.items():
            matches = re.findall(rb"^" + key.encode() + rb"=([^\n]+)$", outside, re.M)
            require(matches == [value.encode()], f"Desktop metadata mismatch: {key}")
        require(packet.endswith(self.ref("handoffs/CURRENT_HANDOFF.md").read_bytes()), "Desktop missing exact full CURRENT recovery copy")
        for path in ("STATE/PROJECT_STATE.md", "STATE/EVENTS.jsonl", "STATE/TASK_LEDGER.tsv", "STATE/RULE_PROMOTION_LEDGER.tsv"):
            require(path.encode() in outside, "Desktop missing STATE recovery pointer")
        self.receipt["desktop"] = dict(path=str(desktop), operator_sha256=digest, exact_parity=True, full_current=True)
        self.receipt["checks"].append("canonical_operator_desktop_digest_bytes")

    def run(self):
        self.git_identity()
        self.scope_and_history()
        self.state_and_ledgers()
        self.events()
        self.current()
        self.operator_and_desktop()


def unique_json_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON key: {key}")
        result[key] = value
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--task-id", required=True, help="Worker task being finalized; classification must remain pending")
    parser.add_argument("--base", required=True, help="full re-anchor SHA before task mutations")
    parser.add_argument("--allow-path", action="append", required=True, help="exact allowed relative path; repeat for each")
    parser.add_argument("--expect-branch", default="main")
    parser.add_argument("--expect-origin", default="https://github.com/cenvu/FSD.git")
    parser.add_argument("--desktop", type=Path, default=Path.home() / "Desktop/04_FSD_BRAIN.md")
    parser.add_argument("--require-desktop", action="store_true")
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--require-synced", action="store_true")
    parser.add_argument("--max-fetch-age-seconds", type=int, default=900)
    args = parser.parse_args()
    checker = Checker(args)
    try:
        checker.run()
    except (CheckError, OSError, ValueError, IndexError, UnicodeError, csv.Error) as exc:
        checker.receipt.update(result="FAIL", error=str(exc))
        print(json.dumps(checker.receipt, indent=2))
        return 1
    checker.receipt["result"] = "PASS"
    print(json.dumps(checker.receipt, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
