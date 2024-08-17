# Definitions

## GridU

The Gridfinity unit of measurement: 42mmx42mm

## ScrewU-nit

The Screwfinity unit of measurement.
A ScrewU-nit defines the dimensions of drawers and drawer slots,
and is defined relative to its GridU footprint.

### ScrewU-nit Depth

A ScrewU-nit depth is 2mm less than the GridU depth.
This allows for a 2mm rear cabinet wall.

A drawer is 2mm shallower than the ScrewU-nit depth.
This allows for the drawer stop.

ex:

| U | GridU Depth | ScrewU-nit Depth | Drawer Depth |
|---|-------------|------------------|--------------|
| 1 | 42          | 40               | 38           |
| 2 | 84          | 82               | 80           |
| 3 | 126         | 124              | 122          |

### ScrewU-nit Width

A ScrewU width is 3mm less than the GridU width.
This allows for a 1mm wall between drawer slots.

A drawer is 1mm narrower than the ScrewU-nit width.
This allows for a 0.5mm tolerance on either side.

ex:

| U | GridU Width | ScrewU-nit Width | Drawer Width |
|---|-------------|------------------|--------------|
| 1 | 42          | 39               | 38           |
| 2 | 84          | 81               | 80           |
| 3 | 126         | 123              | 122          |


### ScrewU-nit Height

The ScrewU-nit height is not tied to the Gridfinity grid.
Drawers can be any height,
but the drawer slot MUST be 1mm taller than the corresponding drawer.
This allows for a 0.5mm tolerance above and below.

# Drawers

## Drawer Dimensions

The width and depth of drawers are defined by ScrewU-nits.

## Cutout

The drawer cutout is a void in the body of a drawer
that forms the storage volume of the drawer.

The default cutout for a drawer is the "square cut."
This leaves a square corner at ever lower edge.

If you want to use the drawer for small items,
you might want the "scoop cut" drawer cutout.
This leaves a cylinderical volume solid leading up to the front edge of the drawer.
This makes it much easier to retrieve small items from a drawer,
since they do not get stuck in the front corner.

If you want to create custom cutouts,
you might want the "no cut" option.
This leaves the drawer body as a solid.
You can them import the model into your modeling software of choice
and create your own cutouts as needed.

# Cabinets

The width and depth of cabinets are defined by
the Gridfinity standard:
42mm on an edge.

The height of a cabinet is determined by the drawers the cabinet contains.

Every outer cabinet wall MUST be at least 2mm thick.

## Drawer Slots

A drawer slot is a void in a cabinet
that a drawer can be placed into.
The slot MUST have a drawer stop
that keeps the drawer from sliding out of the drawer.

The drawer slot dimensions are determined by ScrewU-nits.

### Drawer Stops

The drawer stop SHOULD be a pyramidal prism
and MUST stop 2mm from the front of a drawer slot.

The width of the drawer stop across the drawer slot
is not critical to the operation of the drawer.
The convention is for the stop to be 20mm wide,
though this MAY vary based on preference.

```
__________________________________________
                                          |
                                          |
/\________________________________________|
```
