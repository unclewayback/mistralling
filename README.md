# Technical README: Organelle OLED Emulator for Pure Data

A high-performance, single-window 128x64 OLED hardware display emulator built for Pure Data (Vanilla/Purr Data/plugdata) using the pd-lua extension API. This object emulates the graphical behaviors, text menus, and OSC command specifications of the Critter & Guitari Organelle music computer with **hardware-accurate bitmap font rendering**.

## What's New in This Version

### Hardware-Accurate Text Rendering Engine

**Previous Issue**: The original implementation used pd-lua's native vector text engine (`g:draw_text`) which rendered text as an overlay on top of the pixel grid. This caused text to be unaffected by operations like `oled_gInvertArea` or `oled_gClear`, leading to visual artifacts where old text would linger.

**Solution**: This version implements the exact same 5x8 bitmap font used in the Organelle's C++ firmware. Text is now rendered **directly into the pixel buffer** (`draw_buf`) as individual pixels, just like all other graphics. This means:

- Text is affected by `oled_gInvertArea` and `oled_gClear` operations
- Text behaves identically to the hardware
- No more lingering text artifacts
- Perfect emulation of the Organelle's display behavior

### Key Improvements

1. **Bitmap Font Data**: Extracted directly from `Organelle_OS/fonts.h` - the exact same 5x8 font used by the hardware
2. **Hardware-Accurate Functions**: 
   - `put_char_small()` - Renders a single 5x8 character
   - `println_8()` - Prints a string using the 8px font
   - `setLine()` - Clears and sets a line of text at the correct Y position
3. **Line-Based Commands**: Added `oled_line_1` through `oled_line_5` commands that match the hardware's menu system
4. **Removed Overlay System**: Eliminated the separate `text_elements` overlay layer - all text is now in the pixel buffer

---

## System Architecture & Theory of Operation

The original hardware maps graphics directly onto a single 1024-byte pixel block memory matrix (`pix_buf`) representing a 128x64 1-bit screen. Text, geometric shapes, and audio waveforms are all rendered onto this same pixel layer.

This emulator implements a **Dual-Buffer State Machine** inside Lua to separate math execution from visual execution, maximizing patch performance:

- **draw_buf** (Scratchpad Memory): Primitive coordinate and drawing functions write instantly to this matrix block in the background.
- **disp_buf** (Front Video Memory): Background buffers are transferred cleanly to the display layer only when an explicit refresh command (`oled_gFlip`) is fired, eliminating layout flickering.

### Architectural Blueprint

```
[ Pure Data Canvas / Patches ] 
             |
             +---> (Inlet 1: Flattened OSC Graphics Data Streams)
             +---> (Inlet 2: UI Viewport Sizing, Scaling & Theme Colors)
             |
             v
   +-------------------------------------------------------+
   |             organelle_oled.pd_lua                     |
   |                                                       |
   |   [Inlet 1 Handler]          [Inlet 2 Handler]        |
   |          |                          |                 |
   |          v                          v                 |
   |   +--------------+          +--------------------+    |
   |   |  draw_buf    |          | Theme Config State |    |
   |   | (Background) |          |  (Colors/Padding)  |    |
   |   +--------------+          +--------------------+    |
   |          |                          |                 |
   |          v (gFlip message)          |                 |
   |   +--------------+                  |                 |
   |   |  disp_buf    |                  |                 |
   |   |  (Display)   |                  |                 |
   |   +--------------+                  |                 |
   |          |                          |                 |
   |          +------------+    +--------+                 |
   |                       |    |                          |
   |                       v    v                          |
   |             +-----------------------+                 |
   |             |   pd-lua paint(g)     |                 |
   |             |  Window Viewport Blit |                 |
   |             +-----------------------+                 |
   +-------------------------------------------------------+
```

---

## Technical Constraints & Implementation Notes

### The "Unlayered Surface" Priority (Font Rendering)

✅ **RESOLVED**: Text is now rendered directly into `draw_buf` as raw 1s and 0s using the hardware's bitmap font data.

- All text operations now affect and are affected by the same pixel buffer as graphics
- `oled_gInvertArea` will properly invert text pixels
- `oled_gClear` will properly clear text
- No more overlay layer artifacts

### Font Data Format

The 5x8 bitmap font is stored as an array of bytes:
- 96 characters (ASCII 32-127)
- Each character is 5 bytes (1 byte per column)
- Each byte represents 8 rows (1 bit per row)
- Character index: `(char_code - 32) * 5`

Example: Character 'A' (ASCII 65):
- Index: (65 - 32) * 5 = 33 * 5 = 165
- Bytes: 0x7E, 0x11, 0x11, 0x11, 0x7E

---

## Data Interface & OSC Stream Mappings

The object maps data on **Inlet 1**. It assumes your patch has stripped out the hardcoded screen index integer 3 from the message payload to preserve index counts.

### Geometric Drawing Primitives (Require `oled_gFlip` to refresh)

| Command | Arguments | Action |
|---------|-----------|--------|
| `oled_gClear` | None | Wipes all bits in background scratchpad memory to 0. |
| `oled_gSetPixel` | x, y, color (0 or 1) | Alters a single targeted bit map coordinate. |
| `oled_gLine` | x0, y0, x1, y1, color | Draws custom vector lines via Bresenham's line algorithm. |
| `oled_gBox` | x, y, width, height, color | Draws an open wireframe rectangle outline box. |
| `oled_gFillArea` | x, y, width, height, color | Paints a solid filled coordinate box block. |
| `oled_gInvertArea` | x, y, width, height | Toggles/flips pixel values (1 → 0, 0 → 1) inside specific screen areas. |
| `oled_gCircle` | x, y, radius, color | Calculates a standard circular line trace using Bresenham's midpoint circle algorithm. |
| `oled_gPrintln` | x, y, size, color, text... | Renders text directly into pixel buffer using bitmap fonts. |
| `oled_gWaveform` | 128 amplitude bytes (0-64) | Maps array values horizontally onto individual display columns and renders connecting lines. |

### System Frame Actions & Menu Lines

| Command | Arguments | Action |
|---------|-----------|--------|
| `oled_gFlip` | None | Clones draw_buf to disp_buf and forces the visible canvas frame to execute an explicit graphical window repaint. |
| `oled_gInvert` | None | Bitwise-inverts the global presentation color map state. |
| `oled_gShowInfoBar` | state (0 or 1) | Draws a baseline bounding tracking line at pixel y-coordinate 54 to match the standard Organelle layout. |
| `oled_line_1` through `oled_line_5` | text string... | Core system font rows. Clears the target slot area, applies size 8 font configuration, maps vertical slot coordinate bounds using the C++ formula `((line - 1) * 11) + 9`, and automatically flips the display instantly. |
| `oled_vumeter` | peak_val | Updates information fields to drive audio peak meter animations. |

### Configuration Controls (Inlet 2)

Messages passed to the secondary configuration inlet update the host template shell workspace styling live:

| Command | Arguments | Description |
|---------|-----------|-------------|
| `scale` | multiplier (int 1-8) | Sets window pixel-doubling scale (e.g., scale 2 scales the 128x64 workspace to 256x128). |
| `margin` | pixels (int 0-32) | Creates protective boundary spacing around the display grid. |
| `color_on` | R, G, B (0-255) | Configures the active lit pixel color profile (Default: 255 255 255 - White). |
| `color_off` | R, G, B (0-255) | Configures unlit screen workspace colors (Default: 0 0 100 - Marine Blue). |
| `color_margin` | R, G, B (0-255) | Configures outer border padding color frames. |

---

## Usage Examples

### Basic Text Rendering

```pd
[loadbang] -> [oled_gClear] -> [organelle_oled]
[Hello World( -> [oled_gPrintln 10 10 8 1] -> [organelle_oled]
[oled_gFlip( -> [organelle_oled]
```

### Using Line-Based Commands

```pd
[loadbang] -> [oled_line_1 Hello] -> [organelle_oled]
[oled_line_2 World( -> [organelle_oled]
```

### Inverting an Area with Text

```pd
[loadbang] -> [oled_gClear] -> [organelle_oled]
[Hello( -> [oled_gPrintln 10 10 8 1] -> [organelle_oled]
[oled_gInvertArea 10 10 50 10( -> [organelle_oled]
[oled_gFlip( -> [organelle_oled]
```

The text "Hello" will be inverted along with the surrounding area because it's rendered directly into the pixel buffer.

---

## Compatibility Notes

- This emulator is designed to work with **pd-lua** in Pure Data Vanilla, Purr Data, or plugdata
- All OSC messages should have the screen index (3) stripped before reaching the object
- Forward slashes in OSC paths must be flattened (e.g., `/oled/gFlip` → `oled_gFlip`)
- The object maintains backward compatibility with patches designed for the previous version

---

## Performance Considerations

- Text rendering is now slightly slower than the vector overlay approach, but much more accurate
- For best performance, minimize the number of `oled_gFlip` calls
- Use `oled_line_1` through `oled_line_5` for menu-style text as they're optimized for that use case
- The bitmap font rendering is hardware-accurate but may not be as smooth as vector fonts at larger scales

---

## Future Enhancements

- Support for larger font sizes (16px, 24px, 32px) using the Arial fonts from the Organelle OS
- Hardware-accurate VU meter rendering
- Battery and WiFi status icon rendering
- SVG export functionality (matching the C++ `saveSVG` function)
