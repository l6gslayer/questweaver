"""Validate the public source set and build a single-folder addon ZIP."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / 'QuestWeaver'
SOURCES = ['.gitignore', 'AGENTS.md', 'README.md', 'SOURCES.md', 'LICENSE', 'CHANGELOG.md',
           'HANDOFF.md', 'docs', 'VALIDATION.md', 'CATALOGUE.md', 'DARKSHORE_CATALOGUE.md', 'DARNASSUS_CATALOGUE.md', 'QuestWeaver', 'tests', 'scripts', '.github']
ALLOWED = {'.lua', '.toc', '.md', '.py', '.yml'}
PATTERNS = {
    'machine home path': r'(?:/Users/|/home/|[A-Za-z]:\\Users\\)[^\s"\']+',
    'email address': r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b',
    'GitHub credential': r'\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})',
    'private key': r'-----BEGIN [A-Z ]*PRIVATE KEY-----',
    'AWS key': r'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
}

def source_files():
    for name in SOURCES:
        path = ROOT / name
        if not path.exists():
            raise SystemExit(f'Missing public source: {name}')
        for file in sorted(path.rglob('*')) if path.is_dir() else [path]:
            if file.is_file() and '__pycache__' not in file.parts:
                yield file

def main():
    files = list(source_files())
    for file in files:
        if file.is_symlink():
            raise SystemExit('Symlinks cannot be published')
        relative = file.relative_to(ROOT)
        if file.suffix not in ALLOWED and str(relative) not in {'.gitignore', 'LICENSE'}:
            raise SystemExit(f'Unexpected publishable file: {relative}')
        content = file.read_text(encoding='utf-8')
        # The scanner contains deliberately generic signature literals.
        if relative == Path('scripts/package.py'):
            continue
        for label, pattern in PATTERNS.items():
            if re.search(pattern, content):
                raise SystemExit(f'Privacy check failed ({label}): {relative}')
    toc = (ADDON / 'QuestWeaver.toc').read_text()
    entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('#')]
    for entry in entries:
        if not (ADDON / entry).is_file():
            raise SystemExit(f'Manifest file missing: {entry}')
    version = re.search(r'^## Version: (.+)$', toc, re.M).group(1)
    target = ROOT / 'dist' / f'QuestWeaver-{version}.zip'
    target.parent.mkdir(exist_ok=True)
    addon_files = [ADDON / entry for entry in entries] + [ADDON / 'QuestWeaver.toc']
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for file in addon_files:
            archive.write(file, f'QuestWeaver/{file.name}')
        for name in ['README.md', 'LICENSE', 'SOURCES.md', 'VALIDATION.md', 'CHANGELOG.md', 'CATALOGUE.md', 'DARKSHORE_CATALOGUE.md', 'DARNASSUS_CATALOGUE.md']:
            archive.write(ROOT / name, f'QuestWeaver/{name}')
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None
        assert {name.split('/')[0] for name in archive.namelist()} == {'QuestWeaver'}
    print(f'Public source scan passed ({len(files)} files).')
    print(f'Manifest references passed ({len(entries)} Lua files).')
    print(f'ZIP integrity and single-folder layout passed: dist/{target.name}')

if __name__ == '__main__':
    main()
