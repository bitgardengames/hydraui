import re
from collections import Counter
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPOSITORY_ROOT / "HydraUI"
BUNDLED_OUF = SOURCE_ROOT / "Elements" / "Libraries" / "oUF"
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
            # The bundled oUF tree is retained as implementation reference
            # material, but is deliberately absent from every addon manifest.
            and BUNDLED_OUF not in path.parents
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


def test_bundled_ouf_source_is_retained_as_a_reference():
    assert BUNDLED_OUF.is_dir()
    assert (BUNDLED_OUF / "ouf.lua").is_file()
    assert (BUNDLED_OUF / "LICENSE").is_file()


def test_no_active_runtime_ouf_references_remain():
    actual = {}

    for path in runtime_files():
        references = references_in(path)
        if references:
            actual[str(path.relative_to(REPOSITORY_ROOT))] = references

    assert actual == EXPECTED_REFERENCES, (
        "The retired unit-frame runtime was referenced by packaged code.\n"
        f"Expected: {EXPECTED_REFERENCES!r}\nActual: {actual!r}"
    )
