#!/bin/bash
# Manual ADR-035 rebuild only. Never called by Xcode.
# Usage: build_classification_helper.sh VERIFIED_ARCHIVE NEW_SCRATCH_DIRECTORY
# Output stays in scratch; review two independent builds before copying to FSD.
set -euo pipefail
exec /usr/bin/python3 - "$@" <<'PY'
from pathlib import Path
import hashlib,json,os,re,shutil,stat,subprocess,sys,tarfile

ARCHIVE_SHA='ee215d57e0ec269c60cc9ceca68e6bda321ba9ee5afe24f4b0988703c2d87d12'
MODULE='github.com/h2non/filetype'
VERSION='v1.1.3'
SUM='h1:FKkx9QbD7HR/zjK1Ia5XiBsq9zdLi5Kf3zGyFTAFkGg='
MODSUM='h1:319b3zT68BvV+WRj7cwy856M2ehB3HqNOt6sy1HndBY='
if len(sys.argv)!=3:
    raise SystemExit('usage: build_classification_helper.sh ARCHIVE NEW_SCRATCH')
archive=Path(sys.argv[1]).resolve(strict=True)
if hashlib.sha256(archive.read_bytes()).hexdigest()!=ARCHIVE_SHA:
    raise SystemExit('STOP: archive pin mismatch (not extracted)')
scratch=Path(sys.argv[2]).absolute()
if scratch.exists() or scratch.is_symlink():
    raise SystemExit('STOP: scratch must be a new independent tree')
repo=Path.cwd().resolve()
source=repo/'Tools/FSDClassificationHelper'
expected=f'{MODULE} {VERSION} {SUM}\n{MODULE} {VERSION}/go.mod {MODSUM}\n'
if (source/'go.sum').read_text()!=expected:
    raise SystemExit('STOP: committed go.sum pin mismatch')
scratch.mkdir(parents=True)
scratch=scratch.resolve()
with tarfile.open(archive) as tar:
    for member in tar.getmembers():
        if member.name.startswith('/') or '..' in Path(member.name).parts:
            raise SystemExit('STOP: archive path escapes scratch')
    tar.extractall(scratch)
(scratch/'go').rename(scratch/'toolchain')
if (scratch/'toolchain/VERSION').read_text().splitlines()[0]!='go1.27.1':
    raise SystemExit('STOP: Go version mismatch')
# Relocation verified against official pinned cmd/internal/telemetry/counter.
if 'counter.OpenDir(os.Getenv("TEST_TELEMETRY_DIR"))' not in (scratch/'toolchain/src/cmd/internal/telemetry/counter/counter.go').read_text():
    raise SystemExit('STOP: telemetry containment source changed')
telemetry=Path.home()/'Library/Application Support/go/telemetry'
def metadata():
    if not telemetry.exists():return {'exists':False}
    result={}
    for p in [telemetry,*sorted(telemetry.rglob('*'))]:
        st=p.lstat()
        result[str(p.relative_to(telemetry))]=dict(type=stat.S_IFMT(st.st_mode),size=st.st_size,mtime_ns=st.st_mtime_ns,inode=st.st_ino)
    return result
before=metadata()
(scratch/'external-telemetry-before.json').write_text(json.dumps(before,sort_keys=True,indent=2)+'\n')
env=dict(PATH=str(scratch/'toolchain/bin')+':/usr/bin:/bin:/usr/sbin:/sbin',GOENV='off',GOTOOLCHAIN='local',CGO_ENABLED='0',GOOS='darwin',GOARCH='arm64',GOPROXY='file://'+str(scratch/'proxy'),GOSUMDB='off')
for key,name in dict(TEST_TELEMETRY_DIR='go-telemetry',HOME='home',XDG_CONFIG_HOME='xdg-config',XDG_CACHE_HOME='xdg-cache',GOROOT='toolchain',GOPATH='gopath',GOMODCACHE='gomodcache',GOCACHE='gocache',GOTMPDIR='gotmp',TMPDIR='gotmp').items():
    p=scratch/name;p.mkdir(exist_ok=True);env[key]=str(p)
(scratch/'go-telemetry/mode').write_text('off\n')
(scratch/'environment.json').write_text(json.dumps(env,indent=2)+'\n')
# Only the exact authorized module's proxy objects; no sumdb/network in Go.
proxy=scratch/'proxy/github.com/h2non/filetype/@v';proxy.mkdir(parents=True)
for suffix in ('info','mod','zip'):
    subprocess.run(['/usr/bin/curl','--fail','--location','--silent','--show-error','--max-time','120','--output',str(proxy/(VERSION+'.'+suffix)),'https://proxy.golang.org/github.com/h2non/filetype/@v/'+VERSION+'.'+suffix],check=True)
work=scratch/'source';work.mkdir()
for name in ('main.go','go.mod','go.sum'):shutil.copyfile(source/name,work/name)
policy=scratch/'go.sb'
policy.write_text('(version 1)\n(allow default)\n(deny file-write*)\n(allow file-write* (subpath '+json.dumps(str(scratch))+'))\n(allow file-write-data (literal "/dev/null"))\n(deny network*)\n')
receipts=[]
def go(*args):
    run=subprocess.run(['/usr/bin/sandbox-exec','-f',str(policy),str(scratch/'toolchain/bin/go'),*args],cwd=work,env=env,capture_output=True,text=True)
    after=metadata();(scratch/'external-telemetry-after.json').write_text(json.dumps(after,sort_keys=True,indent=2)+'\n')
    receipts.append(dict(args=list(args),exit=run.returncode,external_telemetry_unchanged=before==after))
    (scratch/'go-receipts.json').write_text(json.dumps(receipts,indent=2)+'\n')
    if before!=after:raise SystemExit('STOP: outside-scratch telemetry change')
    if run.returncode:raise SystemExit('STOP: Go command failed: '+run.stderr)
    return run.stdout
if go('version').strip()!='go version go1.27.1 darwin/arm64':raise SystemExit('STOP: toolchain identity')
info=json.loads(go('mod','download','-json',MODULE+'@'+VERSION))
(scratch/'module-identity.json').write_text(json.dumps(info,indent=2)+'\n')
if info.get('Sum')!=SUM or info.get('GoModSum')!=MODSUM:raise SystemExit('STOP: module pin mismatch')
if (work/'go.sum').read_text()!=expected:raise SystemExit('STOP: go.sum changed')
go('mod','verify')
output=scratch/'FSDClassificationHostSeam'
go('build','-mod=readonly','-trimpath','-buildvcs=false','-ldflags=-buildid=','-o',str(output),'.')
(scratch/'build-metadata.txt').write_text(go('version','-m',str(output)))
(scratch/'deps.json').write_text(go('list','-deps','-json','.'))
(scratch/'symbols.txt').write_text(go('tool','nm',str(output)))
(scratch/'math-log-objdump.txt').write_text(go('tool','objdump','-s','math.log',str(output)))
if before!=metadata():raise SystemExit('STOP: outside-scratch telemetry change')
print('HELPER='+str(output))
print('HELPER_SHA256='+hashlib.sha256(output.read_bytes()).hexdigest())
print('OUTSIDE_SCRATCH_WRITES=0;OS_SANDBOX_ENFORCED;EXTERNAL_TELEMETRY_METADATA_UNCHANGED')
PY
