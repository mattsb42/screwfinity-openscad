include <./constants.scad>;

module Cabinet(drawer_height, drawer_u_width, u_width, u_depth, drawer_rows) {
    outer_wall = 1.5;
    inner_wall = 0.5;
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
    shell_inner_width = shell_outer_width - (outer_wall * 2);
    drawer_slot_inner_width = DRAWER_UNIT_SLOT_WIDTH * drawer_u_width;

    // For single-u-width drawers and a single-column cabinet,
    // the math doesn't work out quite right.
    // TODO: fix this later
    // but for now just cheat.
    single_column_single_u = drawer_u_width == 1 && drawer_columns == 1;
    drawer_slot_outer_width = (single_column_single_u)
        ? shell_inner_width
        : shell_inner_width / drawer_columns;
    assert(
        single_column_single_u || drawer_slot_outer_width > drawer_slot_inner_width,
        str(
            "ERROR: Drawer slot impossible dimensions. Inner width ",
            drawer_slot_inner_width,
            " is wider than outer width ",
            drawer_slot_outer_width
        )
    );
    
    drawer_slot_inner_height = drawer_height + (2 * DRAWER_TOLERANCE);
    drawer_slot_outer_height = drawer_slot_inner_height + (2 * inner_wall);
    
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

    module CubeCup(inner_width, inner_depth, inner_height, outer_width, outer_depth, outer_height, rear_wall_thickness) {
        difference() {
            cube([outer_width, outer_depth, outer_height], center=true);
            translate([0, rear_wall_thickness / 2, 0])
                cube([inner_width, inner_depth, inner_height], center=true);
            // trim off the front film
            translate([0, (outer_depth / 2) + 0.001, 0])
                cube([outer_width, 0.003, outer_height], center=true);
        }
    }

    module DrawerSlot() {
        inner_width = drawer_slot_inner_width;
        inner_depth = (GRIDFINITY_GRID_LENGTH * u_depth) - CABINET_REAR_WALL;
        inner_height = drawer_slot_inner_height;
        outer_width = drawer_slot_outer_width;
        outer_depth = inner_depth + inner_wall;
        outer_height = drawer_slot_outer_height;

        CubeCup(inner_width, inner_depth, inner_height, outer_width, outer_depth, outer_height, rear_wall_thickness=inner_wall);
        translate([0, (outer_depth / 2) - (DRAWER_STOP / 2), (-1 * outer_height / 2) + inner_wall])
            DrawerStop();
    }

    module CabinetShell() {
        outer_width = shell_outer_width;
        inner_width = shell_inner_width;
        outer_depth = GRIDFINITY_GRID_LENGTH * u_depth;
        inner_depth = outer_depth - CABINET_REAR_WALL;
        inner_height = shell_inner_height;
        outer_height = inner_height + (outer_wall * 2);

        CubeCup(inner_width, inner_depth, inner_height, outer_width, outer_depth, outer_height, rear_wall_thickness=CABINET_REAR_WALL);
    }

    // Locate the correct center position for a drawer slot.
    function traverse (column, row) =
        let(origin=[
            (shell_inner_width / 2) - (drawer_slot_outer_width / 2),
            (shell_inner_height / 2) - (drawer_slot_outer_height / 2)
        ])
        let(
            column_position=origin.x - (drawer_slot_outer_width * column),
            row_position=origin.y - (drawer_slot_outer_height * row)
        )
            [column_position, 0, row_position];

    // Alternate drawer colors in a grid pattern.
    function drawer_color (column, row) =
        let(evens="blue", odds="yellow")
        let(color_options=[[odds, evens], [evens, odds]])
        color_options[column % 2][row % 2];

    module CabinetBody() {
        union(){
            color("grey")
                CabinetShell();
            translate([0, CABINET_REAR_WALL / 2, 0])
            for (column = [0: drawer_columns - 1])
                for (row = [0: drawer_rows - 1]){
                    echo(column, " ::: ", row);
                    translate(traverse(column, row))
                        color(drawer_color(column, row))
                        DrawerSlot();
                }
        }
    }

    CabinetBody();
}
