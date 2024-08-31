from enum import IntEnum
from pathlib import Path
from openscad_runner import OpenScadRunner
import json
import pytest

HERE = Path(__file__).parent.resolve()
VECTORS = HERE / "vectors"
OUTPUT_VECTORS = HERE.parent.resolve() / "build" / "vectors"


class DrawerFill(IntEnum):
    NO_CUT = 0
    SCOOP_CUT = 1
    SQUARE_CUT = 2


def vector_file(name: str) -> Path:
    return VECTORS / f"{name}.scad"


def output_file(name: str) -> Path:
    return OUTPUT_VECTORS / f"{name}.png"


def vector_runner(name: str, parameters: dict[str, str]) -> OpenScadRunner:
    output_suffix = ",".join([f"{key}={value}" for key, value in sorted(parameters.items())])
    return OpenScadRunner(
        scriptfile=str(vector_file(name)),
        outfile=str(output_file(f"{name}-{output_suffix}")),
        hard_warnings=True,
        verbose=True,
        set_vars=parameters,
    )


def report_and_assert(runner: OpenScadRunner, should_succeed: bool):
    print(f"Command:\n{runner.cmdline}")
    print("------------------------------------------------------------------------")
    print(f"Return code:\n{runner.return_code}")
    print("------------------------------------------------------------------------")
    print(f"Warnings:\n{"\n".join(runner.warnings)}")
    print("------------------------------------------------------------------------")
    print(f"Errors:\n{"\n".join(runner.errors)}")
    print("------------------------------------------------------------------------")
    print(f"Echos:\n{"\n".join(runner.echos)}")
    assert(runner.good() is should_succeed)
