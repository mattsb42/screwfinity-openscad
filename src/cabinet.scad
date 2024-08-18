include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-utility.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-holes.scad>;
include <./gridfinity-rebuilt-openscad/standard.scad>;


function drawer_slot_options (drawer_u_width, drawer_height) = [drawer_u_width, drawer_height];

function row_options () = [];

drawer = ["width", "height"];
row = [[drawer, drawer, drawer]];
grid = [row, row, row];
shell = ["x", "y", grid];


module Cabinet(
    drawer_height,
    drawer_u_width,
    u_width,
    u_depth,
    drawer_rows,
    base_style=GRIDFINITY_BASE,
    hole_options=bundle_hole_options(magnet_hole=true),
    top_style=LIP_TOP,
) {
    outer_wall = 2.0;
    inner_wall = 1.0;
    ceiling_floor = 0.5;

    assert(
        u_width % 1 == 0,
        str(
            "ERROR: Invalid u_width value ",
            u_width,
            " must be an integer."
        )
    );

    assert(
        u_depth % 1 == 0,
        str(
            "ERROR: Invalid u_depth value ",
            u_depth,
            " must be an integer."
        )
    );

    assert(
        drawer_rows % 1 == 0,
        str(
            "ERROR: Invalid drawer_rows value ",
            drawer_rows,
            " must be an integer."
        )
    );

    assert(
        u_width % drawer_u_width == 0,
        str(
            "ERROR: Invalid drawer and cabinet width selection. ",
            "Cabinet unit width ",
            u_width,
            " is not evenly divisible by drawer unit width ",
            drawer_u_width
        )
    );

    assert(
        base_style == NO_BASE || base_style == GRIDFINITY_BASE,
        str(
            "ERROR: Invalid base style: ",
            base_style
        )
    );

    assert(
        top_style == NO_TOP || top_style == LIP_TOP || top_style == GRIDFINITY_STACKING_TOP,
        str(
            "ERROR: Invalid top style: ",
            top_style
        )
    );

    drawer_columns = u_width / drawer_u_width;

    // Inner dimensions of a drawer slot cutout.
    drawer_slot_inner = [
        (drawer_u_width * GRIDFINITY_GRID_LENGTH) - GU_TO_DU,
        (GRIDFINITY_GRID_LENGTH * u_depth) - CABINET_REAR_WALL,
        drawer_height + (2 * DRAWER_TOLERANCE),
    ];
    
    shell_outer_width = GRIDFINITY_GRID_LENGTH * u_width;
    maximum_shell_inner_width = shell_outer_width - (outer_wall * 2);

    minimum_drawer_slot_outer_width = drawer_slot_inner.x + inner_wall;
    // The buffer space to add to each required wall.
    wall_buffer = 
        (maximum_shell_inner_width - (minimum_drawer_slot_outer_width * drawer_columns))
        / (drawer_columns + 1);
    // The wall buffer is the extra space on each vertical that is not a drawer slot.
    
    // "Outer" dimensions of a virtual drawer slot,
    //  with the necessary boundaries around the cutout.
    drawer_slot_outer = [
        // Each drawer slot "outer" gets two halves of a wall buffer.
        minimum_drawer_slot_outer_width + wall_buffer,
        // The drawer slot "outer" dimension is the same as the inner.
        drawer_slot_inner.y,
        drawer_slot_inner.z + inner_wall,
    ];
    
    // I'm not entirely sure that the bad case is reachable anymore,
    //  but I'm going to leave this check here just in case.
    assert(
        drawer_slot_outer.x > drawer_slot_inner.x,
        str(
            "ERROR: Drawer slot impossible dimensions. Inner width ",
            drawer_slot_inner.x,
            " is wider than outer width ",
            drawer_slot_outer.x
        )
    );
    
    // "Inner" dimensions of a virtual cabinet shell inner space,
    //  with the neccessary boundaries around the drawer slot cutouts.
    shell_inner = [
        // Each outer wall gets two halves of a wall buffer.
        maximum_shell_inner_width - wall_buffer,
        drawer_slot_outer.y,
        drawer_slot_outer.z * drawer_rows,
    ];

    // Outer dimensions of the cabinet shell.
    shell_outer = [
        maximum_shell_inner_width + (outer_wall * 2),
        shell_inner.y + outer_wall,
        shell_inner.z + (outer_wall * 2),
    ];

    expected_outer_dimensions = [
        GRIDFINITY_GRID_LENGTH * u_width,
        GRIDFINITY_GRID_LENGTH * u_depth,
    ];
    assert(
        expected_outer_dimensions.x == shell_outer.x,
        str(
            "ERROR: Shell outer X dimension drift detected.",
            " Expected: ", expected_outer_dimensions.x,
            " Actual: ", shell_outer.x
        )
    );
    assert(
        expected_outer_dimensions.y == shell_outer.y,
        str(
            "ERROR: Shell outer Y dimension drift detected.",
            " Expected: ", expected_outer_dimensions.y,
            " Actual: ", shell_outer.y
        )
    );

    module DrawerStop() {
        // Width of the drawer stop across the slot opening.
        stop_width = 20;
        // Horizonal distance from end of drawer stop to the peak.
        slope_run = 0.5;
        // Height of drawer stop.
        stop_height = 1;

        base = [
            // inner edge
            [[-1 * stop_width / 2, DRAWER_STOP / 2, 0], [stop_width / 2, DRAWER_STOP / 2, 0]],
            // outer edge
            [[-1 * stop_width / 2, -1 * DRAWER_STOP / 2, 0], [stop_width / 2, -1 * DRAWER_STOP / 2, 0]],
        ];
        peak = [
            [-1 * (stop_width / 2 - slope_run), 0, stop_height], [stop_width / 2 - slope_run, 0, stop_height],
        ];
        polyhedron(
            points=[
                base[0].x,
                base[0].y,
                base[1].x,
                base[1].y,
                peak.x,
                peak.y,
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

    // Locate the correct center position for a drawer slot.
    function traverse (column, row) =
        let(origin=[
            // move to left edge
            (shell_inner.x / 2)
                // move to the center of the first drawer
                - (drawer_slot_outer.x / 2),
            (shell_inner.z / 2) - (drawer_slot_outer.z / 2)
        ])
        let(
            column_position=origin.x - (drawer_slot_outer.x * column),
            row_position=origin.y - (drawer_slot_outer.z * row)
        )
            [column_position, 0, row_position];

    function row_wall_buffer (outer_width, slot_width, column_count) = 
        (
            (outer_width - (outer_wall * 2))
            - ((slot_width + inner_wall) * column_count)
        )
        / (column_count + 1);

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
            (u_depth * GRIDFINITY_GRID_LENGTH) - CABINET_REAR_WALL,
            row_drawer_height + (2 * DRAWER_TOLERANCE),
        ];
        outer_perimeter = [
            u_width * GRIDFINITY_GRID_LENGTH,
            u_depth * GRIDFINITY_GRID_LENGTH,
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
            u_width * GRIDFINITY_GRID_LENGTH,
            u_depth * GRIDFINITY_GRID_LENGTH,
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

    function sum_vector(vector, index=0, running_sum=0) =
        index < len(vector)
        ? sum_vector(vector, index + 1, running_sum + vector[index])
        : running_sum;

    function sub_vector(vector, end_index) = end_index <= 0 ? [] : [
        for (i = [0: end_index - 1]) if (i < len(vector)) vector[i]
    ];

    function row_y_offset(rows, row_index) =
        let(
            drawer_height_sum = sum_vector(sub_vector([for (r = rows) r.y], row_index)),
            slot_inner_sum = drawer_height_sum + (row_index * (2 * DRAWER_TOLERANCE)),
            slot_outer_sum = slot_inner_sum + (row_index * inner_wall)
        )
            slot_outer_sum;

    function bottom_of_shell (rows) = -1 * row_y_offset(rows, len(rows));

    module CabinetBody2(rows) {
        // top plate
        translate([0, 0, outer_wall / 2])
            cube([shell_outer.x, shell_outer.y, outer_wall], center=true);
        for (row = [0: len(rows) - 1]) {
            translate([0, 0, -1 * row_y_offset(rows, row)])
                CabinetRow(row_drawer_height=rows[row].y, row_drawer_width=rows[row].x);
        }
        // bottom plate
        translate([0, 0, bottom_of_shell(rows) - (outer_wall / 2)])
            cube([shell_outer.x, shell_outer.y, outer_wall], center=true);
    }

    module CabinetBody() {
        difference() {
            color("grey")
                SolidCabinet(shell_outer);
            translate([0, CABINET_REAR_WALL / 2, 0])
                for (row = [0: drawer_rows - 1])
                    for (column = [0: drawer_columns - 1]){
                        echo(str("column ", column, ", row ", row, " at position ", traverse(column, row)));
                        translate(traverse(column, row))
                            DrawerSlotNegative(drawer_slot_inner);
                    }
        }
    }

    module GridFinityBase (shell_base) {
        translate([0, 0, shell_base - 5]) 
        color("red")
            gridfinityBase(
                gx=u_width,
                gy=u_depth,
                l=GRIDFINITY_GRID_LENGTH,
                dx=0,
                dy=0,
                hole_options=hole_options
            );
    }

    module CabinetBase(shell_base) {
        if(base_style == GRIDFINITY_BASE) GridFinityBase(shell_base);
    }

    module LipTop(shell_top) {
        cross_section = [2, 4];
        translate([0, 0, shell_top + (cross_section.y / 2)]) {
            // add a rim around the lip; the lip by itself is too thin at the edge
            outer_buffer_width = 0.25;
            color("blue")
            difference() {
                cube([shell_outer.x, shell_outer.y, cross_section.y], center=true);
                // make the cut-out cube taller to remove render preview artifacts
                cube([shell_outer.x - outer_buffer_width, shell_outer.y - outer_buffer_width, cross_section.y + 1], center=true);
            }
            // add the lip
            color("green")
                Lip(
                    footprint=[shell_outer.x - outer_buffer_width, shell_outer.y - outer_buffer_width],
                    cross_section=cross_section,
                    center=true
                );
        }
    }

    module GridFinityStackingLip(shell_top) {
        // There's an extra 1mm offset somewhere (haven't pinned down where it comes from)
        //  and add an extra micrometer to remove render artifacts.
        actual_offset = h_base + 1.001;
        translate([0, 0, shell_top - actual_offset]) {
            difference() {
                gridfinityInit(gx = u_width, gy = u_depth, h = 1);
                translate([-1 * shell_outer.x / 2, -1 * shell_outer.y / 2, 0])
                    cube([shell_outer.x, shell_outer.y, actual_offset]);
            }
        }
    }

    module CabinetTop(shell_top) {
        if(top_style == LIP_TOP) LipTop(shell_top);
        else if(top_style == GRIDFINITY_STACKING_TOP) GridFinityStackingLip(shell_top);
    }

    rows = [[1, 20], [1, 30], [1, 40]];
    CabinetTop(shell_top=outer_wall);
    CabinetBody2(rows);
    CabinetBase(shell_base=bottom_of_shell(rows) - outer_wall);
}
