import json
from collections.abc import Iterable
from collections import ChainMap
from tqdm import tqdm
import base64
import zlib
from io import TextIOBase
from collections import deque
from collections.abc import Sequence
from typing import NamedTuple
from dataclasses import dataclass
from multiprocessing.pool import Pool
from itertools import chain
from pathlib import Path
import re
from more_itertools import peekable

from icecream import ic
import click

ic.disable()


@click.group()
def cli():
    pass


def extract_cov(lines: Iterable[str]) -> dict:
    it = iter(lines)
    for line in it:
        if line.startswith("+ cat coverage.cover"):
            cov = next(it)
            if cov.startswith("+ git checkout"):
                return {"exception": "EMPTY_COVERAGE"}
            elif cov.startswith("cat: coverage.cover: No such file or directory"):
                return {"exception": "NO_COVERAGE_DUMPED"}
            assert cov.startswith('{"'), cov
            return json.loads(cov)
    raise RuntimeError


def open_files(files: Iterable[Path]) -> Iterable[TextIOBase | None]:
    for file in files:
        try:
            with open(file) as f:
                yield f
        except Exception:
            yield None


@cli.command()
def main_extract_cov():
    files = list(
        Path("/Users/Haifeng.Ruan/Downloads/assertflip/pred_pre__AssertFlip").rglob(
            "test_output.txt"
        )
    )
    fds = open_files(files)
    locations = map(extract_cov, fds)
    result = {
        Path(file).parent.name: location for file, location in zip(files, locations)
    }
    with open("coverage_pre_patch.json", "x") as f:
        json.dump(result, f, indent=2)


def is_covering_locations(
    cov: dict[str, dict[str, int]], locations: dict[str, list[dict]]
) -> str:
    norm_cov = normalize_cov(cov)
    norm_locations = normalize_locations(locations)

    def is_covering_location(
        cov: dict[str, set[int]], location: tuple[str, set[int]]
    ) -> bool:
        file, lines = location

        c_files = [f for f in cov if f.endswith(file)]
        assert len(c_files) <= 1

        if not c_files:
            return False

        c_file = c_files[0]
        c_lines = cov[c_file]

        return any(c_line in lines for c_line in c_lines)

    is_covering = [
        is_covering_location(norm_cov, (k, v)) for k, v in norm_locations.items()
    ]

    if all(is_covering):
        return "all"
    elif any(is_covering):
        return "partial"
    else:
        return "none"


def normalize_cov(cov: dict[str, dict[str, int]]) -> dict[str, set[int]]:
    return ic(
        {
            file: {int(line) for line, count in v.items() if count > 0}
            for file, v in cov.items()
        }
    )


def normalize_locations(locations: dict[str, list[dict]]) -> dict[str, set[int]]:
    def get_lines(method: dict) -> Iterable[int]:
        start, end = method["line_range"]
        return range(start, end + 1)

    return ic(
        {
            file: set(chain.from_iterable(map(get_lines, methods)))
            for file, methods in locations.items()
        }
    )


@cli.command()
def main_check_cov():
    DIR = Path(__file__).parent

    def load_line(line: str) -> tuple[str, dict] | None:
        try:
            data = json.loads(line)
            return data["task_id"], data["locations"]
        except Exception:
            return None

    with open(DIR / "dev_locations_w_lines.jsonl") as f:
        task2locations = dict(filter(None, map(load_line, f)))

    with open(DIR / "coverage_pre_patch.json") as f:
        task2cov = json.load(f)

    result = {}
    for task, cov in task2cov.items():
        try:
            result[task] = is_covering_locations(cov, task2locations[task])
        except Exception as e:
            print(task, str(e))

    with open("cov_result.json", "w") as f:
        json.dump(result, f, indent=4)


@cli.command()
def main_find_resolved():
    DIR = Path(__file__).parent
    files = DIR.glob("AssertFlip/*/report.json")

    def open_files(files: Iterable[Path]) -> Iterable[TextIOBase]:
        for file in files:
            with open(file) as f:
                yield f

    def load_file(f: TextIOBase) -> tuple[str, bool]:
        data = json.load(f)
        task_id, report = next(iter(data.items()))
        return task_id, report["resolved"]

    resolved_tasks = [
        task for task, resolved in map(load_file, open_files(files)) if resolved
    ]

    Path("resolved_tasks.txt").write_text("\n".join(sorted(resolved_tasks)))


@cli.command()
def main_report_result():
    with open("resolved_tasks.txt") as f:
        resolved_tasks = set(filter(None, (line.strip() for line in f)))

    with open("cov_result.json") as f:
        cov_result = json.load(f)

    from collections import Counter

    resolved_counter = Counter()
    resolved_counter.update(cov_result.get(t) for t in resolved_tasks)

    print("resolved:", resolved_counter)

    all_counter = Counter()
    all_counter.update(cov_result.values())

    print("all:", all_counter)


from functools import wraps


def catch(f):
    from traceback import format_exc

    @wraps(f)
    def wrapped(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except Exception:
            return {"EXCEPTION": format_exc()}

    return wrapped


@cli.command()
def main_extract_traces():
    expr_dir = Path(
        "/home/haifeng/projects/swt-bench/assertflip_analysis/assertflip/pred_pre__AssertFlip"
    )
    task_dirs = list(expr_dir.glob("*/"))

    files = (d / "test_output.txt" for d in task_dirs)
    fds = open_files(files)
    traces = map(_extract_trace, fds)

    with open("assertflip_analysis/raw.traces.jsonl", "w") as f:
        for task_dir, trace in zip(task_dirs, traces):
            json.dump({task_dir.name: list(trace)}, f)
            f.write("\n")


@dataclass
class Failure:
    testname: str
    trace: list[tuple[str, int]]


def _extract_trace_astropy(lines: Iterable[str]) -> list[Failure]:
    it = peekable(iter(lines))
    while True:
        if next(it).startswith("=================================== FAILURES ="):
            break

    def parse_failure(it: peekable) -> Failure:
        title = next(it)
        assert title.startswith("__"), title
        testname = title.split()[1]
        assert testname.isidentifier()

        while True:
            if next(it).startswith(
                "----------------------------- Captured stdout call "
            ):
                break

        trace = []
        while True:
            line = it.peek()
            if not re.search(r"^\d+\.\d+", line):
                break

            line = next(it)
            _, pos = line.partition(":")[0].split()
            file, _, line_num = pos.partition("(")
            line_num = int(line_num.removesuffix(")"))
            trace.append((file, line_num))

        return Failure(testname=testname, trace=trace)

    failures = []
    while not it.peek().startswith(
        "=========================== short test summary info ============================"
    ):
        failures.append(parse_failure(it))

    return failures


def _extract_trace(lines: Iterable[str] | None) -> Iterable[tuple[str, int] | None]:
    if lines is None:
        yield None
        return

    it = iter(lines)
    for line in it:
        if line.startswith("+ python3 /root/trace.py"):
            break

    for line in it:
        if line.startswith("+ cat coverage.cover"):
            break

        if time_match := re.search(r"^\d+\.\d+", line):
            if loc_match := re.search(r"\((?P<num>\d+)\):", line):
                file = line[time_match.end() + 1 : loc_match.start()]
                line_num = int(loc_match["num"])
                yield file, line_num


class FuncLoc(NamedTuple):
    file: str
    class_name: str | None
    func_name: str | None


def _translate(trace: Iterable[tuple[str, int]], index: dict) -> Iterable[FuncLoc]:
    from itertools import chain

    def _translate_loc(loc: tuple[str, int] | None) -> FuncLoc | None:
        if loc is None:
            return None

        loc_file, loc_line = loc
        for file, start, end, (class_name, func_name) in chain(
            index["class-function"], index["function"]
        ):
            if file == loc_file and start <= loc_line <= end:
                return FuncLoc(file, class_name, func_name)
        return FuncLoc(loc_file, "UNK", "UNK")

    for loc in trace:
        yield _translate_loc(loc)


def _coalesce(func_trace: Iterable[FuncLoc]) -> Iterable[FuncLoc]:
    last = None
    for loc in func_trace:
        if loc != last:
            yield loc
        last = loc


def _composed(
    trace: Iterable[tuple[str, int]] | None, index: dict
) -> Iterable[FuncLoc] | None:
    if trace is None:
        return None
    return list(_coalesce(_translate(trace, index)))


@cli.command()
@click.option("--ast-indices-file", type=str, help="ast index of swe projects")
@click.option("--traces-file", type=str, help="trace file")
def translate_trace_to_funcs(ast_indices_file: str, traces_file: str) -> None:
    from collections import ChainMap

    with open(ast_indices_file) as f:
        index_map = ChainMap(*map(json.loads, f))

    with open(traces_file) as f:
        trace_map = ChainMap(*map(json.loads, f))

    keys = set(trace_map) & set(index_map)
    assert keys
    traces = (trace_map[k] for k in keys)
    indices = (index_map[k] for k in keys)

    with Pool(50) as pool:
        coalesced = pool.starmap(_composed, tqdm(zip(traces, indices), total=len(keys)))
        # coalesced = pool.map(_coalesce, translated)

    with open("assertflip_analysis/func.traces.jsonl", "w") as f:
        for key, trace in zip(keys, coalesced):
            f.write(
                json.dumps({key: list(trace) if trace is not None else None}) + "\n"
            )


class Func(NamedTuple):
    file: str
    module: str
    func: str

    def __repr__(self):
        return f"{self.module}:{self.func}"

    def __eq__(self, other):
        return self.file == other.file and self.func == other.func


class Edge(NamedTuple):
    depth: int  # depth of stack frame
    caller: Func
    callee: Func


class ReconstructCallstacks:
    @staticmethod
    def run(trace: Iterable[Edge]) -> Iterable[Sequence[Func]]:
        stack = deque()
        depths = deque()
        last_callee = None
        for depth, caller, callee in trace:
            last_depth = depths[-1] if depths else -1
            if depth > last_depth:
                assert last_callee is None or (caller == last_callee), (
                    depth,
                    caller,
                    callee,
                )
                stack.append(caller)
                depths.append(depth)
            else:
                assert depths
                assert last_callee

                full_stack = stack.copy()
                full_stack.append(last_callee)
                yield full_stack

                while depth < depths[-1]:
                    stack.pop()
                    depths.pop()
                assert (not depths) or (depth == depths[-1] and caller == stack[-1])

                if depths:
                    stack.pop()
                    depths.pop()
                stack.append(caller)
                depths.append(depth)

            last_callee = callee

        if last_callee:
            stack.append(last_callee)
            yield stack

def encode_object(obj):
    json_str = json.dumps(obj, separators=(",", ":"))
    compressed = zlib.compress(json_str.encode("utf-8"))
    b64_str = base64.b64encode(compressed).decode("ascii")
    return b64_str
def decode_object(b64_str: str):
    compressed = base64.b64decode(b64_str)
    json_str = zlib.decompress(compressed).decode("utf-8")
    obj = json.loads(json_str)
    return obj


@cli.command()
@click.option("--stacks-file", "-s", type=str)
@click.option("--dev-locs-file", "-d", type=str)
def main_select_stacks(stacks_dir: str, dev_locs_file: str) -> None:
    stacks_files = Path(stacks_dir).glob("*.b64")
    stacks_map = ChainMap(*(decode_object(f.read_text()) for f in stacks_files))
    stacks_map = {
        k: [[Func(*x) for x in stack] for stack in stacks]
        for k, stacks in stacks_map.items()
    }
    stacks_map = {k: clean_stacks(v) for k, v in stacks_map}

    with open(dev_locs_file) as f:
        dev_locs_map = ChainMap(*map(json.loads, f))

    def dev_loc_to_func(dev_loc: dict) -> Func:
        if dev_loc["class_name"]:
            func_name = f"{dev_loc['class_name']}.{dev_loc['method_name']}"
        else:
            func_name = dev_loc["method_name"]
        return Func(dev_loc["rel_file_path"], "", func_name)

    dev_funcs_map = {k: set(map(dev_loc_to_func, v)) for k, v in dev_locs_map.items()}

    relevant_stacks_map = {
        k: select_stacks(stacks_map[k], dev_funcs_map[k]) for k in stacks_map
    }

    with open("assertflip_analysis/relevant_stacks.json", "w") as f:
        json.dump(relevant_stacks_map, f, indent=4)


def select_stacks(
    stacks: Iterable[Sequence[Func]], dev_funcs: set[Func]
) -> Iterable[Sequence[Func]]:
    for stack in stacks:
        for func in stack:
            if func in dev_funcs:
                yield stack
                continue


def clean_stacks(stacks: Iterable[Sequence[Func]]) -> Iterable[Sequence[Func]]:
    def filter_stack(stack: Iterable[Func]) -> list[Func]:
        return [f for f in stack if "/tests/" not in f.file]

    yield from filter(None, map(filter_stack, stacks))


# ____________________________________ TESTS __________________________________________


def test_reconstruct_callstacks():
    f, g, h, t, y = (Func("foo.py", "foo", name) for name in "fghty")
    trace = [Edge(1, f, g), Edge(2, g, h), Edge(2, g, t), Edge(1, f, y)]
    expected_callstacks = [[f, g, h], [f, g, t], [f, y]]
    result = ReconstructCallstacks.run(trace)
    assert list(map(list, result)) == expected_callstacks


def test_reconstruct_empty_callstacks():
    assert list(ReconstructCallstacks.run([])) == []


def test_reconstruct_real_callstacks():
    DIR = Path(__file__).parent
    file = DIR / "tests/fixtures/astropy-12907-stack.json"
    with open(file) as f:
        trace = json.load(f)
    trace = (
        Edge(depth, Func(*caller), Func(*callee)) for depth, caller, callee in trace
    )
    print(trace)
    stacks = ReconstructCallstacks.run(trace)

    def filter_stack(stack: Iterable[Func]) -> list[Func]:
        return [f for f in stack if "/astropy/" in f.file and "/tests/" not in f.file]

    filtered_stacks = list(filter(None, map(filter_stack, stacks)))
    print("total", len(filtered_stacks), "stacks")

    for stack in set(map(tuple, filtered_stacks)):
        print(stack)


if __name__ == "__main__":
    cli()
