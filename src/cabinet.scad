include <./constants.scad>;

module Cabinet(drawer_height, drawer_u_width, u_width, u_depth, drawer_rows) {
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

    drawer_columns = u_width / drawer_u_width;

    
    shell_outer_width = GRIDFINITY_GRID_LENGTH * u_width;
    maximum_shell_inner_width = shell_outer_width - (outer_wall * 2);

    drawer_slot_inner_width = (drawer_u_width * GRIDFINITY_GRID_LENGTH) - GU_TO_DU;


    minimum_drawer_slot_outer_width = drawer_slot_inner_width + inner_wall;
    // The buffer space to add to each required wall.
    wall_buffer = 
        (maximum_shell_inner_width - (minimum_drawer_slot_outer_width * drawer_columns))
        / (drawer_columns + 1);
    // The wall buffer is the extra space on each vertical that is not a drawer slot.
    // Each outer wall gets two halves.
    shell_inner_width = maximum_shell_inner_width - wall_buffer;
    // Each drawer slot "outer" gets two halves.
    drawer_slot_outer_width = minimum_drawer_slot_outer_width + wall_buffer;
    
    assert(
        drawer_slot_outer_width > drawer_slot_inner_width,
        str(
            "ERROR: Drawer slot impossible dimensions. Inner width ",
            drawer_slot_inner_width,
            " is wider than outer width ",
            drawer_slot_outer_width
        )
    );
    
    drawer_slot_inner_height = drawer_height + (2 * DRAWER_TOLERANCE);
    drawer_slot_outer_height = drawer_slot_inner_height + inner_wall;
    
    shell_inner_height = drawer_slot_outer_height * drawer_rows;

    module DrawerStop() {
        stop_width = 20;
        slope_run = 0.5;
        stop_height = 1;

        inner_left = [-1 * stop_width / 2, DRAWER_STOP / 2, 0];
        inner_right = [stop_width / 2, DRAWER_STOP / 2, 0];
        outer_left = [-1 * stop_width / 2, -1 * DRAWER_STOP / 2, 0];
        outer_right = [stop_width / 2, -1 * DRAWER_STOP / 2, 0];
        peak_left = [-1 * (stop_width / 2 - slope_run), 0, stop_height];
        peak_right = [stop_width / 2 - slope_run, 0, stop_height];
        polyhedron(
            points=[
                inner_left,
                inner_right,
                outer_left,
                outer_right,
                peak_left,
                peak_right,
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

    module DrawerSlotNegative() {
        inner_width = drawer_slot_inner_width;
        inner_depth = (GRIDFINITY_GRID_LENGTH * u_depth) - CABINET_REAR_WALL;
        inner_height = drawer_slot_inner_height;
        difference(){
            cube([inner_width, inner_depth, inner_height], center=true);
            translate([0, (inner_depth / 2) - (DRAWER_STOP / 2), -1 * inner_height / 2])
                DrawerStop();
        }
    }

    module SolidCabinet() {
        outer_width = shell_outer_width;
        outer_depth = GRIDFINITY_GRID_LENGTH * u_depth;
        outer_height = shell_inner_height + (outer_wall * 2);
        difference() {
            cube([outer_width, outer_depth, outer_height], center=true);
            // trim off the front film
            translate([0, (outer_depth / 2) + 0.001, 0])
                cube([outer_width, 0.003, outer_height], center=true);
        }
    }

    // Locate the correct center position for a drawer slot.
    function traverse (column, row) =
        let(origin=[
            // move to left edge
            (shell_inner_width / 2)
                // move to the center of the first drawer
                - (drawer_slot_outer_width / 2),
            (shell_inner_height / 2) - (drawer_slot_outer_height / 2)
        ])
        let(
            column_position=origin.x - (drawer_slot_outer_width * column),
            row_position=origin.y - (drawer_slot_outer_height * row)
        )
            [column_position, 0, row_position];

    module CabinetBody() {
        difference() {
            color("grey")
                SolidCabinet();
            translate([0, CABINET_REAR_WALL / 2, 0])
                for (column = [0: drawer_columns - 1])
                    for (row = [0: drawer_rows - 1]){
                        echo(str("column ", column, ", row ", row, " at position ", traverse(column, row)));
                        translate(traverse(column, row))
                            DrawerSlotNegative();
                    }
        }
    }

    CabinetBody();
}
