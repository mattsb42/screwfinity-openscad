include <./constants.scad>;
include <./options.scad>;
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
HANDLE_LIP = 8;
// wall thickness in handle
HANDLE_WALL = 1;

function drawer_options (unit_width, unit_depth, height) = [unit_width, unit_depth, height];

function drawer_outside_dimensions(dimensions) = [
    (dimensions.x * GRIDFINITY_GRID_LENGTH) - GU_TO_DU - (DRAWER_TOLERANCE * 2),
    (dimensions.y * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP,
    dimensions.z,
];

module Drawer(dimensions, drawer_wall=1, fill_type=SQUARE_CUT, label_cut=NO_LABEL_CUT) {

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

    outside = drawer_outside_dimensions(dimensions);
    inside = [
        outside.x - (2 * drawer_wall),
        outside.y - (2 * drawer_wall),
        outside.z - drawer_wall
    ];

    assert(
        inside.x >= minimum_interior_width,
        str(
            "ERROR: Drawer width is too narrow.",
            " With unit width ", dimensions.x,
            " and drawer wall thickness ", drawer_wall,
            " the drawer interior width is ", inside.x, ".",
            " Recommend reducing drawer width to no more than ",
            (outside.x - minimum_interior_width) / 2
        )
    );

    module Body() {
        difference() {
            roundedCube(size=[outside.x, outside.y, outside.z], r=body_chamfer, sidesonly=true, center=true);
            // chamfer
            translate([-1 * outside.x / 2, -1 * outside.y / 2, -1 * outside.z / 2])
                Lip(footprint=outside, cross_section=[CHAMFER_HEIGHT, CHAMFER_HEIGHT]);
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

    module Handle() {
        handle_support_width = outside.x / 3;
        label_cutout_thickness = HANDLE_WALL - LABEL_SLOT_CUT_RADIUS;
        // overhang that holds the label in place
        label_cutout_overhang = 2;
        edge = [outside.x / 2 - HANDLE_WALL, HANDLE_WALL * 2, outside.z / 2];

        // start at the top front edge of the drawer
        module InnerPlaneTopLeft() translate([edge.x, -1 * HANDLE_WALL, edge.z]) sphere(r=HANDLE_WALL);
        module InnerPlaneTopRight() translate([-1 * edge.x, -1 * HANDLE_WALL, edge.z]) sphere(r=HANDLE_WALL);

        // step out to the top front edge of the handle
        module OuterPlaneTopLeft() translate([edge.x, edge.y, edge.z]) sphere(r=HANDLE_WALL);
        module OuterPlaneTopRight() translate([-1 * edge.x, edge.y, edge.z]) sphere(r=HANDLE_WALL);

        // start at the front edge of the drawer
        // where we want the bottom of the handle to be
        module BottomLeft() translate([edge.x, 0, (-1 * edge.z) + HANDLE_WALL]) sphere(r=HANDLE_WALL);
        module BottomRight() translate([-1 * edge.x, 0, (-1 * edge.z) + HANDLE_WALL]) sphere(r=HANDLE_WALL);

        // step out to the outer front edge of the handle
        module OuterPlaneBottomLeft() translate([edge.x, HANDLE_LIP, 0]) sphere(r=HANDLE_WALL);
        module OuterPlaneBottomRight() translate([-1 * edge.x, HANDLE_LIP, 0]) sphere(r=HANDLE_WALL);

        // step in from the front edge to mirror the top
        module InnerPlaneBottomLeft() translate([edge.x, HANDLE_LIP - (HANDLE_WALL * 2), 0]) sphere(r=HANDLE_WALL);
        module InnerPlaneBottomRight() translate([-1 * edge.x, HANDLE_LIP - (HANDLE_WALL * 2), 0]) sphere(r=HANDLE_WALL);

        // step back to the front of the drawer
        // and over to the inner drawer support foot
        module BaseInnerLeft() translate([edge.x - handle_support_width, 0, edge.z]) sphere(r=HANDLE_WALL);
        module BaseInnerRight() translate([-1  * (edge.x - handle_support_width), 0, edge.z]) sphere(r=HANDLE_WALL);

        face_pane_angle = 
            let(
                // run from outer surface bottom to front of drawer body
                baseline_run=abs(HANDLE_LIP - edge.y),
                // rise from outer surface bottom to top
                baseline_rise=edge.z - 0
            )
            atan(baseline_rise / baseline_run);

        function parallel_offset(hypotenuse) =
            let(
                angle=face_pane_angle,
                // the y/z offsets we want to match the angle
                run=cos(angle) * hypotenuse,
                rise=sin(angle) * hypotenuse
            )
            [0, run, rise];

        function perpendicular_offset(hypotenuse) =
            let(
                angle=90 - face_pane_angle,
                run=cos(angle) * hypotenuse,
                rise=sin(angle) * hypotenuse
            )
            [0, run, rise];

        // pull in to get the right thickness
        // and translate up to match the lip angle
        label_slot_lower = [
            edge.x - LABEL_SLOT_OFFSET,
            HANDLE_LIP - LABEL_SLOT_FACE_OFFSET,
            0,
        ];
        upper_offset = parallel_offset(dimensions.z);
        label_slot_upper = [
            label_slot_lower.x,
            label_slot_lower.y - upper_offset.y,
            label_slot_lower.z + upper_offset.z,
        ];
        
        module LabelSlot() {
            hull() {
                // upper left
                translate([label_slot_upper.x, label_slot_upper.y, label_slot_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // upper right
                translate([-1 * label_slot_upper.x, label_slot_upper.y, label_slot_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // lower left
                translate([label_slot_lower.x, label_slot_lower.y, label_slot_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // lower right
                translate([-1 * label_slot_lower.x, label_slot_lower.y, label_slot_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
            }
        }

        module LabelCutout() {
            label_cutout_inner_upper = [
                label_slot_upper.x - label_cutout_overhang,
                label_slot_upper.y,
                label_slot_upper.z
            ];

            // walk out perpendicular to the handle plane
            label_cutout_outer_offset = perpendicular_offset(10);
            
            label_cutout_outer_upper = [
                label_cutout_inner_upper.x,
                label_cutout_inner_upper.y + label_cutout_outer_offset.y,
                label_cutout_inner_upper.z + label_cutout_outer_offset.z
            ];

            // walk up the slope of the handle plane
            label_cutout_inner_offset = parallel_offset(label_cutout_overhang);
            label_cutout_inner_lower = [
                label_slot_lower.x - label_cutout_overhang,
                label_slot_lower.y - label_cutout_inner_offset.y,
                label_slot_lower.z + label_cutout_inner_offset.z
            ];

            label_cutout_outer_lower = [
                label_cutout_inner_lower.x,
                label_cutout_inner_lower.y + label_cutout_outer_offset.y,
                label_cutout_inner_lower.z + label_cutout_outer_offset.z
            ];
            hull() {
                // inner upper left
                translate([label_cutout_inner_upper.x, label_cutout_inner_upper.y, label_cutout_inner_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // inner upper right
                translate([-1 * label_cutout_inner_upper.x, label_cutout_inner_upper.y, label_cutout_inner_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // inner lower left
                translate([label_cutout_inner_lower.x, label_cutout_inner_lower.y, label_cutout_inner_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // inner lower right
                translate([-1 * label_cutout_inner_lower.x, label_cutout_inner_lower.y, label_cutout_inner_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);

                // outer upper left
                translate([label_cutout_outer_upper.x, label_cutout_outer_upper.y, label_cutout_outer_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // outer upper right
                translate([-1 * label_cutout_outer_upper.x, label_cutout_outer_upper.y, label_cutout_outer_upper.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // outer lower left
                translate([label_cutout_outer_lower.x, label_cutout_outer_lower.y, label_cutout_outer_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
                // outer lower right
                translate([-1 * label_cutout_outer_lower.x, label_cutout_outer_lower.y, label_cutout_outer_lower.z]) sphere(r=LABEL_SLOT_CUT_RADIUS);
            }
        }


        /*
        Three structures form the handle,
        each a hull of sphere points.

        The face is a flat plane
        that extends outward from the front of the drawer,
        halfway down the drawer height.

        Two tetrahedron bases support the face,
        one on either side of the drawer.
        */

        module LeftBase() {
            hull() {
                InnerPlaneTopLeft();
                BottomLeft();
                OuterPlaneBottomLeft();
                BaseInnerLeft();
            }
        }

        module RightBase() {
            hull() {
                InnerPlaneTopRight();
                BottomRight();
                OuterPlaneBottomRight();
                BaseInnerRight();
            }
        }

        module LabelSlotWithWindow() {
            LabelSlot();
            LabelCutout();
        }

        module Face() {
            hull() {
                InnerPlaneTopRight();
                InnerPlaneTopLeft();
                OuterPlaneTopLeft();
                OuterPlaneTopRight();
                OuterPlaneBottomLeft();
                OuterPlaneBottomRight();
                InnerPlaneBottomLeft();
                InnerPlaneBottomRight();
            }
        }

        module SolidHandle() {
            LeftBase();
            RightBase();
            Face();
        }

        difference() {
            SolidHandle();
            if (label_cut == LABEL_CUT) LabelSlotWithWindow();
        }
    }

    // block out the edges of the side walls to slice off any overhangs
    module SideWallSlice() {
        // add a tiny slice to intersect with the wall and avoid rendering artifacts
        buffer = 0.00005;
        translate([(outside.x / 2) + 5 - buffer, 0, 0])
            cube([10, outside.y * 2, outside.z * 2], center=true);
        translate([-1 * (outside.x / 2) - 5 + buffer, 0, 0])
            cube([10, outside.y * 2, outside.z * 2], center=true);
    }

    difference() {
        union() {
            Body();
            translate([0, (outside.y / 2) - HANDLE_WALL, 0])
                Handle();
        }
        translate([0, 0, (drawer_wall / 2)]) {
            if (fill_type == SQUARE_CUT) SquareCutout();
            else if (fill_type == SCOOP_CUT) ScoopCutout();
        }
        SideWallSlice();
        // slice off everything above the top
        translate([0, 0, (outside.z / 2) + (drawer_wall) + 0.001])
            cube([outside.x * 2, outside.y *2, (drawer_wall * 2) + 0.003], center=true);
    }
}


module Label(drawer_unit_dimensions) {
    assert(
        drawer_unit_dimensions.x > 0 && drawer_unit_dimensions.y > 0 && drawer_unit_dimensions.z > 0,
        str(
            "ERROR: All dimensions MUST be positive. ",
            drawer_unit_dimensions
        )
    );

    drawer_dimensions = drawer_outside_dimensions(drawer_unit_dimensions);
    label_slot_y_offset = HANDLE_LIP - LABEL_SLOT_FACE_OFFSET;

    label_dimensions = [
        drawer_dimensions.x - (2 * (HANDLE_WALL + LABEL_SLOT_OFFSET)),
        sqrt(pow(label_slot_y_offset, 2) + pow(drawer_dimensions.z / 2, 2)) - LABEL_SLOT_CUT_RADIUS,
        LABEL_THICKNESS,
    ];

    cube(label_dimensions, center=true);
}
