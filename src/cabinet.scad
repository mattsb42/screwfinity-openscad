include <./constants.scad>;

module Cabinet(drawer_height, drawer_u_width, u_width, u_depth, drawer_rows) {
    outer_wall = 1.5;
    inner_wall = 0.5;
    ceiling_floor = 0.5;
    drawer_columns = u_width / drawer_u_width;

    
    shell_outer_width = GRIDFINITY_GRID_LENGTH * u_width;
    shell_inner_width = shell_outer_width - (outer_wall * 2);
    drawer_slot_inner_width = DRAWER_UNIT_SLOT_WIDTH * drawer_u_width;
    drawer_slot_outer_width = shell_inner_width / drawer_columns;
    
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

    function drawer_color (column, row) =
        let(color_options=[["red", "green"], ["green", "red"]])
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
