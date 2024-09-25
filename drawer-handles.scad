// wall thickness in handle
HANDLE_WALL = 1;


/**
Creates a "standard" triangle handle.
*/
module TriangleHandle(drawer_outside_dimensions, label_cut, handle_depth) {
    assert(
        handle_depth >= HANDLE_WALL * 2,
        str(
            "ERROR: Handle depth MUST be at least ",
            HANDLE_WALL * 2,
            " for TriangleHandle handles. Provided: ",
            handle_depth
        )
    );

    handle_support_width = drawer_outside_dimensions.x / 3;
    label_cutout_thickness = HANDLE_WALL - LABEL_SLOT_CUT_RADIUS;
    // overhang that holds the label in place
    label_cutout_overhang = 2;
    edge = [drawer_outside_dimensions.x / 2 - HANDLE_WALL, HANDLE_WALL * 2, drawer_outside_dimensions.z / 2];

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
    module OuterPlaneBottomLeft() translate([edge.x, handle_depth, 0]) sphere(r=HANDLE_WALL);
    module OuterPlaneBottomRight() translate([-1 * edge.x, handle_depth, 0]) sphere(r=HANDLE_WALL);

    // step in from the front edge to mirror the top
    module InnerPlaneBottomLeft() translate([edge.x, handle_depth - (HANDLE_WALL * 2), 0]) sphere(r=HANDLE_WALL);
    module InnerPlaneBottomRight() translate([-1 * edge.x, handle_depth - (HANDLE_WALL * 2), 0]) sphere(r=HANDLE_WALL);

    // step back to the front of the drawer
    // and over to the inner drawer support foot
    module BaseInnerLeft() translate([edge.x - handle_support_width, 0, edge.z]) sphere(r=HANDLE_WALL);
    module BaseInnerRight() translate([-1  * (edge.x - handle_support_width), 0, edge.z]) sphere(r=HANDLE_WALL);

    face_pane_angle = 
        let(
            // run from outer surface bottom to front of drawer body
            baseline_run=abs(handle_depth - edge.y),
            // rise from outer surface bottom to top
            baseline_rise=edge.z - 0
        )
        atan(baseline_rise / baseline_run);

    /**
    Calculate the coordinates of moving `hypotenuse` distance parallel to the handle face.
    */
    function parallel_offset(hypotenuse) =
        let(
            angle=face_pane_angle,
            // the y/z offsets we want to match the angle
            run=cos(angle) * hypotenuse,
            rise=sin(angle) * hypotenuse
        )
        [0, run, rise];

    /**
    Calculate the coordinates of moving `hypotenuse` distance perpendicular to the handle face.
    */
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
        handle_depth - LABEL_SLOT_FACE_OFFSET,
        0,
    ];
    upper_offset = parallel_offset(handle_depth * 2);
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
