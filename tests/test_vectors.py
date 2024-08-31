from pathlib import Path
from typing import Iterable
from openscad_runner import OpenScadRunner
import pytest
from . import vector_file, output_file, vector_runner, DrawerFill


@pytest.mark.parametrize(
        "width, depth, height",
        [
            pytest.param(-1, 1, 10, id="negative width"),
            pytest.param(1, -1, 10, id="negative depth"),
            pytest.param(1, 1, -10, id="negative height"),
            pytest.param(1, 1.5, 10, id="non-integer depth"),
            # maybe break out too-narrow drawers into their own broader test case later
            pytest.param(0.1, 1, 10, id="width too narrow"),
        ],
)
def test_drawer_invalid_dimensions(width, depth, height):
    runner = vector_runner(
        name="drawer",
        parameters={
            "unit_width": width,
            "unit_depth": depth,
            "height": height,
            "wall_thickness": 1,
        },
    )
    runner.run()
    assert(not runner.good())


def test_drawer_invalid_fill_type():
    runner = vector_runner(
        name="drawer",
        parameters={
            "fill_type": -1,
        },
    )
    runner.run()
    assert(not runner.good())


@pytest.mark.parametrize("fill_type", [pytest.param(i, id=f"fill_type={i}") for i in DrawerFill])
@pytest.mark.parametrize("width", [pytest.param(i, id=f"width={i}") for i in [0.5, 1, 2, 3]])
@pytest.mark.parametrize("depth", [pytest.param(i, id=f"depth={i}") for i in [1, 2, 3]])
@pytest.mark.parametrize("height", [pytest.param(i, id=f"height={i}") for i in [10, 20, 30]])
@pytest.mark.parametrize("wall", [pytest.param(i, id=f"wall={i}") for i in [0.5, 1, 2]])
def test_drawer(fill_type, width, depth, height, wall):
    runner = vector_runner(
        name="drawer",
        parameters={
            "fill_type": fill_type,
            "unit_width": width,
            "unit_depth": depth,
            "height": height,
            "wall_thickness": wall,
        },
    )
    runner.run()
    assert(runner.good())

# execute all the examples

# cabinet width
# cabinet depth
# cabinet row combinations
# cabinet top
# cabinet base
