include <./constants.scad>;
include <./options.scad>;
include <./drawer-handles.scad>;
include <./drawer-cutouts.scad>;
include <./grid.scad>;
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


/**
Helper to assemble a drawer options structure.
*/
function drawer_options(unit_width, unit_depth, height) = [unit_width, unit_depth, height];

/**
Helper to assemble a handle properties structure.
*/
function handle_properties(
    style=TRIANGLE_HANDLE,
    depth=DEFAULT_HANDLE_DEPTH,
    label_cut=NO_LABEL_CUT
) = [style, depth, label_cut];

/**
Helper to assemble fill properties for a drawer.
*/
function fill_properties(
    style=undef,
    grid=undef
) =
    assert(
        !(style == undef && grid == undef),
        str(
            "ERROR: Neither style nor grid are set for fill_properties. ",
            "Provide exactly one."
        )
    )
    assert(
        style == undef || grid == undef,
        str(
            "ERROR: Both style and grid are set for fill_properties. ",
            "Provide exactly one."
        )
    )
    grid != undef
    ? grid
    : uniform_grid(
        row_count=1,
        column_count=1,
        style=style
    );

function drawer_outside_dimensions(dimensions) = [
    (dimensions.x * GRIDFINITY_GRID_LENGTH) - GU_TO_DU - (DRAWER_TOLERANCE * 2),
    (dimensions.y * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL - DRAWER_STOP,
    dimensions.z,
];

module Drawer(
    dimensions,
    drawer_wall=1,
    fill_properties=fill_properties(style=SQUARE_CUT),
    handle_properties=handle_properties()
) {


    fill_type = SCOOP_CUT;
    minimum_interior_width = 0.1;
    body_chamfer = 1;

    valid_width = assert_positive_value(name="width", value=dimensions.x);
    valid_depth = assert_positive_integer_value(name="unit depth", value=dimensions.y);
    valid_height = assert_positive_value(name="height", value=dimensions.z);

    for(cell = fill_properties)
        let(valid_style=assert_valid_drawer_cell_cut_style(cell[4]));

    assert(
        len(handle_properties) == 3,
        str(
            "ERROR: Invalid handle properties length",
            len(handle_properties)
        )
    );

    handle_style = handle_properties[0];
    valid_handle_style = assert_valid_drawer_handle_style(handle_style);

    handle_depth = handle_properties[1];
    valid_handle_depth = assert_positive_value(name="handle depth", value=handle_depth);

    label_cut = handle_properties[2];
    valid_label_cut = assert_valid_drawer_label_cut_style(label_cut);

    outside_dimensions = drawer_outside_dimensions(dimensions);
    maximum_inside_width = outside_dimensions.x - (2 * drawer_wall);

    assert(
        maximum_inside_width >= minimum_interior_width,
        str(
            "ERROR: Drawer width is too narrow.",
            " With unit width ", dimensions.x,
            " and drawer wall thickness ", drawer_wall,
            " the drawer interior width is ", maximum_inside_width, ".",
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

    // block out the edges of the side walls to slice off any overhangs
    module SideWallSlice() {
        // add a tiny slice to intersect with the wall and avoid rendering artifacts
        buffer = 0.00005;
        translate([(outside_dimensions.x / 2) + 5 - buffer, 0, 0])
            cube([10, outside_dimensions.y * 2, outside_dimensions.z * 2], center=true);
        translate([-1 * (outside_dimensions.x / 2) - 5 + buffer, 0, 0])
            cube([10, outside_dimensions.y * 2, outside_dimensions.z * 2], center=true);
    }

    module Cutouts() {
        // reset to the top left
        // because that's what grid-math assumes
        let(
            fill_outside_dimensions=[
                outside_dimensions.x - drawer_wall,
                outside_dimensions.y - drawer_wall,
                outside_dimensions.z
            ]
        )
        translate([
            fill_outside_dimensions.x / 2 * -1,
            fill_outside_dimensions.y / 2 * -1,
            0
        ])
        for (cut = fill_properties)
            let(
                x_offset=cut[0],
                y_offset=cut[1],
                x_percentage=cut[2],
                y_percentage=cut[3],
                style=cut[4]
            )
            translate([
                // For reasons that don't grok in my brain right now,
                // the grid is rotated 180 degrees on the y axis.
                // This means that we have to reverse the x coordinate
                // or we get a mirror image of what we intended.
                fill_outside_dimensions.x - (fill_outside_dimensions.x * x_offset),
                fill_outside_dimensions.y * y_offset,
                (drawer_wall / 2)
            ])
            let(
                cut_dimensions=[
                    (fill_outside_dimensions.x * x_percentage) - drawer_wall,
                    (fill_outside_dimensions.y * y_percentage) - drawer_wall,
                    fill_outside_dimensions.z - drawer_wall
                ]
            )
            color("red"){
                if (style == SQUARE_CUT) SquareCutout(dimensions=cut_dimensions, chamfer=body_chamfer);
                else if (style == SCOOP_CUT) ScoopCutout(dimensions=cut_dimensions, chamfer=body_chamfer);
            }
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
        Cutouts();
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
