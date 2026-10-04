import re
from collections import Counter
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPOSITORY_ROOT / "HydraUI"
BUNDLED_REFERENCE = SOURCE_ROOT / "Elements" / "Libraries" / "oUF"
RUNTIME_SUFFIXES = {".lua", ".xml", ".toc"}
REFERENCE_PATTERN = re.compile(
    r"(?:ns|Namespace)\.oUF|oUF-|(?<![\w.])oUF\b"
)

EXPECTED_REFERENCES = {}


def runtime_files():
    for path in SOURCE_ROOT.rglob("*"):
        if (
            path.is_file()
            and path.suffix.lower() in RUNTIME_SUFFIXES
            and BUNDLED_REFERENCE not in path.parents
        ):
            yield path


def references_in(path):
    references = Counter()

    for line in path.read_text(encoding="utf-8").splitlines():
        # Prose comments are not runtime dependencies. String values remain
        # visible so retired secure attributes and UI labels are still guarded.
        if path.suffix.lower() == ".lua":
            line = line.split("--", 1)[0]

        references.update(REFERENCE_PATTERN.findall(line))

    return references


def test_bundled_ouf_reference_is_retained():
    assert BUNDLED_REFERENCE.is_dir()
    assert (BUNDLED_REFERENCE / "LICENSE").is_file()


def test_no_runtime_ouf_references_remain():
    actual = {}

    for path in runtime_files():
        references = references_in(path)
        if references:
            actual[str(path.relative_to(REPOSITORY_ROOT))] = references

    assert actual == EXPECTED_REFERENCES, (
        "The retired unit-frame runtime was referenced by packaged code.\n"
        f"Expected: {EXPECTED_REFERENCES!r}\nActual: {actual!r}"
    )
