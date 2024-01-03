include <BOSL2/std.scad>
bolts = import("bolts.json");

$fn = 360;

inner_diameter = 55; //[::non-negative float]

wall_thickness = 2.5; //[::non-negative float]

height = 60; //[::non-negative integer]

// extra thickness at back of holder
block_thickness = 3; //[::non-negative integer]

// orientation of attachment
orientation = "right"; // [left,right, center, none]

bolt = "M3"; //[M2.5,M3,M4,M5]
bolt_to_side_space = 14;

hc_panel_depth = 11.22;
/* [Hidden] */

// stuff for honeycomb hexagons
hexa_radius = 11.4;
hexa_circular_radius = hex_to_circular_radius(hexa_radius);
hexa_side_length = sqrt((hexa_circular_radius * hexa_circular_radius - hexa_radius * hexa_radius) / 0.25);

// stuff for the holder
inner_radius = inner_diameter / 2;
outer_radius = inner_radius + wall_thickness;
outer_diameter = outer_radius * 2;
holder_depth = block_thickness + outer_diameter;
mask_height = min(height, 3 * hexa_radius + 1);


bottle_holder_and_attachment();

module bottle_holder_and_attachment()
{
    difference()
    {
        union()
        {
            bottle_holder();
            if (orientation == "right")
            {
                translate([ hc_panel_depth, outer_radius, 0 ]) attachment();
                translate([ hc_panel_depth + 2, outer_radius, 0 ])
                    rounding_edge_mask(l = mask_height, r = 5, orient = UP, anchor = BOTTOM);
            }
            else if (orientation == "left")
            {
                rotate([ 0, 0, 180 ]) translate([ -13.22, outer_radius, 0 ]) attachment();
                translate([ 13.22, -outer_radius, 0 ])
                    rounding_edge_mask(l = mask_height, r = 5, orient = UP, anchor = BOTTOM, spin = 270);
            }
        }
        if (orientation == "center")
        {
            head_radius = bolts[bolt].countersunk.head_diameter / 2;
            if (height >= (hexa_radius + head_radius + 2))
            {
                translate([ block_thickness + wall_thickness, 0, hexa_radius ]) rotate([ 0, 90, 0 ]) _bolt(bolt);
            }
            if (height >= (3 * hexa_radius + head_radius + 2))
            {
                translate([ block_thickness + wall_thickness, 0, 3 * hexa_radius + 1 ]) rotate([ 0, 90, 0 ])
                    _bolt(bolt);
            }
        }
    }
}

module attachment()
{
    rotate([ 0, 90, 0 ]) translate([ -3 * hexa_radius - 1, bolt_to_side_space, 0 ]) union()
    {
        _single_hex_prism();
        translate([ hexa_radius, -hexa_side_length / 2, 0 ]) cube(size = [ 1, hexa_side_length, 2 ]);
        translate([ 2 * hexa_radius + 1, 0, 0 ]) _single_hex_prism();
        translate([ 0, -bolt_to_side_space, 0 ])
            cube(size = [ 3 * hexa_radius + 1, bolt_to_side_space - hexa_side_length / 2, 2 ]);
    }
}

module _bolt(bolt_name)
{
    data = bolts[bolt_name].countersunk;
    head_length = data.head_length;
    head_diameter = data.head_diameter;
    pin_length = block_thickness + wall_thickness;
    total_length = 2 * head_length + pin_length;

    translate([ 0, 0, -(pin_length + head_length) ]) union()
    {
        cylinder(h = pin_length, d = data.diameter, center = false);
        translate(v = [ 0, 0, pin_length ]) cylinder(h = head_length, d1 = diameter, d2 = head_diameter);
        translate(v = [ 0, 0, pin_length + head_length ]) cylinder(h = head_length, d = head_diameter);
    }
}

module _single_hex_prism()
{
    rotate([ 0, 0, 30 ]) difference()
    {
        cylinder(h = 2, r = hexa_circular_radius, $fn = 6);
        translate([ 0, 0, -0.01 ]) cylinder(h = 2.02, d = bolt_diameter(bolt));
    }
}


module bottle_holder()
{
    difference()
    {

        bottle3D();
        // subtract inner cylinder
        translate([ block_thickness + outer_radius, 0, 2 ]) cylinder(h = height, d = inner_diameter);
        // subtract rounding
        translate([ holder_depth, 0, height ]) rotate([ 90, 180, 0 ])
            rounding_edge_mask(l = inner_diameter + wall_thickness * 2, r = outer_radius);
    }
}

module bottle3D()
{
    linear_extrude(height) _bottle2d();
}

module _bottle2d()
{
    block_y = outer_radius * 2;
    block_x = block_thickness + outer_radius; // also x-coord of center point of circles
    union()
    {
        difference()
        {
            union()
            {
                // wall block
                translate([ 0, -outer_radius, 0 ]) square([ block_x, block_y ]);
                //  add outer circle
                translate([ block_x, 0, 0 ]) circle(outer_radius);
            }
            // subtract inner block
            translate([ block_x, 0, 0 ]) circle(inner_radius / 2);
            translate([ block_x, -inner_diameter / 4, 0 ]) square([ outer_radius, inner_diameter / 2 ]);
        }
    }
}

function hex_to_circular_radius(d) = d / sqrt(3) * 2;
function bolt_diameter(bolt_name) = bolts[bolt_name].countersunk.diameter;
