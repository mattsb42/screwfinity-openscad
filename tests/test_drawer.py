import pytest
from . import assert_error_present, report, vector_runner, DrawerFill, DrawerHandleLabelCut

GOOD_WIDTHS = [0.5, 1, 2, 3]
GOOD_DEPTHS = [1, 2, 3]
GOOD_HEIGHTS = [10, 20, 30]
GOOD_WALLS = [0.5, 1, 2]


@pytest.mark.parametrize("label_cut", [pytest.param(i, id=f"label_cut={i.name}") for i in DrawerHandleLabelCut])
@pytest.mark.parametrize("fill_type", [pytest.param(i, id=f"fill_type={i.name}") for i in DrawerFill])
@pytest.mark.parametrize("width", [pytest.param(i, id=f"width={i}") for i in GOOD_WIDTHS])
@pytest.mark.parametrize("depth", [pytest.param(i, id=f"depth={i}") for i in GOOD_DEPTHS])
@pytest.mark.parametrize("height", [pytest.param(i, id=f"height={i}") for i in GOOD_HEIGHTS])
@pytest.mark.parametrize("wall", [pytest.param(i, id=f"wall={i}") for i in GOOD_WALLS])
def test_drawer(label_cut, fill_type, width, depth, height, wall):
    runner = vector_runner(
        name="drawer",
        parameters={
            "label_cut": label_cut,
            "fill_type": fill_type,
            "unit_width": width,
            "unit_depth": depth,
            "height": height,
            "wall_thickness": wall,
        },
    )
    runner.run()
    report(runner)
    assert(runner.good())


@pytest.mark.parametrize(
        "width, depth, height, error_message",
        [
            pytest.param(-1, 1, 10, "Invalid width value", id="negative width"),
            pytest.param(1, -1, 10, "Invalid unit depth value", id="negative depth"),
            pytest.param(1, 1, -10, "Invalid height value", id="negative height"),
            pytest.param(1, 1.5, 10, "Invalid unit depth value", id="non-integer depth"),
            # maybe break out too-narrow drawers into their own broader test case later
            pytest.param(0.1, 1, 10, "Drawer width is too narrow", id="width too narrow"),
        ],
)
def test_drawer_invalid_dimensions(width, depth, height, error_message):
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
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, error_message)


def test_drawer_invalid_fill_type():
    runner = vector_runner(
        name="drawer",
        parameters={
            "fill_type": -1,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid cell cut type")


def test_invalid_label_cut():
    runner = vector_runner(
        name="drawer",
        parameters={
            "label_cut": -1,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid label cut type")


def test_invalid_handle_style():
    runner = vector_runner(
        name="drawer",
        parameters={
            "handle_style": -1,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid handle style")


def test_invalid_handle_depth():
    runner = vector_runner(
        name="drawer",
        parameters={
            "handle_depth": -1,
        },
    )
    runner.run()
    report(runner)
    assert(not runner.good())
    assert_error_present(runner, "Invalid handle depth")
