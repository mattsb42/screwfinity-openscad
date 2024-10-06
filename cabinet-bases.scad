include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-utility.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-holes.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-baseplate.scad>;
include <./gridfinity-rebuilt-openscad/standard.scad>;

module GridFinityBase(gridfinity_footprint, hole_options) {
    translate([0, 0, 0 - h_base]) 
    color("red")
        gridfinityBase(
            gx=gridfinity_footprint.x,
            gy=gridfinity_footprint.y,
            l=GRIDFINITY_GRID_LENGTH,
            dx=0,
            dy=0,
            hole_options=hole_options
        );
}

module CabinetBase(gridfinity_footprint, style, hole_options) {
    if(style == GRIDFINITY_BASE) GridFinityBase(gridfinity_footprint, hole_options);
}
