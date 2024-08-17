include <./constants.scad>;
include <./options.scad>;
use <./util.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-utility.scad>;
use <./gridfinity-rebuilt-openscad/gridfinity-rebuilt-holes.scad>;

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
        top_style == NO_TOP || top_style == LIP_TOP,
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

    module DrawerSlotNegative() {
        difference(){
            cube(drawer_slot_inner, center=true);
            translate([
                0,
                (drawer_slot_inner.y / 2) - (DRAWER_STOP / 2),
                -1 * drawer_slot_inner.z / 2
            ])
                DrawerStop();
        }
    }

    module SolidCabinet() {
        difference() {
            cube(shell_outer, center=true);
            // trim off the front film
            translate([0, (shell_outer.y / 2) + 0.001, 0])
                cube([shell_outer.x, 0.003, shell_outer.z], center=true);
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

    module CabinetBase() {
        if(base_style == GRIDFINITY_BASE) {
            translate([0, 0, (-1 * shell_outer.z / 2) - 5]) 
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
    }

    module CabinetTop() {
        if(top_style == LIP_TOP) {
            translate([-1 * shell_outer.x / 2, -1 * shell_outer.y / 2, shell_outer.z / 2])
            color("green")
            Lip(footprint=shell_outer, cross_section=[2, 4], center=false);            
        }
    }

    CabinetTop();
    CabinetBody();
    CabinetBase();
}
