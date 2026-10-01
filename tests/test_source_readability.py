import re
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = REPOSITORY_ROOT / "HydraUI"
LIBRARIES_ROOT = SOURCE_ROOT / "Elements" / "Libraries"


def first_party_files():
    for path in SOURCE_ROOT.rglob("*"):
        if path.is_file() and LIBRARIES_ROOT not in path.parents:
            yield path


def first_party_lua_files():
    yield from (path for path in first_party_files() if path.suffix == ".lua")


def test_first_party_text_files_have_no_trailing_whitespace():
    offenders = []

    for path in first_party_files():
        try:
            lines = path.read_text().splitlines()
        except UnicodeDecodeError:
            continue

        for line_number, line in enumerate(lines, start=1):
            if line != line.rstrip():
                offenders.append(f"{path.relative_to(REPOSITORY_ROOT)}:{line_number}")

    assert not offenders, "Trailing whitespace found in:\n" + "\n".join(offenders)


def test_first_party_lua_uses_tabs_for_indentation():
    offenders = []

    for path in first_party_lua_files():
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            if line.startswith(" "):
                offenders.append(f"{path.relative_to(REPOSITORY_ROOT)}:{line_number}")

    assert not offenders, "Space-indented Lua found in:\n" + "\n".join(offenders)


def test_first_party_lua_expands_control_flow_across_lines():
    compact_block = re.compile(
        r"^\s*(?:(?:if|elseif|for|while) .+ (?:then|do)|else|"
        r"(?:local\s+\w+\s*=\s*)?function .+\)) .+ end(?:\s*--.*)?$"
    )
    offenders = []

    for path in first_party_lua_files():
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            if compact_block.match(line):
                offenders.append(f"{path.relative_to(REPOSITORY_ROOT)}:{line_number}")

    assert not offenders, "Compact Lua blocks found in:\n" + "\n".join(offenders)


def test_first_party_lua_avoids_redundant_control_flow_parentheses():
    control_flow = re.compile(r"^\s*(?:if|elseif|while) (.+) (?:then|do)(?:\s*--.*)?$")
    offenders = []

    for path in first_party_lua_files():
        for line_number, line in enumerate(path.read_text().splitlines(), start=1):
            match = control_flow.match(line)
            if not match:
                continue

            condition = match.group(1)
            depth = 0
            closes_at_end = False
            for index, character in enumerate(condition):
                if character == "(":
                    depth += 1
                elif character == ")":
                    depth -= 1
                    if depth == 0:
                        closes_at_end = index == len(condition) - 1
                        break

            if condition.startswith("(") and closes_at_end:
                offenders.append(f"{path.relative_to(REPOSITORY_ROOT)}:{line_number}")

    assert not offenders, "Redundant control-flow parentheses found in:\n" + "\n".join(offenders)
