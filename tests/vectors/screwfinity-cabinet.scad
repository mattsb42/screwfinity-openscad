/* Vector file used to generate
 * 'standard' compatible artifact set for releases.
 */
include <../../options.scad>;
use <../../cabinet.scad>;
$fa = 1;
$fs = 0.4;

unit_width = 2;
unit_depth = 2;
drawer_unit_width = 1;
drawer_height = SMALL;
rows = 2;
top_style = NO_TOP;
base_style = NO_BASE;
label_cut = LABEL_CUT;

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
    base=surface_options(style=base_style),
    label_cut=label_cut
);
