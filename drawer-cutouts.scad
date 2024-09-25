use <./util.scad>;
use <./MCAD/boxes.scad>;

function cell (style, colspan=1, rowspan=1) = [style, colspan, rowspan];

/**
Calculates the x offset of the left edge of a cell,
based on the colspan values of the previous cells in the row.
*/
function cell_starting_column(previous_cells_in_row) = sum_vector([
    for (i = previous_cells_in_row) i[1]
])

/**
Calculates how a specific cell will affect cells in lower rows.
*/
function column_offset_on_lower_rows(cell_location, cell_data) =
    let(
        colspan=cell_data[1],
        rowspan=cell_data[2]
    )
    rowspan == 1
    // If the rowspan is 1, the cell only affects itself
    ? [cell_location, cell_location, 0]
    // otherwise, calculate the first affected cell
    : [
        // first affected cell    
        [cell_location.x, cell_location.y + (rowspan - 1)],
        // last affeccted cell
        [cell_location.x + (colspan - 1), cell_location.y + (rowspan - 1)],
        // affected cell column offset
        colspan
    ];

/**
Collects all column offsets from row-spanning cells in higher rows
that affect the target cell.
*/
function cumulative_column_offset_from_higher_rows(
    rows,
    cell_location,
    check_location=[0, 0],
    running_sum=0) =
    // return once we reach the target cell's row
    check_location.y == cell_location.y
    ? running_sum
    : let(
        check_offset=column_offset_on_lower_rows(check_location, rows[check_location.x][check_location.y]),
        first_affected=check_offset[0],
        last_affected=check_offset[1],
        potential_offset=check_offset[2],
        // only collect additional offset if it actually affects this cell
        additional_offset=first_affected.x <= cell_location.x
            && last_affected.x >= cell_location.x
            && first_affected.y <= cell_location.y
            && last_affected.y >= cell_location.y
            ? additional_offset
            : 0,
        next_check=(check_location.x + 1) < len(rows[check_location.y])
            ? [check_location.x + 1, check_location.y]
            : [0, check_location.y + 1]
    )
    cumulative_column_offset_from_higher_rows(
        rows=rows,
        cell_location=cell_location,
        check_location=[],
        running_sum=running_sum + additional_offset
    );

function grid (dimensions, rows) =
    let(x=2)
    let(
        columns=dimension.x,
        rows=dimensions.y,
        column_width=(1 / columns),
        row_height=(1 / rows)
    )
    [
        for (row_index = [0:len(rows)])
            for (cell_index = [0:len(rows[row_index])])
                let(
                    row_cell=rows[row_index][cell_index],
                    style=row_cell[0],
                    colspan=row_cell[1],
                    rowspan=row_cell[2],
                    column_offset_within_row=cell_starting_column(sub_vector(rows[row_index], cell_index)),
                    column_offset_from_previous_rows=cumulative_column_offset_from_higher_rows(
                        rows=rows,
                        cell_location=[cell_index, row_index]
                    ),
                    column_offset=column_offset_from_previous_rows+column_offset_within_row
                )
                assert(
                    (column_offset + colspan) <= columns,
                    str(
                        "ERROR: Exceeded grid columns on cell ",
                        cell_index,
                        " in row ",
                        row_index
                    )
                )
                assert(
                    (row_index + (rowspan - 1)) <= rows,
                    str(
                        "ERROR: Exceeded grid rows on cell ",
                        cell_index,
                        " in row ",
                        row_index
                    )
                )
                [
                    // x offset from home to center of cell
                    (column_width * column_offset) + (column_width * colspan / 2),
                    // y offset from home to center of cell
                    (row_height * row_index) + (row_height * rowspan / 2),
                    // cell x percentage of grid
                    colspan / columns,
                    // cell y percentage of grid
                    rowspan / rows,
                    // cell style
                    style
                ]
    ];

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
