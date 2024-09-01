include <../../options.scad>;
use <../../cabinet.scad>;
$fa = 1;
$fs = 0.4;

Cabinet(
    gridfinity_footprint=[5, 3],
    grid=[
        drawer_slot_options(unit_width=.75, height=SMALL),
        drawer_slot_options(unit_width=5, height=MEDIUM),
        drawer_slot_options(unit_width=2, height=10),
        drawer_slot_options(unit_width=0.5, height=LARGE),
    ],
    top=surface_options(style=GRIDFINITY_BASEPLATE_MAGNET_TOP),
    base=surface_options(style=GRIDFINITY_BASE)
);
