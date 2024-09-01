import pytest
from . import assert_error_present, report, vector_runner, CabinetBases, CabinetTops

GOOD_WIDTHS = [1, 2, 3, 4]
GOOD_DEPTHS = [1, 2, 3]
GOOD_DRAWER_WIDTHS = [0.5, 1, 2, 3]
GOOD_DRAWER_HEIGHTS = [10, 20, 30]
GOOD_ROWS = [1, 2, 3]


def good_cabinet_and_drawer_widths():
    for width in GOOD_WIDTHS:
        for drawer_width in GOOD_DRAWER_WIDTHS:
            if drawer_width <= width:
                yield pytest.param(width, drawer_width, id=f"width={width}-drawer_width={drawer_width}")



@pytest.mark.parametrize("depth", [pytest.param(i, id=f"depth={i}") for i in GOOD_DEPTHS])
@pytest.mark.parametrize("width, drawer_width", good_cabinet_and_drawer_widths())
@pytest.mark.parametrize("drawer_height", [pytest.param(i, id=f"drawer_height={i}") for i in GOOD_DRAWER_HEIGHTS])
@pytest.mark.parametrize("rows", [pytest.param(i, id=f"rows={i}") for i in GOOD_ROWS])
def test_grid_expand(width, depth, drawer_width, drawer_height, rows):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "unit_width": width,
            "unit_depth": depth,
            "drawer_unit_width": drawer_width,
            "drawer_height": drawer_height,
            "rows": rows,
        },
    )
    runner.run()
    report(runner)
    assert(runner.good())


@pytest.mark.parametrize("top", [pytest.param(i, id=f"top={i}") for i in CabinetTops])
def test_top_styles(top):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "top_style": top,
        },
    )
    runner.run()
    report(runner)
    assert(runner.good())


@pytest.mark.parametrize("base", [pytest.param(i, id=f"base={i}") for i in CabinetBases])
def test_base_styles(base):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "base_style": base,
        },
    )
    runner.run()
    report(runner)
    assert(runner.good())


@pytest.mark.parametrize("width", [pytest.param(i, id=f"width={i}") for i in [0.1, 1.5]])
@pytest.mark.parametrize("depth", [pytest.param(i, id=f"depth={i}") for i in [0.1, 1.5]])
def test_invalid_footprint(width, depth):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "unit_width": width,
            "unit_depth": depth,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid gridfinity_footprint")


@pytest.mark.parametrize("width, drawer_width", [
    pytest.param(i, j, id=f"width={i}-drawer_width={j}")  for i, j in [
        [1, 2],
        [3, 8],
    ]
])
def test_invalid_width_combinations(width, drawer_width):
    """Drawer width MUST NOT be wider than cabinet width"""
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "unit_width": width,
            "drawer_unit_width": drawer_width,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid drawer and cabinet width selection")


@pytest.mark.parametrize("base", [pytest.param(i, id=f"base={i}") for i in [-1, 10]])
def test_invalid_base_style(base):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "base_style": base,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid base style")


@pytest.mark.parametrize("top", [pytest.param(i, id=f"top={i}") for i in [-1, 10]])
def test_invalid_top_style(top):
    runner = vector_runner(
        name="cabinet-grid-expand",
        parameters={
            "top_style": top,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid top style")

# cabinet row combinations
