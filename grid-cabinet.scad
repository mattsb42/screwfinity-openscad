include <./constants.scad>;
include <./options.scad>;
use <./cabinet.scad>;
use <./cabinet-bases.scad>;
use <./cabinet-tops.scad>;
use <./cabinet-slots.scad>;
use <./MCAD/boxes.scad>;

function inner_shell(outer_dimensions, cabinet_wall) = [
    // the outer walls should be 2x the inner wall thickness
    // because of the uniform buffer for the inner cuts,
    // the x and z dimensions need an extra inner wall buffer
    // on the outer wall
    outer_dimensions.x - (cabinet_wall * 3),
    outer_dimensions.y - (cabinet_wall * 2),
    outer_dimensions.z - (cabinet_wall * 3),
];


function cabinet_dimensions_from_gridfinity_footprint(
    gridfinity_units_width,
    gridfinity_units_depth,
    height
) = [
    gridfinity_units_width * GRIDFINITY_GRID_LENGTH,
    gridfinity_units_depth * GRIDFINITY_GRID_LENGTH,
    height
];


module GridCabinet(
    dimensions,
    grid,
    base=surface_options(style=GRIDFINITY_BASE),
    top=surface_options(style=GRIDFINITY_STACKING_TOP),
    cabinet_wall=1.0,
) {
    valid_x = assert_positive_integer_value(name="dimensions.x", value=dimensions.x);
    valid_y = assert_positive_integer_value(name="dimensions.y", value=dimensions.y);
    valid_z = assert_positive_integer_value(name="dimensions.z", value=dimensions.z);
    valid_base = assert_valid_cabinet_base_style(base[0]);
    valid_top = assert_valid_cabinet_top_style(top[0]);

    gridfinity_footprint = [
        floor(dimensions.x / GRIDFINITY_GRID_LENGTH),
        floor(dimensions.y / GRIDFINITY_GRID_LENGTH)
    ];

    inner_shell_dimensions = inner_shell(dimensions, cabinet_wall);

    /**
     * Get the Z position of the top of the shell.
     */
    function top_of_shell() = dimensions.z / 2;

    /**
     * Get the Z position of the bottom of the shell.
     */
    function bottom_of_shell() = -1 * dimensions.z / 2;

    /**
     * Create the central cabinet body.
     */
    module CabinetBody() {
        // For some reason, this ends up 0.086mm small in every dimension.
        // I have no clue why,
        // but that's a small enough issue
        // that I'm not going to worry about it for now.
        roundedCube(
            size=dimensions,
            r=0.5,
            sidesonly=false,
            center=true
        );
    }

    /**
     * Create the shapes for all drawer slots,
     * that can then be removed from a solid geometry.
     */
    module GridDrawerSlotsNegative() {
        // reset to the top left
        // because that's what grid-math assumes
        translate([
            inner_shell_dimensions.x / 2,
            // center on the cutout depth
            (dimensions.y - inner_shell_dimensions.y) / 2,
            inner_shell_dimensions.z / 2
        ])
        for(cut = grid)
            let(
                x_offset=cut[0],
                z_offset=cut[1],
                y_offset=cabinet_wall * 2,
                x_percentage=cut[2],
                z_percentage=cut[3]
            )
            translate([
                -1 * (inner_shell_dimensions.x * x_offset),
                0,
                -1 * (inner_shell_dimensions.z * z_offset)
            ])
            let(cut_dimensions=[
                (inner_shell_dimensions.x * x_percentage) - cabinet_wall,
                inner_shell_dimensions.y,
                (inner_shell_dimensions.z * z_percentage) - cabinet_wall
            ])
            color("red")
            DrawerSlotNegative(cut_dimensions);
    }

    translate([0, 0, top_of_shell()])
        CabinetTop(
            gridfinity_footprint=gridfinity_footprint,
            outer_footprint=dimensions,
            style=top[0]
        );
    difference(){
        CabinetBody();
        GridDrawerSlotsNegative();
    }
    translate([0, 0, bottom_of_shell()])
        CabinetBase(
            gridfinity_footprint=gridfinity_footprint,
            style=base[0],
            hole_options=base[1]
        );
}
