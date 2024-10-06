include <./constants.scad>;
include <./options.scad>;
use <./cabinet.scad>;
use <./cabinet-bases.scad>;
use <./cabinet-tops.scad>;
use <./cabinet-slots.scad>;
use <./MCAD/boxes.scad>;

module GridCabinet(
    gridfinity_footprint,
    height,
    grid,
    base=surface_options(style=GRIDFINITY_BASE),
    top=surface_options(style=GRIDFINITY_STACKING_TOP),
    cabinet_wall=1.0,
) {
    valid_x = assert_integer_value(name="gridfinity_footprint.x", value=gridfinity_footprint.x);
    valid_y = assert_integer_value(name="gridfinity_footprint.y", value=gridfinity_footprint.y);
    valid_base = assert_valid_cabinet_base_style(base[0]);
    valid_top = assert_valid_cabinet_top_style(top[0]);

    outer_dimensions = [
        gridfinity_footprint.x * GRIDFINITY_GRID_LENGTH,
        gridfinity_footprint.y * GRIDFINITY_GRID_LENGTH,
        height,
    ];
    inner_shell_dimensions = [
        outer_dimensions.x - cabinet_wall,
        outer_dimensions.y - cabinet_wall,
        outer_dimensions.z - cabinet_wall,
    ];

    // make a solid shell
    // use grid to cut drawer slots
    //  - outer shell has one wall width on each wall
    //  - each drawer slot needs an inner buffer

    /**
     * Get the Z position of the top of the shell.
     */
    function top_of_shell() = outer_dimensions.z / 2;

    /**
     * Get the Z position of the bottom of the shell.
     */
    function bottom_of_shell() = -1 * outer_dimensions.z / 2;

    module CabinetBody() {
        roundedCube(
            size=outer_dimensions,
            r=0.5,
            sidesonly=false,
            center=true
        );
    }

    module DrawerSlots() {
        // reset to the top left
        // because that's what grid-math assumes
        translate([
            inner_shell_dimensions.x / 2,
            0,
            inner_shell_dimensions.z / 2
        ])
        for(cut = grid)
            let(
                x_offset=cut[0],
                z_offset=cut[1],
                x_percentage=cut[2],
                z_percentage=cut[3]
            )
            translate([
                -1 * (inner_shell_dimensions.x - (inner_shell_dimensions.x * x_offset)),
                cabinet_wall,
                -1 * (inner_shell_dimensions.z * z_offset)
            ])
            let(cut_dimensions=[
                (inner_shell_dimensions.x * x_percentage) - cabinet_wall,
                outer_dimensions.y - cabinet_wall,
                (inner_shell_dimensions.z * z_percentage) - cabinet_wall
            ])
            color("red")
            DrawerSlotNegative(cut_dimensions);
    }

    translate([0, 0, top_of_shell()])
        CabinetTop(
            gridfinity_footprint=gridfinity_footprint,
            outer_footprint=outer_dimensions,
            style=top[0]
        );
    difference(){
        CabinetBody();
        DrawerSlots();
    }
    translate([0, 0, bottom_of_shell()])
        CabinetBase(
            gridfinity_footprint=gridfinity_footprint,
            style=base[0],
            hole_options=base[1]
        );
}
