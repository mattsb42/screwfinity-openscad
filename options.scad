// Standard sizes
SMALL = 20;
MEDIUM = 30;
LARGE = 40;

// Drawer fill options
NO_CUT = 0;
SCOOP_CUT = 1;
SQUARE_CUT = 2;

function assert_valid_drawer_cell_cut_style(style) =
    assert(
        style == NO_CUT || style == SQUARE_CUT || style == SCOOP_CUT,
        str(
            "ERROR: Invalid cell cut type: ",
            style
        )
    )
    true;

// Drawer label options
NO_LABEL_CUT = 0;
LABEL_CUT = 1;

function assert_valid_drawer_label_cut_style(style) =
    assert(
        style == NO_LABEL_CUT || style == LABEL_CUT,
        str(
            "ERROR: Invalid label cut type: ",
            style
        )
    )
    true;

// Drawer handle options
TRIANGLE_HANDLE = 1;

function assert_valid_drawer_handle_style(style) =
    assert(
        style == TRIANGLE_HANDLE,
        str(
            "ERROR: Invalid handle style: ",
            style
        )
    )
    true;

// Cabinet base options
NO_BASE = 0;
GRIDFINITY_BASE = 1;

function assert_valid_cabinet_base_style(style) =
    assert(
        style == NO_BASE || style == GRIDFINITY_BASE,
        str(
            "ERROR: Invalid base style: ",
            style
        )
    )
    true;

// Cabinet top options
NO_TOP = 0;
LIP_TOP = 1;
GRIDFINITY_STACKING_TOP = 2;
GRIDFINITY_BASEPLATE_MAGNET_TOP = 3;

function assert_valid_cabinet_top_style(style) = 
    assert(
        style == NO_TOP
        || style == LIP_TOP
        || style == GRIDFINITY_STACKING_TOP
        || style == GRIDFINITY_BASEPLATE_MAGNET_TOP,
        str(
            "ERROR: Invalid top style: ",
            style
        )
    )
    true;
