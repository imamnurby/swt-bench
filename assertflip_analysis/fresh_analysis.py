from __future__ import annotations
import json
from loguru import logger
import orjson
from os.path import exists
from collections.abc import Iterable
from contextlib import contextmanager
from pydantic import TypeAdapter
from os.path import join
from os.path import basename
from collections import ChainMap
from concurrent.futures import ProcessPoolExecutor
import base64
from io import TextIOBase
import gzip

from collections import deque
from collections.abc import Sequence
from pathlib import Path

import click

from collections.abc import Iterator
from pydantic import BaseModel

import time
from functools import wraps


def timethis(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        r = func(*args, **kwargs)
        end = time.perf_counter()
        logger.info("{}.{} : {}".format(func.__module__, func.__name__, end - start))
        return r

    return wrapper


@contextmanager
def timeblock(label: str):
    start = time.perf_counter()
    try:
        yield
    finally:
        end = time.perf_counter()
        logger.info("{} : {}".format(label, end - start))


@click.group()
def cli():
    pass


class Edge(BaseModel):
    depth: int  # depth of stack frame
    caller: Func
    callee: Func


class Func(BaseModel):
    file: str
    module: str | None
    func: str

    def __repr__(self):
        return f"{self.file}:{self.func}"

    def __eq__(self, other):
        return self.file == other.file and self.func == other.func

    def __hash__(self):
        return hash((self.file, self.func))


class Stack(BaseModel):
    funcs: Sequence[Func]

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Stack):
            return False

        return len(self.funcs) == len(other.funcs) and all(
            x == y for x, y in zip(self.funcs, other.funcs)
        )

    def __iter__(self) -> Iterator[Func]:  # type:ignore
        return iter(self.funcs)

    def __len__(self) -> int:
        return len(self.funcs)


class Graph(BaseModel):
    edges: Sequence[Edge]


class ReconstructCallstacks:
    @timethis
    @staticmethod
    def run(trace: Iterable[Edge]) -> Iterable[Stack]:
        stack = deque()
        depths = deque()
        last_callee = None
        for edge in trace:
            depth, caller, callee = edge.depth, edge.caller, edge.callee
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
                yield Stack(funcs=full_stack)

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
            yield Stack(funcs=stack)


def filter_stack(stack: Stack) -> Stack:
    return Stack(
        funcs=[
            Func(file=f.file.removeprefix("/testbed/"), module=f.module, func=f.func)
            for f in stack.funcs
            if "/tests/" not in f.file
            and "/site-packages/" not in f.file
            and "miniconda" not in f.file
            and "/root/trace.py" not in f.file
            and "<frozen importlib" not in f.file
        ]
    )


@logger.catch
def main():
    dev_funcs_map = load_dev_funcs_map()

    task_dirs = list(
        Path("run_instance_swt_logs/assertflip/pred_pre__AssertFlip").glob("*/")
    )

    task_dirs = [
        Path(
            "run_instance_swt_logs/validate-gold/pred_pre__gold/astropy__astropy-12907"
        )
    ]

    task_ids = [t.name for t in task_dirs]
    dev_funcs = [dev_funcs_map[t] for t in task_ids]
    out_dirs = [Path("assertflip_analysis", "fresh_results", t) for t in task_ids]

    with ProcessPoolExecutor(4) as executor:
        executor.map(process_task_dir, task_dirs, out_dirs, dev_funcs)


def load_dev_funcs_map() -> dict[str, set[Func]]:
    with open("assertflip_analysis/norm.dev_locations.jsonl") as f:
        dev_locs_map = ChainMap(*map(json.loads, f))

    def dev_loc_to_func(dev_loc: dict) -> Func:
        if dev_loc["start"] is None:
            func_name = "<module>"
        elif dev_loc["class_name"]:
            func_name = f"{dev_loc['class_name']}.{dev_loc['method_name']}"
        else:
            func_name = dev_loc["method_name"]
        return Func(file=dev_loc["rel_file_path"], module="", func=func_name)

    return {k: set(map(dev_loc_to_func, v)) for k, v in dev_locs_map.items()}


def process_task_dir(task_dir: Path, out_dir: Path, dev_funcs: set[Func]) -> None:
    logger.add(out_dir / "fresh_analysis.log")

    logger.info(dev_funcs)

    test_output_file = task_dir / "test_output.txt"
    if not test_output_file.exists():
        logger.error("test output file not found")
        return

    with open(test_output_file) as f, timeblock("extract graph b64 from log"):
        b64 = extract_graph_b64(f)

    out_dir.mkdir(parents=True, exist_ok=True)
    out_dir.joinpath("graph.b64").write_text(b64)

    process_graph_b64(b64, out_dir, dev_funcs)


def extract_graph_b64(f: TextIOBase) -> str:
    for line in f:
        if "Call stacks json base64:" in line:
            return next(f).rstrip()
    raise RuntimeError("call stack b64 not found in test output")


def process_graph_b64(
    b64_str: str, out_dir: Path, dev_funcs: set[Func] | None = None
) -> None:
    graph = decode_object(b64_str, Graph)
    assert isinstance(graph, Graph)

    # reconstruct stacks from call graph
    stacks = list(ReconstructCallstacks.run(graph.edges))
    logger.info("found {} stacks", len(stacks))

    out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / "stacks.b64l", "w") as f:
        with ProcessPoolExecutor(10) as executor, timeblock("encode stacks"):
            stack_strings = list(executor.map(encode_object, stacks, chunksize=1000))

        with timeblock("write stacks"):
            for s in stack_strings:
                f.write(s)
                f.write("\n")

    # remove irrelevant functions from stacks
    clean_stacks = map(filter_stack, stacks)
    clean_stacks = filter(None, clean_stacks)
    with timeblock("filter stacks"):
        clean_stacks = list(clean_stacks)

    logger.info("found {} clean stacks", len(clean_stacks))

    with open(out_dir / "clean.stacks.b64l", "w") as f:
        with ProcessPoolExecutor(10) as executor, timeblock("encode clean stacks"):
            stack_strings = list(
                executor.map(encode_object, clean_stacks, chunksize=1000)
            )

        for s in stack_strings:
            f.write(s)
            f.write("\n")

    dev_funcs = dev_funcs or set()

    def is_relevant(stack: Stack) -> bool:
        return any(dev_f in stack.funcs for dev_f in dev_funcs)

    relevant_stacks = list(filter(is_relevant, clean_stacks))
    logger.info("found {} relevant clean stacks", len(relevant_stacks))

    with (
        open(out_dir / "relevant.clean.stacks.b64l", "w") as f,
        timeblock("encode & dump relevant stacks"),
    ):
        for stack in relevant_stacks:
            f.write(encode_object(stack))
            f.write("\n")

    with open(out_dir / "relevant.clean.stacks.json", "wb") as f:
        adapter = TypeAdapter(list[Stack])
        f.write(adapter.dump_json(relevant_stacks, indent=4))


def encode_object(model: BaseModel) -> str:
    json_str = model.model_dump_json()
    compressed = gzip.compress(json_str.encode("utf-8"), compresslevel=1)
    b64_str = base64.b64encode(compressed).decode("ascii")
    return b64_str


@timethis
def decode_object(b64_str: str, model_type: type[BaseModel] | None = None):
    compressed = base64.b64decode(b64_str)
    json_bytes = gzip.decompress(compressed)
    if model_type is not None:
        return model_type.model_validate_json(json_bytes.decode("utf-8"))
    else:
        return orjson.loads(json_bytes)


def test_reconstruct_callstacks():
    f, g, h, t, y = (Func(file="foo.py", module="foo", func=name) for name in "fghty")
    trace = [
        Edge(depth=1, caller=f, callee=g),
        Edge(depth=2, caller=g, callee=h),
        Edge(depth=2, caller=g, callee=t),
        Edge(depth=1, caller=f, callee=y),
    ]
    expected_callstacks = [
        Stack(funcs=[f, g, h]),
        Stack(funcs=[f, g, t]),
        Stack(funcs=[f, y]),
    ]
    result = ReconstructCallstacks.run(trace)
    assert list(result) == expected_callstacks


if __name__ == "__main__":
    main()
