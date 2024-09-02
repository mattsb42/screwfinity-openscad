include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./MCAD/boxes.scad>;

function drawer_options (unit_width, unit_depth, height) = [unit_width, unit_depth, height];

module Drawer(dimensions, drawer_wall=1, fill_type=SQUARE_CUT, label_cut=NO_LABEL_CUT) {

    minimum_interior_width = 0.1;
    body_chamfer = 1;
    handle_wall = 1;

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

    assert(
        label_cut == NO_LABEL_CUT || label_cut == LABEL_CUT,
        str(
            "ERROR: Invalid label cut type",
            label_cut
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
        handle_lip = 8;
        handle_support_width = outside.x / 3;
        // distance from outer edge of drawer to start of label slot
        label_slot_offset = 2;
        label_slot_thickness = .5;
        label_cutout_thickness = handle_wall - label_slot_thickness;
        // overhang that holds the label in place
        label_cutout_overhang = 2;
        edge = [outside.x / 2 - handle_wall, handle_wall * 2, outside.z / 2];

        // start at the top front edge of the drawer
        module InnerPlaneTopLeft() translate([edge.x, -1 * handle_wall, edge.z]) sphere(r=handle_wall);
        module InnerPlaneTopRight() translate([-1 * edge.x, -1 * handle_wall, edge.z]) sphere(r=handle_wall);

        // step out to the top front edge of the handle
        module OuterPlaneTopLeft() translate([edge.x, edge.y, edge.z]) sphere(r=handle_wall);
        module OuterPlaneTopRight() translate([-1 * edge.x, edge.y, edge.z]) sphere(r=handle_wall);

        // start at the front edge of the drawer
        // where we want the bottom of the handle to be
        module BottomLeft() translate([edge.x, 0, (-1 * edge.z) + handle_wall]) sphere(r=handle_wall);
        module BottomRight() translate([-1 * edge.x, 0, (-1 * edge.z) + handle_wall]) sphere(r=handle_wall);

        // step out to the outer front edge of the handle
        module OuterPlaneBottomLeft() translate([edge.x, handle_lip, 0]) sphere(r=handle_wall);
        module OuterPlaneBottomRight() translate([-1 * edge.x, handle_lip, 0]) sphere(r=handle_wall);

        // step in from the front edge to mirror the top
        module InnerPlaneBottomLeft() translate([edge.x, handle_lip - (handle_wall * 2), 0]) sphere(r=handle_wall);
        module InnerPlaneBottomRight() translate([-1 * edge.x, handle_lip - (handle_wall * 2), 0]) sphere(r=handle_wall);

        // step back to the front of the drawer
        // and over to the inner drawer support foot
        module BaseInnerLeft() translate([edge.x - handle_support_width, 0, edge.z]) sphere(r=handle_wall);
        module BaseInnerRight() translate([-1  * (edge.x - handle_support_width), 0, edge.z]) sphere(r=handle_wall);

        function yz_offset(hypotenuse) =
            let(
                // outer plane outer surface top vs bottom
                // this gives us the ratio
                baseline_run=abs(handle_lip - edge.y),
                baseline_rise=edge.z - 0,
                // angle in y-z plane of faceplate surface
                angle=atan(baseline_run / baseline_rise),
                // the y/z offsets we want to match the angle
                run=cos(angle) * hypotenuse,
                rise=sin(angle) * hypotenuse
            )
            [0, run, rise];

        // pull in to get the right thickness
        // and translate up to match the lip angle
        lip_translate = [0, (handle_lip * 2) - label_cutout_thickness, edge.z * 4];
        label_slot_upper = [edge.x - label_slot_offset, -1 * lip_translate.y, lip_translate.z];
        module LabelSlotUpperLeft() translate([label_slot_upper.x, label_slot_upper.y, label_slot_upper.z]) sphere(r=label_slot_thickness);
        module LabelSlotUpperRight() translate([-1 * label_slot_upper.x, label_slot_upper.y, label_slot_upper.z]) sphere(r=label_slot_thickness);

        label_slot_lower = [edge.x - 1, handle_lip - label_cutout_thickness, 0];
        module LabelSlotLowerLeft() translate([label_slot_lower.x, label_slot_lower.y, label_slot_lower.z]) sphere(r=label_slot_thickness);
        module LabelSlotLowerRight() translate([-1 * label_slot_lower.x, label_slot_lower.y, label_slot_lower.z]) sphere(r=label_slot_thickness);

        label_cutout_inner_upper = [label_slot_upper.x - label_cutout_overhang, label_slot_upper.y, label_slot_upper.z];
        // no fancy math needed for this offset
        // we're already above the cutoff plane
        label_cutout_outer_upper = [label_cutout_inner_upper.x, label_cutout_inner_upper.y, label_cutout_inner_upper.z];

        // walk up the slope of the handle plane
        label_cutout_inner_offset = yz_offset(1);
        label_cutout_inner_lower = [
            label_slot_lower.x - label_cutout_overhang,
            label_slot_lower.y - label_cutout_inner_offset.y,
            label_slot_lower.z + label_cutout_inner_offset.z
        ];

        // walk out perpendicular to the handle plane
        label_cutout_outer_offset = yz_offset(10);
        label_cutout_outer_lower = [label_cutout_inner_lower.x, label_cutout_inner_lower.y + label_cutout_outer_offset.y, label_cutout_inner_lower.z + label_cutout_outer_offset.z];
        module LabelCutoutInnerUpperLeft() translate([label_cutout_inner_upper.x, label_cutout_inner_upper.y, label_cutout_inner_upper.z]) sphere(r=label_slot_thickness);
        module LabelCutoutInnerUpperRight() translate([-1 * label_cutout_inner_upper.x, label_cutout_inner_upper.y, label_cutout_inner_upper.z]) sphere(r=label_slot_thickness);
        module LabelCutoutOuterUpperLeft() translate([label_cutout_outer_upper.x, label_cutout_outer_upper.y, label_cutout_outer_upper.z]) sphere(r=label_slot_thickness);
        module LabelCutoutOuterUpperRight() translate([-1 * label_cutout_outer_upper.x, label_cutout_outer_upper.y, label_cutout_outer_upper.z]) sphere(r=label_slot_thickness);
        module LabelCutoutInnerLowerLeft() translate([label_cutout_inner_lower.x, label_cutout_inner_lower.y, label_cutout_inner_lower.z]) sphere(r=label_slot_thickness);
        module LabelCutoutInnerLowerRight() translate([-1 * label_cutout_inner_lower.x, label_cutout_inner_lower.y, label_cutout_inner_lower.z]) sphere(r=label_slot_thickness);
        module LabelCutoutOuterLowerLeft() translate([label_cutout_outer_lower.x, label_cutout_outer_lower.y, label_cutout_outer_lower.z]) sphere(r=label_slot_thickness);
        module LabelCutoutOuterLowerRight() translate([-1 * label_cutout_outer_lower.x, label_cutout_outer_lower.y, label_cutout_outer_lower.z]) sphere(r=label_slot_thickness);

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

        module LabelSlot() {
            hull() {
                LabelSlotUpperLeft();
                LabelSlotUpperRight();
                LabelSlotLowerLeft();
                LabelSlotLowerRight();
            }
            hull() {
                LabelCutoutInnerUpperLeft();
                LabelCutoutInnerUpperRight();
                LabelCutoutInnerLowerLeft();
                LabelCutoutInnerLowerRight();
                LabelCutoutOuterUpperLeft();
                LabelCutoutOuterUpperRight();
                LabelCutoutOuterLowerLeft();
                LabelCutoutOuterLowerRight();
            }
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
            if (label_cut == LABEL_CUT) LabelSlot();
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
            translate([0, (outside.y / 2) - handle_wall, 0])
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
