use <./MCAD/triangles.scad>;

/**
 * Create a lip for chamfers or cabinet tops.
 *
 * @param vector    footprint       The footprint of the lip structure: [width, depth]
 * @param vector    cross_section   The naive cross-section of the lip: [width, height]
 * @param boolean   center          Whether to center the lip on the origin
 */
module Lip(footprint, cross_section, center=false) {
    tan_angle = atan(cross_section.y / cross_section.x);

    translate(center ? [-1 * footprint.x / 2, -1 * footprint.y / 2, -1 * cross_section.y / 2] : [0, 0, 0]) {
        rotate([-90, -90, 0]) {
            triangle(o_len=cross_section.x, a_len=cross_section.y, depth=footprint.y, center=false);
            translate([0, 0, footprint.y])
                rotate([-90, 0, 0])
                    triangle(o_len=cross_section.x, a_len=cross_section.y, depth=footprint.x, center=false);
            translate([0, footprint.x, footprint.y])
                rotate([-180, 0, 0])
                    triangle(o_len=cross_section.x, a_len=cross_section.y, depth=footprint.y, center=false);
            translate([0, footprint.x, 0])
                rotate([-270, 0, 0])
                    triangle(o_len=cross_section.x, a_len=cross_section.y, depth=footprint.x, center=false);
        }
    }
}

/**
 * Sum all members of a vector.
 */
function sum_vector(vector, index=0, running_sum=0) =
    index < len(vector)
    ? sum_vector(vector, index + 1, running_sum + vector[index])
    : running_sum;

/**
 * Slice a vector up to end_index.
 */
function sub_vector(vector, end_index) = end_index <= 0 ? [] : [
    for (i = [0: end_index - 1]) if (i < len(vector)) vector[i]
];

function assert_integer_value(name, value) =
    assert(
        value % 1 == 0,
        str(
            "ERROR: Invalid ",
            name,
            " value ",
            value,
            " MUST be an integer."
        )
    )
    true;

function assert_positive_integer_value(name, value) =
    assert(
        value % 1 == 0 && value > 0,
        str(
            "ERROR: Invalid ",
            name,
            " value ",
            value,
            " MUST be a positive integer."
        )
    )
    true;

function assert_positive_value(name, value) =
    assert(
        value > 0,
        str(
            "ERROR: Invalid ",
            name,
            " value ",
            value,
            " MUST be positive."
        )
    )
    true;
