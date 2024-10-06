include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./cabinet-tops.scad>;
use <./cabinet-bases.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-holes.scad>;


function drawer_slot_options(unit_width, height) = [unit_width, 0, height];

function grid_expand(drawer, rows) = [for (i = [0:rows -1]) drawer];

function surface_options(
    style,
    hole_options=bundle_hole_options(
        magnet_hole=true,
        crush_ribs=true
    )
) = [style, hole_options];

module Cabinet(
    gridfinity_footprint,
    grid,
    base=surface_options(style=GRIDFINITY_BASE),
    top=surface_options(style=GRIDFINITY_STACKING_TOP),
) {
    outer_wall = 2.0;
    inner_wall = 1.0;
    outer_footprint = [
        gridfinity_footprint.x * GRIDFINITY_GRID_LENGTH,
        gridfinity_footprint.y * GRIDFINITY_GRID_LENGTH
    ];

    valid_x = assert_integer_value(name="gridfinity_footprint.x", value=gridfinity_footprint.x);
    valid_y = assert_integer_value(name="gridfinity_footprint.y", value=gridfinity_footprint.y);

    for (row = grid) {
        assert(
            row.x <= gridfinity_footprint.x,
            str(
                "ERROR: Invalid drawer and cabinet width selection. ",
                "Drawer unit width ", row.x,
                " is wider than cabinet grid unit width ", gridfinity_footprint.x
            )
        );
    }

    valid_base = assert_valid_cabinet_base_style(base[0]);
    valid_top = assert_valid_cabinet_top_style(top[0]);

    module DrawerStop() {
        // Width of the drawer stop across the slot opening.
        stop_width = 20;
        // Horizonal distance from end of drawer stop to the peak.
        slope_run = 0.5;
        // Height of drawer stop.
        stop_height = 1;

        stop_base = [
            // inner edge
            [[-1 * stop_width / 2, DRAWER_STOP / 2, 0], [stop_width / 2, DRAWER_STOP / 2, 0]],
            // outer edge
            [[-1 * stop_width / 2, -1 * DRAWER_STOP / 2, 0], [stop_width / 2, -1 * DRAWER_STOP / 2, 0]],
        ];
        stop_peak = [
            [-1 * (stop_width / 2 - slope_run), 0, stop_height], [stop_width / 2 - slope_run, 0, stop_height],
        ];
        polyhedron(
            points=[
                stop_base[0].x,
                stop_base[0].y,
                stop_base[1].x,
                stop_base[1].y,
                stop_peak.x,
                stop_peak.y,
            ],
            faces=[
                // bottom face
                [0, 2, 3, 1],
                // inner slope
                [0, 1, 5, 4],
                // outer slope
                [2, 4, 5, 3],
                // left slope
                [0, 4, 2],
                // right slope
                [1, 3, 5],
            ]
        );
    }

    module DrawerSlotNegative(dimensions) {
        difference(){
            cube(dimensions, center=true);
            translate([
                0,
                (dimensions.y / 2) - (DRAWER_STOP / 2),
                -1 * dimensions.z / 2
            ])
                DrawerStop();
        }
    }

    module SolidCabinet(dimensions) {
        difference() {
            cube(dimensions, center=true);
            // trim off the front film
            translate([0, (dimensions.y / 2) + 0.001, 0])
                cube([dimensions.x, 0.003, dimensions.z], center=true);
        }
    }

    /**
     * Get the buffer to add to each wall in a row,
     *  to center the columns in a row.
     */
    function row_wall_buffer(outer_width, slot_width, column_count) = 
        (
            (outer_width - (outer_wall * 2))
            - ((slot_width + inner_wall) * column_count)
        )
        / (column_count + 1);

    /**
     * Get the correct coordinates for the center of a drawer slot.
     */
    function row_traverse(row_inner, slot_outer, column) =
        let(origin=[
            // move to the left edge
            (row_inner.x / 2)
                // move to the center of the first drawer
                - (slot_outer.x / 2),
            // move the origin forward to align the cutout with the front of the cabinet
            CABINET_REAR_WALL / 2,
            (row_inner.z / 2) - (slot_outer.z / 2)
        ])
            [
                origin.x - (slot_outer.x * column),
                origin.y,
                origin.z,
            ];

    /**
     */
    module CabinetRow(row_drawer_height, row_drawer_width) {
        // Inner dimensions of a drawer slot cutout.
        echo(str("Creating row for drawers of width ", row_drawer_width, " and height ", row_drawer_height));
        slot_inner = [
            (row_drawer_width * GRIDFINITY_GRID_LENGTH) - GU_TO_DU,
            (gridfinity_footprint.y * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL,
            row_drawer_height + (2 * DRAWER_TOLERANCE),
        ];
        outer_perimeter = [
            gridfinity_footprint.x * GRIDFINITY_GRID_LENGTH,
            gridfinity_footprint.y * GRIDFINITY_GRID_LENGTH,
        ];
        minimum_slot_outer_width = slot_inner.x + inner_wall;
        row_columns = floor(outer_perimeter.x / minimum_slot_outer_width);
        
        // Extra width to add to each wall to center the drawer slots in a row.
        row_buffer = row_wall_buffer(
            outer_width=outer_perimeter.x,
            slot_width=slot_inner.x,
            column_count=row_columns
        );

        // "Outer" dimensions of a virtual drawer slot,
        //  with the necessary boundaries around the cutout.
        slot_outer = [
            // Spread the extra space evenly across all walls.
            minimum_slot_outer_width + row_buffer,
            // The drawer slot "outer" dimension is the same as the inner.
            slot_inner.y,
            slot_inner.z + inner_wall,
        ];
        // Virtual "inner" dimensions of the row.
        // Used to align and center the slot cutouts.
        row_inner = [
            outer_perimeter.x - (outer_wall * 2) - row_buffer,
            slot_outer.y,
            slot_outer.z,
        ];
        row_outer = [
            gridfinity_footprint.x * GRIDFINITY_GRID_LENGTH,
            gridfinity_footprint.y * GRIDFINITY_GRID_LENGTH,
            row_inner.z,
        ];

        translate([0, 0, -1 * row_outer.z / 2])
        difference() {
            color("grey")
                SolidCabinet(row_outer);
            for (column = [0: row_columns - 1])
                translate(row_traverse(row_inner, slot_outer, column))
                    DrawerSlotNegative(slot_inner);
        }
    }

    /**
     * Get the correct Z starting point for a specific row.
     */
    function row_z_offset(rows, row_index) =
        let(
            drawer_height_sum = sum_vector(sub_vector([for (r = rows) r.z], row_index)),
            slot_inner_sum = drawer_height_sum + (row_index * (2 * DRAWER_TOLERANCE)),
            slot_outer_sum = slot_inner_sum + (row_index * inner_wall)
        )
            slot_outer_sum;

    /**
     * Get the Z position of the top of the shell.
     */
    function top_of_shell() = outer_wall;

    /**
     * Get the Z position of the bottom of the shell.
     */
    function bottom_of_shell() = -1 * row_z_offset(grid, len(grid)) - outer_wall;

    module CabinetBody() {
        echo(str("grid: ", grid));
        // top plate
        color("pink")
        translate([0, 0, top_of_shell() - (outer_wall / 2)])
            cube([outer_footprint.x, outer_footprint.y, outer_wall], center=true);
        for (row = [0: len(grid) - 1]) {
            translate([0, 0, -1 * row_z_offset(grid, row)])
                CabinetRow(row_drawer_height=grid[row].z, row_drawer_width=grid[row].x);
        }
        // bottom plate
        color("pink")
        translate([0, 0, bottom_of_shell() + (outer_wall / 2)])
            cube([outer_footprint.x, outer_footprint.y, outer_wall], center=true);
    }

    translate([0, 0, top_of_shell()])
        CabinetTop(
            gridfinity_footprint=gridfinity_footprint,
            outer_footprint=outer_footprint,
            style=top[0]
        );
    CabinetBody();
    translate([0, 0, bottom_of_shell()])
        CabinetBase(
            gridfinity_footprint=gridfinity_footprint,
            style=base[0],
            hole_options=base[1]
        );
}
