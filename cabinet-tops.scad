include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-holes.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-baseplate.scad>;
include <./gridfinity-rebuilt-openscad/standard.scad>;

module CabinetTop(gridfinity_footprint, outer_footprint, style) {
    if(style == LIP_TOP) LipTop(outer_footprint);
    else if(style == GRIDFINITY_STACKING_TOP) GridFinityStackingLip(gridfinity_footprint, outer_footprint);
    else if(style == GRIDFINITY_BASEPLATE_MAGNET_TOP) GridFinityMagnetBaseplateLip(gridfinity_footprint, outer_footprint);
}

module LipTop(outer_footprint) {
    cross_section = [2, 4];
    translate([0, 0, (cross_section.y / 2)]) {
        // add a rim around the lip; the lip by itself is too thin at the edge
        outer_buffer_width = 0.25;
        color("blue")
        difference() {
            cube([outer_footprint.x, outer_footprint.y, cross_section.y], center=true);
            // make the cut-out cube taller to remove render preview artifacts
            cube([outer_footprint.x - outer_buffer_width, outer_footprint.y - outer_buffer_width, cross_section.y + 1], center=true);
        }
        // add the lip
        color("green")
            Lip(
                footprint=[outer_footprint.x - outer_buffer_width, outer_footprint.y - outer_buffer_width],
                cross_section=cross_section,
                center=true
            );
    }
}

module GridFinityStackingLip(gridfinity_footprint, outer_footprint) {
    // There's an extra 1mm offset somewhere (haven't pinned down where it comes from)
    //  and add an extra micrometer to remove render artifacts.
    actual_offset = h_base + 1.001;
    translate([0, 0, 0 - actual_offset]) {
        difference() {
            gridfinityInit(gx = gridfinity_footprint.x, gy = gridfinity_footprint.y, h = 1);
            translate([-1 * outer_footprint.x / 2, -1 * outer_footprint.y / 2, 0])
                cube([outer_footprint.x, outer_footprint.y, actual_offset]);
        }
    }
}

module GridFinityMagnetBaseplateLip(gridfinity_footprint, outer_footprint) {
    // offset one micrometer above the bottom of the magnet hole
    offset = 4.361;
    translate([0, 0, 0 - offset]) {
        difference() {
            gridfinityBaseplate(
                grid_size_bases=gridfinity_footprint,
                length=GRIDFINITY_GRID_LENGTH,
                min_size_mm = [0,0],
                sp=2,
                hole_options=bundle_hole_options(
                    magnet_hole=true,
                    crush_ribs=true
                ),
                sh=0
            );
            translate([-1 * outer_footprint.x / 2 - 1, -1 * outer_footprint.y / 2 - 1, -1])
                cube([outer_footprint.x + 2, outer_footprint.y + 2, offset + 1]);
        }
    }
}

