include <./constants.scad>;

module Cabinet(drawer_height, u_width, u_depth) {
    outer_wall = 1.5;
    inner_wall = 0.5;
    ceiling_floor = 0.5;

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

    module DrawerSlot() {
        inner_width = DRAWER_UNIT_SLOT_WIDTH;
        inner_depth = (GRIDFINITY_GRID_LENGTH * u_depth) - CABINET_REAR_WALL;
        inner_height = drawer_height + (2 * DRAWER_TOLERANCE);
        outer_width = inner_width + (2 * inner_wall);
        outer_depth = inner_depth + inner_wall;
        outer_height = inner_height + (2 * inner_wall);

        difference() {
            cube([outer_width, outer_depth, outer_height], center=true);
            translate([0, inner_wall / 2, 0])
                cube([inner_width, inner_depth, inner_height], center=true);
            // trim off the front film
            translate([0, (outer_depth / 2) + 0.001, 0])
                cube([outer_width, 0.003, outer_height], center=true);
        }
        translate([0, (outer_width / 2) - (DRAWER_STOP / 2), (-1 * outer_height / 2) + inner_wall])
            DrawerStop();
    }

    module CabinetBody() {
        width = GRIDFINITY_GRID_LENGTH * u_width;
        depth = GRIDFINITY_GRID_LENGTH * u_depth;
        height = 1;
    }

    DrawerSlot();
}
