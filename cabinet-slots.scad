include <./constants.scad>;


/**
 * Create a shape that can be removed from a solid geometry
 * to create a drawer slot.
 * 
 * @param dimensions : the inner dimensions of the desired drawer slot
 */
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

/**
 * Creates the drawer stop lip
 * that keeps drawers in the slots.
 */
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
