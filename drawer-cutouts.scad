
use <./MCAD/boxes.scad>;

module SquareCutoutRear(dimensions, chamfer) {
    translate([0, -1 * dimensions.y / 4, 0])
        roundedCube(size=[dimensions.x, dimensions.y / 2, dimensions.z], r=chamfer, sidesonly=true, center=true);
}

module SquareCutoutFront(dimensions, chamfer) {
    translate([0, dimensions.y / 4, 0])
        roundedCube(size=[dimensions.x, dimensions.y / 2, dimensions.z], r=chamfer, sidesonly=true, center=true);
}

module ScoopCutoutFront(dimensions, chamfer) {
    intersection() {
        translate([0, (dimensions.y / 2) - dimensions.z, dimensions.z / 2])
            rotate([0, 90, 0])
                cylinder(h=dimensions.x, r=dimensions.z, center=true);
        SquareCutoutFront(dimensions, chamfer);
    }
}

module SquareCutout(dimensions, chamfer) {
    hull() {
        SquareCutoutFront(dimensions, chamfer);
        SquareCutoutRear(dimensions, chamfer);
    }
}

module ScoopCutout(dimensions, chamfer) {
    hull() {
        ScoopCutoutFront(dimensions, chamfer);
        SquareCutoutRear(dimensions, chamfer);
    }
}
