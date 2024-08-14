include <./constants.scad>;
use <./MCAD/boxes.scad>;
$fa=1;
$fs=0.4;

module Drawer(height, drawer_wall=1, u_width=1, u_depth=2) {
    outside_height = height;
    inside_height = height - drawer_wall;
    outside_width = (u_width * DRAWER_UNIT_SLOT_WIDTH) - (DRAWER_TOLERANCE * 2);
    inside_width = outside_width - (2 * drawer_wall);
    outside_depth = (u_depth * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP;
    inside_depth = outside_depth - (2 * drawer_wall);

    module Body()
        roundedCube(size=[outside_width, outside_depth, outside_height], r=drawer_wall, sidesonly=true, center=true);

    module InnerBodySquare()
        roundedCube(size=[inside_width, inside_depth, inside_height], r=drawer_wall, sidesonly=true, center=true);

    module Handle() {
        handle_lip = 8;
        handle_support_width = 10;
        edge = [outside_width / 2 - drawer_wall, 0, outside_height / 2];

        module TopLeft() translate([edge[0], 0, edge[2]]) sphere(r=drawer_wall);
        module TopRight() translate([-1 * edge[0], 0, edge[2]]) sphere(r=drawer_wall);
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
                OuterLipRight();
                OuterLipLeft();
            }
        }

        module HandleBody() {
            LeftBase();
            RightBase();
            Face();
        }

        // move to front of drawer
        translate([0, outside_depth / 2 - drawer_wall, 0]){
            HandleBody();
        }
    }

    difference() {
        union() {
            Body();
            Handle();
        }
        translate([0, 0, (drawer_wall / 2)])
            InnerBodySquare();
        // slice off everything above the top
        translate([0, 0, (outside_height / 2) + (drawer_wall / 2) + 0.001])
            cube([outside_width * 2, outside_depth *2, drawer_wall + 0.003], center=true);
    }
}
