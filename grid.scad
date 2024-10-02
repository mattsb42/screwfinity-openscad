include <./util.scad>;
/**
This module contains utilities to calculate
relative offset of cells on a grid.
The API draws heavy inspiration from HTML Tables,
and the output of `grid()` is an array of offset descriptions.
All offsets are from the "top left" of the plane.

The style identifier is passed arbitrarily from what it is set to in `cell()`
so that these utilities will work with both
cabinets (drawer height for drawer slots)
and drawers (cut style for drawer cutouts)
[
    [
        // column axis offset as a percentage of total columns
        0.25,
        // row axis offset as a percentage of total rows
        0.5,
        // column width as a percentage of total rows
        0.5,
        // row width as a percentage of total rows
        1,
        // style identifier
        2
    ],
    ...
]

Grids are composed of cells,
and cells can span both columns and rows.
*/

/**
Create a cell.
A cell is the fundamental unit of a grid.
Cells can have a style
and can span both columns and rows.
Both colspan and rowspan MUST be positive integers.
*/
function cell(style, colspan=1, rowspan=1) =
    assert(
        rowspan > 0 && rowspan % 1 == 0,
        str(
            "ERROR: rowspan MUST be a positive integer: ",
            rowspan
        )
    )
    assert(
        colspan > 0 && colspan % 1 == 0,
        str(
            "ERROR: colspan MUST be a positiive integer: ",
            colspan
        )
    )
    [style, colspan, rowspan];

/**
Create a uniform grid of cells.

Every cell is the same,
and they are uniformly distributed
across the rows and columns.

Each cell is one column wide and one row tall.
*/
function uniform_grid(row_count, column_count, style) = grid(
    row_count=row_count,
    column_count=column_count,
    row_data=[
        for (row_index = [1:row_count])
            uniform_row_data(
                column_count=column_count,
                style=style
            )
    ]
);

/**
Create row_data for a uniform row of cells.

This is a helper for input to grid()
if you want a row where all the the cells are the same.

Every cell is the same.

Each cell is one column wide.
*/
function uniform_row_data(column_count, style) = [
    for (cell_index = [1:column_count])
        cell(style=style, colspan=1, rowspan=1)
];

/**
Create a grid of cells.
grid draws heavily from HTML Tables.
Cells and rows behave basically the same,
including how rowspan affects cells defined in lower rows.

Returns an array of cell offset descriptions
that Drawer and Cabinet understand.
*/
function grid(row_count, column_count, row_data) =
    assert(
        row_count > 0 && row_count % 1 == 0,
        str(
            "ERROR: row_count MUST be a positive integer: ",
            row_count
        )
    )
    assert(
        column_count > 0 && column_count % 1 == 0,
        str(
            "ERROR: column_count MUST be a positive integer: ",
            column_count
        )
    )
    let(
        column_width=(1 / column_count),
        row_height=(1 / row_count)
    )
    [
        for (row_index = [0:len(row_data) - 1])
            for (cell_index = [0:len(row_data[row_index]) - 1])
                let(
                    row_cell=row_data[row_index][cell_index],
                    style=row_cell[0],
                    colspan=row_cell[1],
                    rowspan=row_cell[2],
                    column_offset_within_row=cell_starting_column(sub_vector(row_data[row_index], cell_index)),
                    column_offset_from_previous_rows=cumulative_column_offset_from_higher_rows(
                        row_data=row_data,
                        cell_location=[cell_index, row_index]
                    ),
                    column_offset=column_offset_from_previous_rows+column_offset_within_row
                )
                assert(
                    (column_offset + colspan) <= column_count,
                    str(
                        "ERROR: Exceeded grid columns on cell ",
                        cell_index,
                        " in row ",
                        row_index,
                        " with column offset ",
                        column_offset,
                        " and requested column span ",
                        colspan
                    )
                )
                assert(
                    (row_index + (rowspan - 1)) <= row_count,
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
                    colspan / column_count,
                    // cell y percentage of grid
                    rowspan / row_count,
                    // cell style
                    style
                ]
    ];

/**
Calculates the x offset of the left edge of a cell,
based on the colspan values of the previous cells in the row.
*/
function cell_starting_column(previous_cells_in_row) = sum_vector([
    for (i = previous_cells_in_row) i[1]
]);

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
        // this is the cell directly underneath the queried cell    
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
    row_data,
    cell_location,
    check_location=[0, 0],
    running_sum=0) =
    // return once we reach the target cell's row
    check_location.y == cell_location.y
    ? running_sum
    : let(
        check_offset=column_offset_on_lower_rows(check_location, row_data[check_location.x][check_location.y]),
        first_affected=check_offset[0],
        last_affected=check_offset[1],
        potential_offset=check_offset[2],
        // only collect additional offset if it actually affects this cell
        additional_offset=
            // If the cell is in the grid
            // from the first (top left) to last (bottom right)
            // that the check location affects,
            // increase the offset by the offset affect of the check location.
            first_affected.x <= cell_location.x
            && last_affected.x >= cell_location.x
            && first_affected.y <= cell_location.y
            && last_affected.y >= cell_location.y
            ? potential_offset
            // If the cell is not in the impact zone for the check location,
            // there is no affect.
            : 0,
        next_check=
            // If there are still cells in row,
            // step to the right.
            (check_location.x + 1) < len(row_data[check_location.y]) - 1
            ? [check_location.x + 1, check_location.y]
            // Otherwise, step down to the start of the next column.
            : [0, check_location.y + 1]
    )
    cumulative_column_offset_from_higher_rows(
        row_data=row_data,
        cell_location=cell_location,
        check_location=next_check,
        running_sum=running_sum + additional_offset
    );