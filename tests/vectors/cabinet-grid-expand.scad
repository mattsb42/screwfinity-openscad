include <../../options.scad>;
use <../../cabinet.scad>;
$fa = 1;
$fs = 0.4;

unit_width = 1;
unit_depth = 1;
drawer_unit_width = 1;
drawer_height = 10;
rows = 1;
// use no top/base for the baseline to dramatically speed up test run time
top_style = NO_TOP;
base_style = NO_BASE;

Cabinet(
    gridfinity_footprint=[unit_width, unit_depth],
    grid=grid_expand(
        drawer=drawer_slot_options(
            unit_width=drawer_unit_width,
            height=drawer_height
        ),
        rows=rows
    ),
    top=surface_options(style=top_style),
    base=surface_options(style=base_style)
);
