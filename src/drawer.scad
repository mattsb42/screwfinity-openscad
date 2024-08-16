include <./constants.scad>;
include <./options.scad>;
use <./MCAD/boxes.scad>;

module Drawer(height, drawer_wall=1, u_width=1, u_depth=2, fill_type=SQUARE_CUT) {

    assert(
        u_depth % 1 == 0,
        str(
            "ERROR: Invalid u_depth value ",
            u_depth,
            " must be an integer."
        )
    );

    assert(
        fill_type == NO_FILL || fill_type == SQUARE_CUT || fill_type == SCOOP_CUT,
        str(
            "ERROR: Invalid fill type ",
            fill_type
        )
    );

    outside_height = height;
    inside_height = height - drawer_wall;
    outside_width = (u_width * DRAWER_UNIT_SLOT_WIDTH) - (DRAWER_TOLERANCE * 2);
    inside_width = outside_width - (2 * drawer_wall);
    outside_depth = (u_depth * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP;
    inside_depth = outside_depth - (2 * drawer_wall);

    module Body()
        roundedCube(size=[outside_width, outside_depth, outside_height], r=drawer_wall, sidesonly=true, center=true);

    module SquareCutoutRear() {
        translate([0, -1 * inside_depth / 4, 0])
            roundedCube(size=[inside_width, inside_depth / 2, inside_height], r=drawer_wall, sidesonly=true, center=true);
    }

    module SquareCutoutFront() {
        translate([0, inside_depth / 4, 0])
            roundedCube(size=[inside_width, inside_depth / 2, inside_height], r=drawer_wall, sidesonly=true, center=true);
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
                translate([0, (inside_depth / 2) - inside_height, inside_height / 2])
                    rotate([0, 90, 0])
                        cylinder(h=inside_width, r=inside_height, center=true);
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
        edge = [outside_width / 2 - drawer_wall, drawer_wall * 2, outside_height / 2];

        module TopLeft() translate([edge[0], 0, edge[2]]) sphere(r=drawer_wall);
        module TopRight() translate([-1 * edge[0], 0, edge[2]]) sphere(r=drawer_wall);
        module UpperLipLeft() translate([edge[0], edge[1], edge[2]]) sphere(r=drawer_wall);
        module UpperLipRight() translate([-1 * edge[0], edge[1], edge[2]]) sphere(r=drawer_wall);
        module BottomLeft() translate([edge[0], 0, (-1 * edge[2]) + drawer_wall]) sphere(r=drawer_wall);
        module BottomRight() translate([-1 * edge[0], 0, (-1 * edge[2]) + drawer_wall]) sphere(r=drawer_wall);
        module OuterLipLeft() translate([edge[0], handle_lip, 0]) sphere(r=drawer_wall);
        module OuterLipRight() translate([-1 * edge[0], handle_lip, 0]) sphere(r=drawer_wall);
        module InnerLipLeft() translate([edge[0] - handle_support_width, 0, 0]) sphere(r=drawer_wall);
        module InnerLipRight() translate([-1  * (edge[0] - handle_support_width), 0, 0]) sphere(r=drawer_wall);

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
            translate([0, outside_depth / 2 - drawer_wall, 0])
                Handle();
        }
        translate([0, 0, (drawer_wall / 2)]) {
            if (fill_type == SQUARE_CUT) SquareCutout();
            else if (fill_type == SCOOP_CUT) ScoopCutout();
        }
        // slice off everything above the top
        translate([0, 0, (outside_height / 2) + (drawer_wall / 2) + 0.001])
            cube([outside_width * 2, outside_depth *2, drawer_wall + 0.003], center=true);
    }
}
