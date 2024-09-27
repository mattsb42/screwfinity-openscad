include <../../options.scad>;
use <../../drawer.scad>;
$fa = 1;
$fs = 0.4;

unit_width = 1;
unit_depth = 2;
height = 10;
wall_thickness = 1;
fill_type = SQUARE_CUT;
label_cut = LABEL_CUT;


Drawer(
    dimensions=drawer_options(
        unit_width=unit_width,
        unit_depth=unit_depth,
        height=height
    ),
    drawer_wall=wall_thickness,
    fill_type=fill_type,
    handle_properties=handle_properties(
        label_cut=label_cut
    )
);
