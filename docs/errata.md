This port of Screwfinity SHOULD be compatible with
[the original](https://thangs.com/designer/ZombieHedgehog/3d-model/Screwfinity%20Unit%202U%20Medium%20-%20The%20Gridfinity%20Storage%20Unit-1027305).
However, I have found some inconsistencies in the orginal that
I either could not replicate
or chose not to perpetuate
in this port.
I have enumerated these points here for reference.

# Drawer Slot Width

I found that the drawer slot width varies slightly between the different heights.
While the small-height drawer slot is 39mm wide,
the medium-height drawer slot is 40mm wide.
However, the 1U drawers are universally 38mm wide.

As detailed in [the spec](./spec.md),
I have chosen to standardize on 39mm wide drawer slots.
