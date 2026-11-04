# Implementation Summary: Organelle OLED Emulator with Hardware-Accurate Text Rendering

## Overview

This implementation provides a **hardware-accurate** emulator of the Critter & Guitari Organelle's OLED display for Pure Data (using pd-lua). The key improvement is the **bitmap font rendering engine** that renders text directly into the pixel buffer, matching the behavior of the actual hardware.

## Problem Solved

The previous implementation used pd-lua's native vector text engine (`g:draw_text`) which rendered text as an **overlay** on top of the pixel grid. This caused a critical issue:

- Text was **not affected** by operations like `oled_gInvertArea` or `oled_gClear`
- Old text would **linger** on screen when it should have been cleared or inverted
- Text existed on a separate layer from graphics, breaking the "unlayered surface" principle of the hardware

## Solution

This version implements the **exact same 5x8 bitmap font** used in the Organelle's C++ firmware (`Organelle_OS/fonts.h`). Text is now rendered **directly into the pixel buffer** (`draw_buf`) as individual pixels, just like all other graphics.

### Key Changes

1. **Bitmap Font Data**: Extracted the complete `characters[]` array from `Organelle_OS/fonts.h`
   - 96 characters (ASCII 32-127)
   - Each character is 5 bytes (1 byte per column, 8 bits per column = 8 rows)
   - Total: 480 bytes of font data

2. **Hardware-Accurate Functions**:
   - `put_char_small(c, x, y, color)`: Renders a single 5x8 character
   - `println_8(text, x, y, color)`: Prints a string using the 8px font
   - `println(text, x, y, h, color)`: General print function (currently only size 8 is hardware-accurate)

3. **Line-Based Commands**: Added `oled_line_1` through `oled_line_5` commands
   - Matches the hardware's menu system
   - Uses the C++ formula `((line - 1) * 11) + 9` for Y positioning
   - Automatically clears the line area and flips the display

4. **Removed Overlay System**: Eliminated the separate `text_elements` overlay layer
   - All text is now in the pixel buffer
   - Text is affected by all graphics operations (clear, invert, etc.)

## Files Created

1. **`organelle_oled.pd_lua`** - The improved Lua script for Pure Data
2. **`README_OLED-emu.md`** - Updated technical documentation

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

**Result**: The text "Hello" will be inverted along with the surrounding area because it's rendered directly into the pixel buffer.

## Compatibility

- **Backward Compatible**: Existing patches using the previous version will continue to work
- **pd-lua Required**: Works with Pure Data Vanilla, Purr Data, or plugdata with pd-lua extension
- **OSC Format**: Messages should have the screen index (3) stripped before reaching the object
- **Path Format**: Forward slashes in OSC paths must be flattened (e.g., `/oled/gFlip` → `oled_gFlip`)

## Performance Notes

- Text rendering is now slightly slower than the vector overlay approach
- For best performance, minimize the number of `oled_gFlip` calls
- Use `oled_line_1` through `oled_line_5` for menu-style text (optimized for that use case)
- The bitmap font rendering is hardware-accurate but may not be as smooth as vector fonts at larger scales

## Future Enhancements

- Support for larger font sizes (16px, 24px, 32px) using the Arial fonts from the Organelle OS
- Hardware-accurate VU meter rendering
- Battery and WiFi status icon rendering
- SVG export functionality

## Reference

- Original C++ implementation: [critterandguitari/Organelle_OS/OledScreen.cpp](https://github.com/critterandguitari/Organelle_OS/blob/master/OledScreen.cpp)
- Font data: [critterandguitari/Organelle_OS/fonts.h](https://github.com/critterandguitari/Organelle_OS/blob/master/fonts.h)
