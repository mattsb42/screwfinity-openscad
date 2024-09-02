from enum import IntEnum
from pathlib import Path
from typing import Optional
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


class DrawerHandleLabelCut(IntEnum):
    NO_LABEL_CUT = 0
    LABEL_CUT = 1


class CabinetBases(IntEnum):
    NO_BASE = 0
    GRIDFINITY_BASE = 1


class CabinetTops(IntEnum):
    NO_TOP = 0
    LIP_TOP = 1
    GRIDFINITY_STACKING_TOP = 2
    GRIDFINITY_BASEPLATE_MAGNET_TOP = 3


class ScrewfinityStandardDrawerHeights(IntEnum):
    SMALL = 20
    MEDIUM = 30
    LARGE = 40


def vector_file(name: str) -> Path:
    return VECTORS / f"{name}.scad"


def output_file(name: str, extension: str) -> Path:
    return OUTPUT_VECTORS / f"{name}.{extension}"


def vector_runner(name: str, parameters: dict[str, str], output_suffix: Optional[str]=None, extension: str="png", camera: Optional[list[int]]=None) -> OpenScadRunner:
    OUTPUT_VECTORS.mkdir(parents=True, exist_ok=True)
    if output_suffix is None:
        output_suffix = ",".join([f"{key}={value}" for key, value in sorted(parameters.items())])
    return OpenScadRunner(
        scriptfile=str(vector_file(name)),
        outfile=str(output_file(f"{name}-{output_suffix}", extension)),
        hard_warnings=True,
        verbose=True,
        set_vars=parameters,
        camera=camera,
        auto_center=True,
    )


def report(runner: OpenScadRunner):
    print(f"Command:\n{runner.cmdline}")
    print("------------------------------------------------------------------------")
    print(f"Return code:\n{runner.return_code}")
    print("------------------------------------------------------------------------")
    print(f"Warnings:\n{"\n".join(runner.warnings)}")
    print("------------------------------------------------------------------------")
    print(f"Errors:\n{"\n".join(runner.errors)}")
    print("------------------------------------------------------------------------")
    print(f"Echos:\n{"\n".join(runner.echos)}")
    print("------------------------------------------------------------------------")
    print(f"stdout:\n{"\n".join(runner.stdout)}")
    print("------------------------------------------------------------------------")
    print(f"stderr:\n{"\n".join(runner.stderr)}")


def assert_error_present(runner: OpenScadRunner, error_message: str):
    assert(any([f"ERROR: {error_message}" in line for line in runner.errors]))
