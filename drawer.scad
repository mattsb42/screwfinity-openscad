include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./MCAD/boxes.scad>;

function drawer_options (unit_width, unit_depth, height) = [unit_width, unit_depth, height];

module Drawer(dimensions, drawer_wall=1, fill_type=SQUARE_CUT) {

    minimum_interior_width = 0.1;

    assert(
        dimensions.x > 0 && dimensions.y > 0 && dimensions.z > 0,
        str(
            "ERROR: All dimensions MUST be positive. ",
            dimensions
        )
    )

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

    outside = [
        (dimensions.x * GRIDFINITY_GRID_LENGTH) - GU_TO_DU - (DRAWER_TOLERANCE * 2),
        (dimensions.y * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP,
        dimensions.z,
    ];
    inside = [
        outside.x - (2 * drawer_wall),
        outside.y - (2 * drawer_wall),
        outside.z - drawer_wall
    ];

    assert(
        inside.x >= minimum_interior_width,
        str(
            "ERROR: Drawer width is too narrow.",
            " With unit width ", dimension.x,
            " and drawer wall thickness ", drawer_wall,
            " the drawer interior width is ", inside.x, ".",
            " Recommend reducing drawer width to no more than ",
            (outside.x - minimum_interior_width) / 2
        )
    );

    module Body() {
        difference() {
            roundedCube(size=[outside.x, outside.y, outside.z], r=drawer_wall, sidesonly=true, center=true);
            // chamfer
            translate([-1 * outside.x / 2, -1 * outside.y / 2, -1 * outside.z / 2])
                Lip(footprint=outside, cross_section=[CHAMFER_HEIGHT, CHAMFER_HEIGHT]);
        }
    }

    module SquareCutoutRear() {
        translate([0, -1 * inside.y / 4, 0])
            roundedCube(size=[inside.x, inside.y / 2, inside.z], r=drawer_wall, sidesonly=true, center=true);
    }

    module SquareCutoutFront() {
        translate([0, inside.y / 4, 0])
            roundedCube(size=[inside.x, inside.y / 2, inside.z], r=drawer_wall, sidesonly=true, center=true);
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

    module Handle() {
        handle_lip = 8;
        handle_support_width = 10;
        edge = [outside.x / 2 - drawer_wall, drawer_wall * 2, outside.z / 2];

        module TopLeft() translate([edge.x, 0, edge.z]) sphere(r=drawer_wall);
        module TopRight() translate([-1 * edge.x, 0, edge.z]) sphere(r=drawer_wall);
        module UpperLipLeft() translate([edge.x, edge.y, edge.z]) sphere(r=drawer_wall);
        module UpperLipRight() translate([-1 * edge.x, edge.y, edge.z]) sphere(r=drawer_wall);
        module BottomLeft() translate([edge.x, 0, (-1 * edge.z) + drawer_wall]) sphere(r=drawer_wall);
        module BottomRight() translate([-1 * edge.x, 0, (-1 * edge.z) + drawer_wall]) sphere(r=drawer_wall);
        module OuterLipLeft() translate([edge.x, handle_lip, 0]) sphere(r=drawer_wall);
        module OuterLipRight() translate([-1 * edge.x, handle_lip, 0]) sphere(r=drawer_wall);
        module InnerLipLeft() translate([edge.x - handle_support_width, 0, 0]) sphere(r=drawer_wall);
        module InnerLipRight() translate([-1  * (edge.x - handle_support_width), 0, 0]) sphere(r=drawer_wall);

        module LeftBase() {
            hull() {
                TopLeft();
                BottomLeft();
                OuterLipLeft();
                InnerLipLeft();
            }
        }

        module RightBase() {
            hull() {
                TopRight();
                BottomRight();
                OuterLipRight();
                InnerLipRight();
            }
        }

        module Face() {
            hull() {
                TopRight();
                TopLeft();
                UpperLipLeft();
                UpperLipRight();
                OuterLipRight();
                OuterLipLeft();
            }
        }

        LeftBase();
        RightBase();
        Face();
    }

    difference() {
        union() {
            Body();
            translate([0, outside.y / 2 - drawer_wall, 0])
                Handle();
        }
        translate([0, 0, (drawer_wall / 2)]) {
            if (fill_type == SQUARE_CUT) SquareCutout();
            else if (fill_type == SCOOP_CUT) ScoopCutout();
        }
        // slice off everything above the top
        translate([0, 0, (outside.z / 2) + (drawer_wall / 2) + 0.001])
            cube([outside.x * 2, outside.y *2, drawer_wall + 0.003], center=true);
    }
}
