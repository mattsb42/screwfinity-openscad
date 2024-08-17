use <./MCAD/triangles.scad>;

module Lip(footprint, height, center=false) {
    translate(center ? [-1 * footprint.x / 2, -1 * footprint.y / 2, -1 * height / 2] : [0, 0, 0]) {
        rotate([-90, -90, 0]) {
            a_triangle(tan_angle=45, a_len=height, depth=footprint.y, center=false);
            translate([0, 0, footprint.y])
                rotate([-90, 0, 0])
                    a_triangle(tan_angle=45, a_len=height, depth=footprint.x, center=false);
            translate([0, footprint.x, footprint.y])
                rotate([-180, 0, 0])
                    a_triangle(tan_angle=45, a_len=height, depth=footprint.y, center=false);
            translate([0, footprint.x, 0])
                rotate([-270, 0, 0])
                    a_triangle(tan_angle=45, a_len=height, depth=footprint.x, center=false);
        }
    }
}
