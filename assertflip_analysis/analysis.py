import json
import orjson
from collections.abc import Iterable
from functools import partial
from itertools import repeat
from typing import TypeVar
from os.path import join
from os import makedirs
from typing import Self
from typing import Any
import traceback
from collections.abc import Callable
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

T = TypeVar("T")
R = TypeVar("R")

ic.disable()


@click.group()
def cli():
    pass


@dataclass
class Error:
    exc_type: str
    traceback: str
    value: Any

    @classmethod
    def from_exception(cls, e: Exception, value: Any) -> Self:
        return cls(
            exc_type=e.__class__.__name__, traceback=traceback.format_exc(), value=value
        )


def safe_gen(
    func: Callable[[T], R]
) -> Callable[[Iterable[T | Error]], Iterable[R | Error]]:
    @wraps(func)
    def wrapped(iterable: Iterable[T | Error]) -> Iterable[R | Error]:
        for x in iterable:
            if isinstance(x, Error):
                yield x
                continue

            try:
                yield func(x)
            except Exception as e:
                yield Error.from_exception(e, x)

    return wrapped


def safe(func: Callable[[T], R]) -> Callable[[T], R | Error]:
    @wraps(func)
    def wrapped(x: T) -> R | Error:
        try:
            return func(x)
        except Exception as e:
            return Error.from_exception(e, x)

    return wrapped


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


def open_files(files: Iterable[Path | Error]) -> Iterable[TextIOBase | Error]:
    for file in files:
        if isinstance(file, Error):
            yield file
            continue

        try:
            with open(file) as f:
                yield f
        except Exception as e:
            yield Error.from_exception(e, file)


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
        return f"{self.file}:{self.func}"

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

                while depths and depth < depths[-1]:
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
    # json_str = json.dumps(obj, separators=(",", ":"))
    json_str = orjson.dumps(obj).decode()
    compressed = zlib.compress(json_str.encode("utf-8"))
    b64_str = base64.b64encode(compressed).decode("ascii")
    return b64_str


def decode_object(b64_str: str):
    compressed = base64.b64decode(b64_str)
    json_str = zlib.decompress(compressed).decode("utf-8")
    # obj = json.loads(json_str)
    obj = orjson.loads(json_str)
    return obj


@cli.command()
@click.option("--stacks-dir", "-s", type=str)
@click.option("--dev-locs-file", "-d", type=str)
def main_select_stacks(stacks_dir: str, dev_locs_file: str) -> None:
    stacks_files = sorted(Path(stacks_dir).glob("*.b64"))
    # stacks_files = [Path(stacks_dir) / "astropy__astropy-12907.b64"]
    with Pool(64) as pool:
        texts = pool.map(Path.read_text, tqdm(stacks_files, desc="read files"))
        stacks = pool.map(
            decode_object_safe,
            tqdm(texts, total=len(stacks_files), desc="decode objects"),
        )
    stacks_map = ChainMap(*(s for s in stacks if not isinstance(s, Error)))

    stacks_map = {
        k: [[Func(*x) for x in stack] for stack in stacks]
        for k, stacks in stacks_map.items()
    }
    stacks_map = {k: list(clean_stacks(v)) for k, v in stacks_map.items()}

    with open("bar2.json", "w") as f:
        x = {
            k: [list(map(tuple, stack)) for stack in stacks]
            for k, stacks in stacks_map.items()
        }
        f.write(orjson.dumps(x, option=orjson.OPT_INDENT_2).decode())

        relevant_dir = "assertflip_analysis/clean_stacks"
        makedirs(relevant_dir, exist_ok=True)
        try:
            dicts = (dict([item]) for item in x.items())
            out_files = (Path(relevant_dir, f"{k}.b64") for k in x)
            with Pool(64) as pool:
                contents = pool.map(
                    encode_object,
                    tqdm(dicts, total=len(stacks_files), desc="encode clean stack"),
                )
                pool.starmap(
                    Path.write_text,
                    tqdm(
                        zip(out_files, contents),
                        total=len(stacks_files),
                        desc="dump clean stack",
                    ),
                )

            # for k, v in x.items():
            #     with open(join(clean_dir, f"{k}.b64"), "w") as f:
            #         f.write(encode_object({k: v}))
        except Exception:
            import traceback

            traceback.print_exc()
        # json.dump(dict(stacks_map.items()), f, indent=4)

    with open(dev_locs_file) as f:
        dev_locs_map = ChainMap(*map(json.loads, f))

    def dev_loc_to_func(dev_loc: dict) -> Func:
        if dev_loc["start"] is None:
            func_name = "<module>"
        elif dev_loc["class_name"]:
            func_name = f"{dev_loc['class_name']}.{dev_loc['method_name']}"
        else:
            func_name = dev_loc["method_name"]
        return Func(dev_loc["rel_file_path"], "", func_name)

    dev_funcs_map = {k: set(map(dev_loc_to_func, v)) for k, v in dev_locs_map.items()}

    print(dev_funcs_map)

    relevant_stacks_map = {
        k: list(select_stacks(stacks_map[k], dev_funcs_map[k]))
        for k in tqdm(stacks_map, total=len(stacks_files), desc="select stacks")
        if k in dev_funcs_map
    }

    with open("assertflip_analysis/relevant_stacks.json", "w") as f:
        x = {
            k: [list(map(tuple, stack)) for stack in stacks]
            for k, stacks in relevant_stacks_map.items()
        }
        f.write(orjson.dumps(x, option=orjson.OPT_INDENT_2).decode())
        # json.dump(x, f, indent=4)

        relevant_dir = "assertflip_analysis/relevant_stacks"
        makedirs(relevant_dir, exist_ok=True)
        try:
            # for k, v in x.items():
            #     with open(join(relevant_dir, f"{k}.json"), "w") as f:
            #         f.write(orjson.dumps({k: v}, option=orjson.OPT_INDENT_2).decode())

            dicts = (dict([item]) for item in x.items())
            out_files = (Path(relevant_dir, f"{k}.json") for k in x)
            with Pool(64) as pool:
                contents = pool.map(
                    partial(orjson.dumps, option=orjson.OPT_INDENT_2),
                    tqdm(dicts, total=len(stacks_files), desc="dump relevant"),
                )
                pool.starmap(Path.write_bytes, zip(out_files, contents))
        except Exception:
            import traceback

            traceback.print_exc()


def select_stacks(
    stacks: Iterable[Sequence[Func]], dev_funcs: set[Func]
) -> Iterable[Sequence[Func]]:
    for stack in stacks:
        if any(func in stack for func in dev_funcs):
            yield stack


def clean_stacks(stacks: Iterable[Sequence[Func]]) -> Iterable[Sequence[Func]]:
    def filter_stack(stack: Iterable[Func]) -> list[Func]:
        return [
            Func(f.file.removeprefix("/testbed/"), f.module, f.func)
            for f in stack
            if "/tests/" not in f.file
            and "/site-packages/" not in f.file
            and "miniconda" not in f.file
            and "/root/trace.py" not in f.file
            and "<frozen importlib" not in f.file
        ]

    yield from filter(None, map(filter_stack, stacks))


def _write_call(task_dir: Path, call_b64: str | Error, out_dir: str) -> None:
    if isinstance(call_b64, str):
        with open(join(out_dir, f"{task_dir.name}.b64"), "w") as f:
            f.write(encode_object({task_dir.name: decode_object(call_b64)}))


@cli.command()
@click.option("--swt-logs-dir", "-i", type=str)
@click.option("--output-dir", "-o", type=str)
def main_extract_calls(swt_logs_dir: str, output_dir: str) -> None:
    task_dirs = list(Path(swt_logs_dir).glob("*/"))

    @safe_gen
    def _extract_calls(iterable: Iterable[str]) -> str:
        it = iter(iterable)
        for line in it:
            if line.startswith("Call stacks json base64:"):
                try:
                    return next(it).strip()
                except StopIteration as e:
                    raise RuntimeError("calls not found") from e
        raise RuntimeError("calls not found")

    fds = open_files(d / "test_output.txt" for d in task_dirs)
    calls = _extract_calls(fds)
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True)

    from multiprocessing.pool import Pool

    with Pool(12) as pool:
        pool.starmap(
            _write_call,
            tqdm(zip(task_dirs, calls, repeat(output_dir)), total=len(task_dirs)),
        )


def _write_stack(task_id: str, trace: list[Edge], stacks_dir: str) -> None:
    stacks = list(map(list, ReconstructCallstacks.run(trace)))
    data = {task_id: stacks}

    with open(join(stacks_dir, f"{task_id}.b64"), "w") as f:
        f.write(encode_object(data))


def decode_object_safe(s: str):
    return safe(decode_object)(s)


@cli.command()
@click.option("--calls-dir", "-i", type=str)
@click.option("--stacks-dir", "-o", type=str)
def main_reconstruct_callstacks(calls_dir: str, stacks_dir: str) -> None:
    calls_files = list(Path(calls_dir).glob("*"))
    # texts = (f.read_text() for f in calls_files)
    # texts = (Path.read_text(f) for f in calls_files)
    # calls = map(safe(decode_object), texts)
    with Pool(12) as pool:
        texts = pool.map(Path.read_text, tqdm(calls_files, desc="read files"))
    with Pool(128) as pool:
        calls = pool.map(
            decode_object_safe, tqdm(texts, total=len(calls_files), desc="decode calls")
        )
    calls = (x for x in calls if not isinstance(x, Error))
    calls_map = ChainMap(*calls)

    makedirs(stacks_dir, exist_ok=True)

    with Pool(128) as pool:
        args = ((*item, stacks_dir) for item in calls_map.items())
        pool.starmap(_write_stack, tqdm(args, total=len(calls_map)))


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
