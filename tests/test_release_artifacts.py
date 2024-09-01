import pytest
from . import report, vector_runner, CabinetBases, CabinetTops, ScrewfinityStandardDrawerHeights


def small_cabinets():
    """
    https://thangs.com/designer/ZombieHedgehog/3d-model/Screwfinity%20Unit%202U%20Small%20-%20The%20Gridfinity%20Storage%20Unit-1046954
    """
    for width in [2, 3, 4, 5, 6]:
        for rows in [2, 3, 4]:
            yield pytest.param(
                width,
                2,
                1,
                ScrewfinityStandardDrawerHeights.SMALL,
                rows,
                id=f"Screwfinity SMALL 2U {rows}x{width}",
            )


def medium_cabinets():
    """
    https://thangs.com/designer/ZombieHedgehog/3d-model/Screwfinity%20Unit%202U%20Medium%20-%20The%20Gridfinity%20Storage%20Unit-1027305
    """
    def medium_param(width, rows):
        return pytest.param(
            width,
            2,
            1,
            ScrewfinityStandardDrawerHeights.MEDIUM,
            rows,
            id=f"Screwfinity MEDIUM 2U {rows}x{width}",
        )

    for width in [2, 3, 4, 5, 6]:
        for rows in [2, 3, 4, 5, 6, 7]:
            yield medium_param(width, rows)
    
    # honestly not sure who this is for,
    # but it's in the upstream artifacts,
    # so ok ¯\_(ツ)_/¯
    yield medium_param(width=18, rows=24)


def medium_wide_cabinets():
    """
    https://thangs.com/designer/ZombieHedgehog/3d-model/Screwfinity%20Unit%202U%20Medium%20WIDE%20-%20The%20Gridfinity%20Storage%20Unit-1034369
    """
    for width in [2, 4, 6]:
        for rows in [2, 3, 4]:
            yield pytest.param(
                width,
                2,
                2,
                ScrewfinityStandardDrawerHeights.MEDIUM,
                rows,
                id=f"Screwfinity MEDIUM WIDE 2U {rows}x{width}",
            )


def large_cabinets():
    """
    https://thangs.com/designer/ZombieHedgehog/3d-model/Screwfinity%20Unit%202U%20Large%20-%20The%20FREE%20Gridfinity%20Storage%20Unit-1081351
    """
    for width in [2, 3, 4, 5]:
        for rows in [2, 3, 4, 5]:
            yield pytest.param(
                width,
                2,
                1,
                ScrewfinityStandardDrawerHeights.LARGE,
                rows,
                id=f"Screwfinity LARGE 2U {rows}x{width}",
            )


def medium_wide_4u_cabinets():
    """
    https://thangs.com/designer/Myrmecodia/3d-model/Screwfinity%20Medium%20Wide%204U%20drawer%20set-1097859
    """
    for width in [4]:
        for rows in [4, 6]:
            yield pytest.param(
                width,
                4,
                2,
                ScrewfinityStandardDrawerHeights.MEDIUM,
                rows,
                id=f"Screwfinity MEDIUM WIDE 4U {rows}x{width}",
            )


def screwfinity_cabinets():
    yield from small_cabinets()
    yield from medium_cabinets()
    yield from medium_wide_cabinets()
    yield from large_cabinets()
    yield from medium_wide_4u_cabinets()


@pytest.mark.compatibility
@pytest.mark.parametrize("width, depth, drawer_width, drawer_height, rows", screwfinity_cabinets())
@pytest.mark.parametrize("top", [pytest.param(i, id=f"top={i.name}") for i in [
    CabinetTops.LIP_TOP,
    CabinetTops.GRIDFINITY_STACKING_TOP,
    CabinetTops.GRIDFINITY_BASEPLATE_MAGNET_TOP,
]])
def test_screwfinity_cabinets(request, width, depth, drawer_width, drawer_height, rows, top):
    runner = vector_runner(
        name="screwfinity-cabinet",
        parameters={
            "unit_width": width,
            "unit_depth": depth,
            "drawer_unit_width": drawer_width,
            "drawer_height": drawer_height,
            "rows": rows,
            "base_style": CabinetBases.GRIDFINITY_BASE,
            "top_style": top,
        },
        output_suffix=request.node.callspec.id,
        extension="stl",
    )
    runner.run()
    report(runner)
    assert(runner.good())
