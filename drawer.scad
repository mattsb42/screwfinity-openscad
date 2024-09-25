include <./constants.scad>;
include <./options.scad>;
include <./drawer-handles.scad>;
use <./util.scad>;
use <./MCAD/boxes.scad>;

// distance from outer edge of drawer to start of label slot
LABEL_SLOT_OFFSET = 1.5;
LABEL_SLOT_CUT_RADIUS = 0.5;
// leave 0.2mm tolerance on each side for smooth operation
LABEL_THICKNESS = (LABEL_SLOT_CUT_RADIUS * 2) - 0.4;
// distance from face to label slot
LABEL_SLOT_FACE_OFFSET = 0.5;
// distance from front face of drawer to outer edge of handle
DEFAULT_HANDLE_DEPTH = 8;

function drawer_options (unit_width, unit_depth, height) = [unit_width, unit_depth, height];

function bundle_handle_options (style=TRIANGLE_HANDLE, depth=DEFAULT_HANDLE_DEPTH) = [style, depth];

function drawer_outside_dimensions(dimensions) = [
    (dimensions.x * GRIDFINITY_GRID_LENGTH) - GU_TO_DU - (DRAWER_TOLERANCE * 2),
    (dimensions.y * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP,
    dimensions.z,
];

module Drawer(dimensions, drawer_wall=1, fill_type=SQUARE_CUT, label_cut=NO_LABEL_CUT, handle_options=bundle_handle_options()) {


    minimum_interior_width = 0.1;
    body_chamfer = 1;

    assert(
        dimensions.x > 0 && dimensions.y > 0 && dimensions.z > 0,
        str(
            "ERROR: All dimensions MUST be positive. ",
            dimensions
        )
    );

    assert(
        dimensions.y % 1 == 0,
        str(
            "ERROR: Invalid unit_depth value ",
            dimensions.y,
            " must be an integer."
        )
    );

    assert(
        fill_type == NO_CUT || fill_type == SQUARE_CUT || fill_type == SCOOP_CUT,
        str(
            "ERROR: Invalid fill type ",
            fill_type
        )
    );

    assert(
        label_cut == NO_LABEL_CUT || label_cut == LABEL_CUT,
        str(
            "ERROR: Invalid label cut type",
            label_cut
        )
    );

    assert(
        len(handle_options) == 2,
        str(
            "ERROR: Invalid handle options length",
            len(handle_options)
        )
    );

    handle_style = handle_options[0];
    assert(
        handle_style == TRIANGLE_HANDLE,
        str(
            "ERROR: Invalid handle style",
            handle_style
        )
    );

    handle_depth = handle_options[1];
    assert(
        handle_depth > 0,
        str(
            "ERROR: Invalid handle depth",
            handle_depth
        )
    );

    outside_dimensions = drawer_outside_dimensions(dimensions);
    inside = [
        outside_dimensions.x - (2 * drawer_wall),
        outside_dimensions.y - (2 * drawer_wall),
        outside_dimensions.z - drawer_wall
    ];

    assert(
        inside.x >= minimum_interior_width,
        str(
            "ERROR: Drawer width is too narrow.",
            " With unit width ", dimensions.x,
            " and drawer wall thickness ", drawer_wall,
            " the drawer interior width is ", inside.x, ".",
            " Recommend reducing drawer width to no more than ",
            (outside_dimensions.x - minimum_interior_width) / 2
        )
    );

    module Body() {
        difference() {
            roundedCube(size=[outside_dimensions.x, outside_dimensions.y, outside_dimensions.z], r=body_chamfer, sidesonly=true, center=true);
            // chamfer
            translate([-1 * outside_dimensions.x / 2, -1 * outside_dimensions.y / 2, -1 * outside_dimensions.z / 2])
                Lip(footprint=outside_dimensions, cross_section=[CHAMFER_HEIGHT, CHAMFER_HEIGHT]);
        }
    }

    module SquareCutoutRear() {
        translate([0, -1 * inside.y / 4, 0])
            roundedCube(size=[inside.x, inside.y / 2, inside.z], r=body_chamfer, sidesonly=true, center=true);
    }

    module SquareCutoutFront() {
        translate([0, inside.y / 4, 0])
            roundedCube(size=[inside.x, inside.y / 2, inside.z], r=body_chamfer, sidesonly=true, center=true);
    }

    module SquareCutout() {
        hull() {
            SquareCutoutFront();
            SquareCutoutRear();       
        }
    }

    module ScoopCutout() {
        module Scoop() {
            intersection() {
                translate([0, (inside.y / 2) - inside.z, inside.z / 2])
                    rotate([0, 90, 0])
                        cylinder(h=inside.x, r=inside.z, center=true);
                SquareCutoutFront();
            }
        }
        hull() {
            Scoop();
            SquareCutoutRear();
        }
    }

    // block out the edges of the side walls to slice off any overhangs
    module SideWallSlice() {
        // add a tiny slice to intersect with the wall and avoid rendering artifacts
        buffer = 0.00005;
        translate([(outside_dimensions.x / 2) + 5 - buffer, 0, 0])
            cube([10, outside_dimensions.y * 2, outside_dimensions.z * 2], center=true);
        translate([-1 * (outside_dimensions.x / 2) - 5 + buffer, 0, 0])
            cube([10, outside_dimensions.y * 2, outside_dimensions.z * 2], center=true);
    }

    difference() {
        union() {
            Body();
            translate([0, (outside_dimensions.y / 2) - HANDLE_WALL, 0])
                TriangleHandle(
                    drawer_outside_dimensions=outside_dimensions,
                    label_cut=label_cut,
                    handle_depth=handle_depth
                );
        }
        translate([0, 0, (drawer_wall / 2)]) {
            if (fill_type == SQUARE_CUT) SquareCutout();
            else if (fill_type == SCOOP_CUT) ScoopCutout();
        }
        SideWallSlice();
        // slice off everything above the top
        translate([0, 0, (outside_dimensions.z / 2) + (drawer_wall) + 0.001])
            cube([outside_dimensions.x * 2, outside_dimensions.y *2, (drawer_wall * 2) + 0.003], center=true);
    }
}


module Label(drawer_unit_dimensions, handle_depth=DEFAULT_HANDLE_DEPTH) {
    assert(
        drawer_unit_dimensions.x > 0 && drawer_unit_dimensions.y > 0 && drawer_unit_dimensions.z > 0,
        str(
            "ERROR: All dimensions MUST be positive. ",
            drawer_unit_dimensions
        )
    );

    assert(
        handle_depth > 0,
        str(
            "ERROR: Handle depth MUST be positive",
            handle_depth
        )
    );

    drawer_dimensions = drawer_outside_dimensions(drawer_unit_dimensions);
    label_slot_y_offset = handle_depth - LABEL_SLOT_FACE_OFFSET;

    label_dimensions = [
        drawer_dimensions.x - (2 * (HANDLE_WALL + LABEL_SLOT_OFFSET)),
        sqrt(pow(label_slot_y_offset, 2) + pow(drawer_dimensions.z / 2, 2)) - LABEL_SLOT_CUT_RADIUS,
        LABEL_THICKNESS,
    ];

    cube(label_dimensions, center=true);
}
