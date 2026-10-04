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

# This is migration debt, not a general exemption. Keep it synchronized with
# Elements/UnitFrames/OUF_MIGRATION_AUDIT.md as references are removed.
EXPECTED_REFERENCES = {
    "HydraUI/HydraUI_Camelot.toc": Counter({"oUF": 1}),
    "HydraUI/HydraUI_Classic.toc": Counter({"oUF": 1}),
    "HydraUI/HydraUI_Mainline.toc": Counter({"oUF": 1}),
    "HydraUI/HydraUI_Mists.toc": Counter({"oUF": 1}),
    "HydraUI/HydraUI_TBC.toc": Counter({"oUF": 1}),
    "HydraUI/Elements/Credit.lua": Counter({"oUF": 1}),
    "HydraUI/Elements/Colors.lua": Counter({"Namespace.oUF": 2, "oUF": 1}),
    "HydraUI/Elements/UnitFrames/NamePlates.lua": Counter(
        {"oUF": 2, "ns.oUF": 1}
    ),
    "HydraUI/Elements/UnitFrames/Spawning.lua": Counter(
        {"oUF": 9, "oUF-": 4, "ns.oUF": 1}
    ),
    "HydraUI/Elements/UnitFrames/Tags.lua": Counter(
        {"oUF": 4, "ns.oUF": 1}
    ),
    "HydraUI/Elements/UnitFrames/UnitFrames.lua": Counter(
        {"oUF": 3, "ns.oUF": 1}
    ),
}


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
        # A prose mention in a Lua comment is not a runtime dependency. String
        # values remain visible so secure oUF attributes and UI labels are
        # still guarded.
        if path.suffix.lower() == ".lua":
            line = line.split("--", 1)[0]

        references.update(REFERENCE_PATTERN.findall(line))

    return references


def test_no_new_ouf_references_outside_bundled_reference():
    actual = {}

    for path in runtime_files():
        references = references_in(path)
        if references:
            actual[str(path.relative_to(REPOSITORY_ROOT))] = references

    assert actual == EXPECTED_REFERENCES, (
        "The oUF migration boundary changed. Do not add direct references; "
        "when removing migration debt, update OUF_MIGRATION_AUDIT.md and the "
        "test snapshot together.\n"
        f"Expected: {EXPECTED_REFERENCES!r}\nActual: {actual!r}"
    )
