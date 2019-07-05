# Graphics Statements

## TEXTCOLOR foreground, background

## BORDER red, green, blue

Set the border color.

## GRAPHICS text on/off, sprite on/off, bitmap on/off, tiles on/off, red, green, blue

Set what Vicky features are enables. If text is enabled with any graphics sub-system, the text overlay feature will be enabled.
If any graphics sub-system is enabled, the graphics enable flag will be set in Vicky. The graphics background is set with the
red, green, and blue components.

## COLORS lut, color, red, green, blue, alpha

Set the RGBA values for a color in a color lookup table. LUT is one of:

0 - Graphics LUT 0
1 - Graphics LUT 1
2 - Graphics LUT 2
3 - Graphics LUT 3
4 - Graphics LUT 4
5 - Graphics LUT 5
6 - Graphics LUT 6
7 - Graphics LUT 7
8 - Text foreground LUT
9 - Text background LUT
10 - Gamma LUT

## PLOT x,y,color

## LINE x0,y0 - x1,y1,color

## BOX x0,y0 - x1,y1,color

## ELLIPSE x0,y0 - x1,y1,color

## SPRITE number SETUP on/off, LUT, layer, address

Setup a sprite:

- number: the index of the sprite (0 - 17)
- on/off: whether or not the sprite should be displayed (TRUE/FALSE)
- LUT: the LUT # of the sprite (0 - 3)
- layer: the display layer of the sprite
- address: the address within Vicky's VRAM where the sprite's pixel data is located

## SPRITE number AT x,y

Set the position of the sprite to (x, y) on the screen.

## TILEMAP number SETUP on/off, LUT, address

Setup a tilemap:

- number: the index number of the tilemap
- on/off: whether or not the tilemap is displayed (TRUE/FALSE)
- LUT: the LUT # of the tilemap (0 - 7)
- address: the address within Vicky's VRAM containing the pixel data of the tiles

## TILEMAP number AT x,y = tile_number

Set the tile for a cell on a tilemap

- number: the index of the tilemap to update
- x: the column to set
- y: the row to set
- tile_number: the number of the tile to draw at the location (x,y) in the tile map

## 