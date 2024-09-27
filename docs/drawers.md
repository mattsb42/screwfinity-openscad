# Drawers

Drawers are relatively straightforward both to create and define.
We need to know the dimentions that you want for the drawer,
and what kind of fill type you want.

```openscad
include <./options.scad>;
use <./drawer.scad>;

Drawer(
    dimensions=drawer_options(
        unit_width=5,
        unit_depth=2,
        height=40
    ),
    drawer_wall=1, // default
    fill_type=SQUARE_CUT, // default
    handle_options=bundle_handle_options(
      label_cut=NO_LABEL_CUT // default
    )
);

```

## dimensions

The `dimensions` parameter expects a three-dimensional vector
that defines the drawer's dimensions.
The `drawer_options` helper function
lets you provide these as named parameters
and converts them to the form that `Drawer` needs.

- **unit_width** :
  The width in GridU.
  This can be any positive value you like,
  but I recommend not going smaller than 0.2
  with the default drawer wall thickness.
  Yes, [cabinets](./cabinets.md) can generate
  fractional drawer slots. ;)
- **unit_depth** :
  The depth in GridU.
  This value must be a positive integer.
  Maybe I'll revisit that decision if
  double-ended cabinets ever become a thing.
- **height** :
  The height in mm.
  In `options.scad`,
  you can find some helper values
  that match the original Screwfinity heights:
  - `SMALL` : 20
  - `MEDIUM` : 30
  - `LARGE` : 40

## drawer_wall

Most drawers should be fine with
the default drawer wall thickness of 1mm,
but if you want to change that,
you can set any mm value you like
(within the capabilities of your printer, of course.)

## fill_type

What do you want the interior of your drawer to be?
You can find these values in `options.scad`.

- `SQUARE_CUT` :
  Standard full cutout.
  This gives you the most usable volume,
  but can be hard to manage with small parts.
- `SCOOP_CUT` :
  Makes a sloping cut up to the front wall.
  This can make it a lot easier to handle small parts.
- `NO_CUT` :
  Leaves the drawer body solid,
  with no cutout.
  Use this if you want to make your own custom drawers.

## handle_properties

Controls how the properties of the handle.
Use the `handle_properties` helper function to generate this.

- **style** :
  The handle style you want.
  You can find these values in `options.scad`.

  - `TRIANGLE_HANDLE` :
    Similar to the original Screwfinity handle,
    this handle is a triangular shape
    with a peak halfway up the drawer,
    a ledge underneath
    that provides a grip point,
    and a label slot along the top-facing surface.
    _Default_

- **depth** :
  The handle depth,
  from the front of the handle
  to the front of the drawer body.
  _Default: 8_

- **label_cut** :
  How/should the handle have a cutout for a label?
  You can find these values in `options.scad`.  

  - `NO_LABEL_CUT` :
    Leave the handle solid.
  - `LABEL_CUT` :
    Cut a slot to fit a label,
    along with a window to view the label.
