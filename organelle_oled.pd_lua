-- organelle_oled.pd_lua
-- Hardware-Accurate Emulator with Bitmap Font Rendering
-- Emulates Critter & Guitari Organelle OLED (128x64 monochrome)
-- Text rendering now uses hardware-accurate bitmap fonts baked directly into pixel buffer

local oled = pd.Class:new():register("organelle_oled")

-- =========================================================================
-- FONT DATA: 5x8 bitmap font from Organelle OS (characters 32-127)
-- Each character is 5 bytes (1 byte per column, 8 bits per column = 8 rows)
-- =========================================================================
local font_small = {
    -- 32: space
    0x00, 0x00, 0x00, 0x00, 0x00,
    -- 33: !
    0x00, 0x00, 0x4F, 0x00, 0x00,
    -- 34: "
    0x00, 0x07, 0x00, 0x07, 0x00,
    -- 35: #
    0x14, 0x7F, 0x14, 0x7F, 0x14,
    -- 36: $
    0x24, 0x2A, 0x7F, 0x2A, 0x12,
    -- 37: %
    0x23, 0x13, 0x08, 0x64, 0x62,
    -- 38: &
    0x00, 0x02, 0x05, 0x02, 0x00,
    -- 39: '
    0x00, 0x05, 0x03, 0x00, 0x00,
    -- 40: (
    0x1C, 0x22, 0x41, 0x00, 0x00,
    -- 41: )
    0x00, 0x00, 0x41, 0x22, 0x1C,
    -- 42: *
    0x14, 0x08, 0x3E, 0x08, 0x14,
    -- 43: +
    0x08, 0x08, 0x3E, 0x08, 0x08,
    -- 44: ,
    0x00, 0x50, 0x30, 0x00, 0x00,
    -- 45: -
    0x08, 0x08, 0x08, 0x08, 0x08,
    -- 46: .
    0x00, 0x60, 0x60, 0x00, 0x00,
    -- 47: /
    0x20, 0x10, 0x08, 0x04, 0x02,
    -- 48: 0
    0x3E, 0x51, 0x49, 0x45, 0x3E,
    -- 49: 1
    0x00, 0x42, 0x7F, 0x40, 0x00,
    -- 50: 2
    0x42, 0x61, 0x51, 0x49, 0x46,
    -- 51: 3
    0x21, 0x41, 0x45, 0x4B, 0x31,
    -- 52: 4
    0x18, 0x14, 0x12, 0x7F, 0x10,
    -- 53: 5
    0x27, 0x45, 0x45, 0x45, 0x39,
    -- 54: 6
    0x3C, 0x4A, 0x49, 0x49, 0x30,
    -- 55: 7
    0x01, 0x71, 0x09, 0x05, 0x03,
    -- 56: 8
    0x36, 0x49, 0x49, 0x49, 0x36,
    -- 57: 9
    0x06, 0x49, 0x49, 0x49, 0x36,
    -- 58: :
    0x00, 0x36, 0x36, 0x00, 0x00,
    -- 59: ;
    0x00, 0x56, 0x36, 0x00, 0x00,
    -- 60: <
    0x08, 0x14, 0x22, 0x41, 0x00,
    -- 61: =
    0x14, 0x14, 0x14, 0x14, 0x14,
    -- 62: >
    0x00, 0x41, 0x22, 0x14, 0x08,
    -- 63: ?
    0x02, 0x01, 0x51, 0x09, 0x06,
    -- 64: @
    0x32, 0x49, 0x79, 0x41, 0x3E,
    -- 65: A
    0x7E, 0x11, 0x11, 0x11, 0x7E,
    -- 66: B
    0x7F, 0x49, 0x49, 0x49, 0x36,
    -- 67: C
    0x3E, 0x41, 0x41, 0x41, 0x22,
    -- 68: D
    0x7F, 0x41, 0x41, 0x22, 0x1C,
    -- 69: E
    0x7F, 0x49, 0x49, 0x49, 0x41,
    -- 70: F
    0x7F, 0x09, 0x09, 0x09, 0x01,
    -- 71: G
    0x3E, 0x41, 0x49, 0x49, 0x7A,
    -- 72: H
    0x7F, 0x08, 0x08, 0x08, 0x7F,
    -- 73: I
    0x00, 0x41, 0x7F, 0x41, 0x00,
    -- 74: J
    0x20, 0x40, 0x41, 0x3F, 0x01,
    -- 75: K
    0x7F, 0x08, 0x14, 0x22, 0x41,
    -- 76: L
    0x7F, 0x40, 0x40, 0x40, 0x40,
    -- 77: M
    0x7F, 0x02, 0x0C, 0x02, 0x7F,
    -- 78: N
    0x7F, 0x04, 0x08, 0x10, 0x7F,
    -- 79: O
    0x3E, 0x41, 0x41, 0x41, 0x3E,
    -- 80: P
    0x7F, 0x09, 0x09, 0x09, 0x06,
    -- 81: Q
    0x3E, 0x41, 0x51, 0x21, 0x5E,
    -- 82: R
    0x7F, 0x09, 0x19, 0x29, 0x46,
    -- 83: S
    0x46, 0x49, 0x49, 0x49, 0x31,
    -- 84: T
    0x01, 0x01, 0x7F, 0x01, 0x01,
    -- 85: U
    0x3F, 0x40, 0x40, 0x40, 0x3F,
    -- 86: V
    0x1F, 0x20, 0x40, 0x20, 0x1F,
    -- 87: W
    0x3F, 0x40, 0x38, 0x40, 0x3F,
    -- 88: X
    0x63, 0x14, 0x08, 0x14, 0x63,
    -- 89: Y
    0x07, 0x08, 0x70, 0x08, 0x07,
    -- 90: Z
    0x61, 0x51, 0x49, 0x45, 0x43,
    -- 91: [
    0x7F, 0x41, 0x41, 0x00, 0x00,
    -- 92: \
    0x02, 0x04, 0x08, 0x10, 0x20,
    -- 93: ]
    0x00, 0x00, 0x41, 0x41, 0x7F,
    -- 94: ^
    0x04, 0x02, 0x01, 0x02, 0x04,
    -- 95: _
    0x40, 0x40, 0x40, 0x40, 0x40,
    -- 96: `
    0x00, 0x01, 0x02, 0x04, 0x00,
    -- 97: a
    0x20, 0x54, 0x54, 0x54, 0x78,
    -- 98: b
    0x7F, 0x48, 0x44, 0x44, 0x38,
    -- 99: c
    0x38, 0x44, 0x44, 0x44, 0x20,
    -- 100: d
    0x38, 0x44, 0x44, 0x48, 0x7F,
    -- 101: e
    0x38, 0x54, 0x54, 0x54, 0x18,
    -- 102: f
    0x08, 0x7E, 0x09, 0x01, 0x02,
    -- 103: g
    0x0C, 0x52, 0x52, 0x52, 0x3E,
    -- 104: h
    0x7F, 0x08, 0x04, 0x04, 0x78,
    -- 105: i
    0x00, 0x44, 0x7D, 0x40, 0x00,
    -- 106: j
    0x00, 0x20, 0x40, 0x44, 0x3D,
    -- 107: k
    0x7F, 0x10, 0x28, 0x44, 0x00,
    -- 108: l
    0x00, 0x41, 0x7F, 0x40, 0x00,
    -- 109: m
    0x7C, 0x04, 0x18, 0x04, 0x78,
    -- 110: n
    0x7C, 0x08, 0x04, 0x04, 0x78,
    -- 111: o
    0x38, 0x44, 0x44, 0x44, 0x38,
    -- 112: p
    0x7C, 0x14, 0x14, 0x14, 0x08,
    -- 113: q
    0x08, 0x14, 0x14, 0x18, 0x7C,
    -- 114: r
    0x7C, 0x08, 0x04, 0x04, 0x08,
    -- 115: s
    0x48, 0x54, 0x54, 0x54, 0x20,
    -- 116: t
    0x04, 0x3F, 0x44, 0x40, 0x20,
    -- 117: u
    0x3C, 0x40, 0x40, 0x20, 0x7C,
    -- 118: v
    0x1C, 0x20, 0x40, 0x20, 0x1C,
    -- 119: w
    0x3C, 0x40, 0x30, 0x40, 0x3C,
    -- 120: x
    0x44, 0x28, 0x10, 0x28, 0x44,
    -- 121: y
    0x0C, 0x50, 0x50, 0x50, 0x3C,
    -- 122: z
    0x44, 0x64, 0x54, 0x4C, 0x44,
    -- 123: {
    0x08, 0x36, 0x41, 0x00, 0x00,
    -- 124: |
    0x00, 0x00, 0x7F, 0x00, 0x00,
    -- 125: }
    0x00, 0x00, 0x41, 0x36, 0x08,
    -- 126: ~
    0x00, 0x8, 0x4, 0x8, 0x4,
    -- 127: DEL
    0x00, 0x00, 0x00, 0x00, 0x00
}

-- Calculate line Y position using C++ formula: ((line - 1) * 11) + 9
local function calcxpos(line)
    return ((line - 1) * 11) + 9
end

function oled:initialize()
    self.inlets = 2
    self.outlets = 0
    -- Organelle Native Geometry
    self.width = 128
    self.height = 64
    -- Quality of Life Settings Defaults
    self.scale = 2
    self.margin = 3
    -- Theme Palette Buffers (R, G, B format)
    self.color_on = {255, 255, 255}
    self.color_off = {0, 0, 100}
    self.color_margin = {15, 15, 15}
    self.draw_buf = {}
    self.disp_buf = {}
    self.screen_inverted = false
    self.show_infobar = false
    self:clear()
    self:flip()
    self:update_canvas_bounds()
    return true
end

function oled:update_canvas_bounds()
    self.total_width = (self.width + (self.margin * 2)) * self.scale
    self.total_height = (self.height + (self.margin * 2)) * self.scale
    self:set_size(self.total_width, self.total_height)
    self:repaint()
end

function oled:clear()
    for i = 1, (self.width * self.height) do
        self.draw_buf[i] = 0
    end
end

function oled:set_pixel(x, y, color)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return
    end
    self.draw_buf[(math.floor(y) * self.width) + math.floor(x) + 1] = color > 0 and 1 or 0
end

function oled:get_pixel(x, y)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return 0
    end
    return self.draw_buf[(math.floor(y) * self.width) + math.floor(x) + 1] or 0
end

function oled:flip()
    for i = 1, (self.width * self.height) do
        self.disp_buf[i] = self.draw_buf[i]
    end
    self:repaint()
end

-- =========================================================================
-- BITMAP FONT RENDERING (Hardware-Accurate)
-- =========================================================================

-- Put a single character using the 5x8 bitmap font
-- Matches C++: put_char_small(unsigned char c, unsigned int y, unsigned int x, unsigned int color)
function oled:put_char_small(c, x, y, color)
    -- Clamp character to valid range (32-127)
    local char_code = math.floor(c) or 0
    if char_code < 32 then char_code = 32 end
    if char_code > 127 then char_code = 127 end
    
    -- Calculate font data offset (5 bytes per character, starting from space=32)
    local font_index = (char_code - 32) * 5 + 1
    
    -- Render 5x8 character
    for col = 0, 4 do
        local byte = font_small[font_index + col] or 0
        for row = 0, 7 do
            -- Check if bit is set (LSB is row 0)
            if (byte & (1 << row)) ~= 0 then
                self:set_pixel(x + col, y + row, color)
            end
        end
    end
    
    -- Return character width (5 pixels)
    return 5
end

-- Print a string using 8px height font (5px width per char)
-- Matches C++: println_8(const char * line, int len, int x, int y)
function oled:println_8(text, x, y, color)
    color = color or 1
    local deltax = x
    for i = 1, #text do
        local c = text:sub(i, i)
        deltax = deltax + self:put_char_small(string.byte(c), deltax, y, color)
        deltax = deltax + 1  -- Add 1 pixel spacing between characters
    end
end

-- Print a string with variable height (supports 8, 16, 24, 32)
function oled:println(text, x, y, h, color)
    h = h or 8
    color = color or 1
    
    if h == 8 then
        self:println_8(text, x, y, color)
    elseif h == 16 then
        self:println_16(text, x, y, color)
    elseif h == 24 then
        self:println_24(text, x, y, color)
    elseif h == 32 then
        self:println_32(text, x, y, color)
    else
        -- Fallback to 8px font for other sizes
        self:println_8(text, x, y, color)
    end
end

-- Print with 16px height (scaled 2x from 8px font)
function oled:println_16(text, x, y, color)
    color = color or 1
    local deltax = x
    for i = 1, #text do
        local c = text:sub(i, i)
        deltax = deltax + self:put_char_16(string.byte(c), deltax, y, color)
        deltax = deltax + 2  -- Add 2 pixel spacing (scaled from 1px)
    end
end

-- Print with 24px height (scaled 3x from 8px font)
function oled:println_24(text, x, y, color)
    color = color or 1
    local deltax = x
    for i = 1, #text do
        local c = text:sub(i, i)
        deltax = deltax + self:put_char_24(string.byte(c), deltax, y, color)
        deltax = deltax + 3  -- Add 3 pixel spacing (scaled from 1px)
    end
end

-- Print with 32px height (scaled 4x from 8px font)
function oled:println_32(text, x, y, color)
    color = color or 1
    local deltax = x
    for i = 1, #text do
        local c = text:sub(i, i)
        deltax = deltax + self:put_char_32(string.byte(c), deltax, y, color)
        deltax = deltax + 4  -- Add 4 pixel spacing (scaled from 1px)
    end
end

-- Put character scaled to 16px height (2x scale)
function oled:put_char_16(c, x, y, color)
    local char_code = math.floor(c) or 0
    if char_code < 32 then char_code = 32 end
    if char_code > 127 then char_code = 127 end
    
    local font_index = (char_code - 32) * 5 + 1
    
    -- Render 5x8 character scaled by 2x
    for col = 0, 4 do
        local byte = font_small[font_index + col] or 0
        for row = 0, 7 do
            if (byte & (1 << row)) ~= 0 then
                -- Draw 2x2 block for each pixel
                for dy = 0, 1 do
                    for dx = 0, 1 do
                        self:set_pixel(x + col * 2 + dx, y + row * 2 + dy, color)
                    end
                end
            end
        end
    end
    return 10  -- 5 columns * 2 = 10 pixels width
end

-- Put character scaled to 24px height (3x scale)
function oled:put_char_24(c, x, y, color)
    local char_code = math.floor(c) or 0
    if char_code < 32 then char_code = 32 end
    if char_code > 127 then char_code = 127 end
    
    local font_index = (char_code - 32) * 5 + 1
    
    -- Render 5x8 character scaled by 3x
    for col = 0, 4 do
        local byte = font_small[font_index + col] or 0
        for row = 0, 7 do
            if (byte & (1 << row)) ~= 0 then
                -- Draw 3x3 block for each pixel
                for dy = 0, 2 do
                    for dx = 0, 2 do
                        self:set_pixel(x + col * 3 + dx, y + row * 3 + dy, color)
                    end
                end
            end
        end
    end
    return 15  -- 5 columns * 3 = 15 pixels width
end

-- Put character scaled to 32px height (4x scale)
function oled:put_char_32(c, x, y, color)
    local char_code = math.floor(c) or 0
    if char_code < 32 then char_code = 32 end
    if char_code > 127 then char_code = 127 end
    
    local font_index = (char_code - 32) * 5 + 1
    
    -- Render 5x8 character scaled by 4x
    for col = 0, 4 do
        local byte = font_small[font_index + col] or 0
        for row = 0, 7 do
            if (byte & (1 << row)) ~= 0 then
                -- Draw 4x4 block for each pixel
                for dy = 0, 3 do
                    for dx = 0, 3 do
                        self:set_pixel(x + col * 4 + dx, y + row * 4 + dy, color)
                    end
                end
            end
        end
    end
    return 20  -- 5 columns * 4 = 20 pixels width
end

-- Clear a line area (for oled_line_1 through oled_line_5)
function oled:clearLine(lineNum)
    local y_pos = calcxpos(lineNum)
    -- Clear the line area: 128 pixels wide, 11 pixels tall
    for i = 0, 127 do
        for j = 0, 10 do
            self:set_pixel(i, y_pos + j, 0)
        end
    end
    -- Also clear the row above line 1 (fixes legacy patch issue)
    if lineNum == 1 then
        for i = 0, 127 do
            self:set_pixel(i, 8, 0)
        end
    end
end

-- Set a line of text (for oled_line_1 through oled_line_5)
function oled:setLine(lineNum, text)
    self:clearLine(lineNum)
    local y_pos = calcxpos(lineNum) + 1
    local len = #text
    if len > 21 then len = 21 end
    self:println_8(text:sub(1, len), 2, y_pos, 1)
    self:flip()
end

-- =========================================================================
-- PAINT ROUTINE
-- =========================================================================
function oled:paint(g)
    -- 1. Render Outer Padding Border Area
    g:set_color(self.color_margin[1], self.color_margin[2], self.color_margin[3])
    g:fill_all()
    
    -- Cache calculated pixel offsets
    local pad = self.margin * self.scale
    
    -- 2. Render Screen Base Background
    local bg = self.screen_inverted and self.color_on or self.color_off
    local fg = self.screen_inverted and self.color_off or self.color_on
    g:set_color(bg[1], bg[2], bg[3])
    g:fill_rect(pad, pad, self.width * self.scale, self.height * self.scale)
    
    -- 3. Render Pixel Matrix
    g:set_color(fg[1], fg[2], fg[3])
    for y = 0, (self.height - 1) do
        for x = 0, (self.width - 1) do
            if self.disp_buf[(y * self.width) + x + 1] == 1 then
                g:fill_rect(pad + (x * self.scale), pad + (y * self.scale), self.scale, self.scale)
            end
        end
    end
    
    -- 4. Render InfoBar
    if self.show_infobar then
        g:set_color(fg[1], fg[2], fg[3])
        g:draw_line(pad, pad + (54 * self.scale), pad + (self.width * self.scale), pad + (54 * self.scale), 1)
    end
end

-- =========================================================================
-- DRAWING PRIMITIVES
-- =========================================================================
function oled:draw_line(x0, y0, x1, y1, color)
    local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
    local sx, sy = x0 < x1 and 1 or -1, y0 < y1 and 1 or -1
    local err = dx - dy
    while true do
        self:set_pixel(x0, y0, color)
        if x0 == x1 and y0 == y1 then
            break
        end
        local e2 = 2 * err
        if e2 > -dy then
            err, x0 = err - dy, x0 + sx
        end
        if e2 < dx then
            err, y0 = err + dx, y0 + sy
        end
    end
end

function oled:draw_box(x, y, w, h, color)
    local bx, by, bw, bh = x or 0, y or 0, w or 0, h or 0
    -- Clamp to screen bounds
    bw = bw > 128 and 128 or bw
    bh = bh > 64 and 64 or bh
    
    for i = 0, bw - 1 do
        self:set_pixel(bx + i, by, color)
        self:set_pixel(bx + i, by + bh - 1, color)
    end
    for i = 0, bh - 1 do
        self:set_pixel(bx, by + i, color)
        self:set_pixel(bx + bw - 1, by + i, color)
    end
end

function oled:draw_circle(cx, cy, r, color)
    local x, y, p = 0, r, 3 - 2 * r
    while x <= y do
        self:set_pixel(cx + x, cy + y, color)
        self:set_pixel(cx - x, cy + y, color)
        self:set_pixel(cx + x, cy - y, color)
        self:set_pixel(cx - x, cy - y, color)
        self:set_pixel(cx + y, cy + x, color)
        self:set_pixel(cx - y, cy + x, color)
        self:set_pixel(cx + y, cy - x, color)
        self:set_pixel(cx - y, cy - x, color)
        p = p < 0 and p + 4 * x + 6 or p + 4 * (x - y) + 10
        if p >= 0 then
            y = y - 1
        end
        x = x + 1
    end
end

function oled:fill_area(x, y, w, h, color)
    local ax, ay, aw, ah = x or 0, y or 0, w or 0, h or 0
    aw = aw > 128 and 128 or aw
    ah = ah > 64 and 64 or ah
    for y_pos = ay, ay + ah - 1 do
        for x_pos = ax, ax + aw - 1 do
            self:set_pixel(x_pos, y_pos, color)
        end
    end
end

function oled:invert_area(x, y, w, h)
    local ax, ay, aw, ah = x or 0, y or 0, w or 0, h or 0
    aw = aw > 128 and 128 or aw
    ah = ah > 64 and 64 or ah
    for y_pos = ay, ay + ah - 1 do
        for x_pos = ax, ax + aw - 1 do
            local current = self:get_pixel(x_pos, y_pos)
            self:set_pixel(x_pos, y_pos, current == 1 and 0 or 1)
        end
    end
end

-- =========================================================================
-- OSC METHOD HANDLERS (Inlet 1)
-- =========================================================================
local function get_args(atoms)
    local args = {}
    local start_idx = atoms[1] == 3 and 2 or 1
    for i = start_idx, #atoms do
        table.insert(args, atoms[i])
    end
    return args
end

function oled:in_1_oled_gClear(atoms)
    self:clear()
end

function oled:in_1_oled_gSetPixel(atoms)
    local a = get_args(atoms)
    self:set_pixel(a[1] or 0, a[2] or 0, a[3] or 1)
end

function oled:in_1_oled_gLine(atoms)
    local a = get_args(atoms)
    self:draw_line(a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 0, a[5] or 1)
end

function oled:in_1_oled_gInvert(atoms)
    self.screen_inverted = not self.screen_inverted
    self:repaint()
end

function oled:in_1_oled_gShowInfoBar(atoms)
    local a = get_args(atoms)
    self.show_infobar = ((a[1] or 0) > 0)
    -- When showing info bar, draw the separator line at y=54
    if self.show_infobar then
        self:draw_line(0, 54, 127, 54, 1)
    end
    self:repaint()
end

function oled:in_1_oled_gFlip(atoms)
    self:flip()
end

function oled:in_1_oled_gBox(atoms)
    local a = get_args(atoms)
    self:draw_box(a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 0, a[5] or 1)
end

function oled:in_1_oled_gCircle(atoms)
    local a = get_args(atoms)
    self:draw_circle(a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 1)
end

function oled:in_1_oled_gFillArea(atoms)
    local a = get_args(atoms)
    self:fill_area(a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 0, a[5] or 1)
end

function oled:in_1_oled_gInvertArea(atoms)
    local a = get_args(atoms)
    self:invert_area(a[1] or 0, a[2] or 0, a[3] or 0, a[4] or 0)
end

function oled:in_1_oled_gPrintln(atoms)
    local a = get_args(atoms)
    local x_val = tonumber(a[1]) or 0
    local y_val = tonumber(a[2]) or 0
    local font_size = tonumber(a[3]) or 8
    local text_color = tonumber(a[4]) or 1
    local txt = {}
    for i = 5, #a do
        table.insert(txt, tostring(a[i]))
    end
    local text_string = table.concat(txt, " ")
    if text_string == "" then text_string = " " end
    self:println(text_string, x_val, y_val, font_size, text_color)
end

function oled:in_1_oled_gWaveform(atoms)
    for x = 0, 126 do
        self:draw_line(x, 64 - (atoms[x + 1] or 0), x + 1, 64 - (atoms[x + 2] or 0), 1)
    end
end

-- Line-based text commands (oled_line_1 through oled_line_5)
function oled:in_1_oled_line_1(atoms)
    local a = get_args(atoms)
    local text = table.concat(a, " ")
    self:setLine(1, text)
end

function oled:in_1_oled_line_2(atoms)
    local a = get_args(atoms)
    local text = table.concat(a, " ")
    self:setLine(2, text)
end

function oled:in_1_oled_line_3(atoms)
    local a = get_args(atoms)
    local text = table.concat(a, " ")
    self:setLine(3, text)
end

function oled:in_1_oled_line_4(atoms)
    local a = get_args(atoms)
    local text = table.concat(a, " ")
    self:setLine(4, text)
end

function oled:in_1_oled_line_5(atoms)
    local a = get_args(atoms)
    local text = table.concat(a, " ")
    self:setLine(5, text)
end

-- VU meter - draws audio level meters at the TOP of the screen
-- Matches Organelle OS C++ drawInfoBar() implementation exactly
function oled:in_1_oled_vumeter(atoms)
    local a = get_args(atoms)
    -- Parse all 5 parameters: inR, inL, outR, outL, peaks
    -- Note: C++ signature is drawInfoBar(int inR, int inL, int outR, int outL, int peaks, ...)
    local inR = tonumber(a[1]) or 0
    local inL = tonumber(a[2]) or 0
    local outR = tonumber(a[3]) or 0
    local outL = tonumber(a[4]) or 0
    local peaks = tonumber(a[5]) or 0
    self:draw_vumeter(inR, inL, outR, outL, peaks)
end

-- Draw VU meter matching Organelle OS C++ drawInfoBar()
-- Layout (from C++ code):
--   'I' at (0,0), 'O' at (45,0)
--   Input VU: x=7 to x=40 (11 bars, 3px wide, spaced 3px apart)
--     - inR (right): top row at y=0-1, bars at x=7+i*3
--     - inL (left): bottom row at y=4-5, bars at x=7+i*3
--   Output VU: x=54 to x=87 (11 bars, 3px wide, spaced 3px apart)
--     - outR (right): top row at y=0-1, bars at x=54+i*3
--     - outL (left): bottom row at y=4-5, bars at x=54+i*3
--   Background ticks at y=1 and y=5 for each bar position
--   Peak indicators drawn at last bar position (i=10) when peak bit is set
function oled:draw_vumeter(inR, inL, outR, outL, peaks)
    -- Clamp all values to 0-11 range (matches C++: if (x < 0) x = 0; if (x > 11) x = 11;)
    inR = math.floor(math.max(0, math.min(11, inR)))
    inL = math.floor(math.max(0, math.min(11, inL)))
    outR = math.floor(math.max(0, math.min(11, outR)))
    outL = math.floor(math.max(0, math.min(11, outL)))
    
    -- Clear the VU meter area (top 6 rows, full width)
    self:fill_area(0, 0, 128, 6, 0)
    
    -- Draw 'I' and 'O' labels (matching C++: put_char_small('I', 0, 0, 1) and put_char_small('O', 45, 0, 1))
    self:put_char_small(string.byte('I'), 0, 0, 1)
    self:put_char_small(string.byte('O'), 45, 0, 1)
    
    -- Draw input VU meter (left side) - matching C++ code
    -- Background ticks ("little guys") at y=1 and y=5
    for i = 0, 10 do
        self:fill_area(7 + i * 3, 1, 1, 1, 1)  -- top tick
        self:fill_area(7 + i * 3, 5, 1, 1, 1)  -- bottom tick
    end
    
    -- Active bars ("big guys") for input - matching C++: draw_box_filled((i * 3) + 7, 0, 3, 2)
    -- inR: top row (y=0-1), 3px wide, 2px high
    for i = 0, inR - 1 do
        self:fill_area(7 + i * 3, 0, 3, 2, 1)
    end
    
    -- inL: bottom row (y=4-5), 3px wide, 2px high
    for i = 0, inL - 1 do
        self:fill_area(7 + i * 3, 4, 3, 2, 1)
    end
    
    -- Draw output VU meter (right side) - matching C++ code
    -- Background ticks
    for i = 0, 10 do
        self:fill_area(54 + i * 3, 1, 1, 1, 1)  -- top tick
        self:fill_area(54 + i * 3, 5, 1, 1, 1)  -- bottom tick
    end
    
    -- Active bars for output - matching C++: draw_box_filled((i * 3) + 54, 0, 3, 2)
    -- outR: top row (y=0-1)
    for i = 0, outR - 1 do
        self:fill_area(54 + i * 3, 0, 3, 2, 1)
    end
    
    -- outL: bottom row (y=4-5)
    for i = 0, outL - 1 do
        self:fill_area(54 + i * 3, 4, 3, 2, 1)
    end
    
    -- Draw peak indicators - matching C++ peak bitmask logic
    -- peaks bitmask: 1=inR, 2=inL, 4=outR, 8=outL
    if peaks and peaks > 0 then
        if (peaks & 1) ~= 0 then
            self:fill_area(7 + 10 * 3, 0, 3, 2, 1)  -- inR peak at last bar
        end
        if (peaks & 2) ~= 0 then
            self:fill_area(7 + 10 * 3, 4, 3, 2, 1)  -- inL peak at last bar
        end
        if (peaks & 4) ~= 0 then
            self:fill_area(54 + 10 * 3, 0, 3, 2, 1)  -- outR peak at last bar
        end
        if (peaks & 8) ~= 0 then
            self:fill_area(54 + 10 * 3, 4, 3, 2, 1)  -- outL peak at last bar
        end
    end
end

-- =========================================================================
-- SETTINGS & PALETTE CONTROLS (Inlet 2)
-- =========================================================================
function oled:in_2(sel, atoms)
    if sel == "scale" then
        local new_scale = tonumber(atoms[1]) or 2
        if new_scale >= 1 and new_scale <= 8 then
            self.scale = math.floor(new_scale)
            self:update_canvas_bounds()
        end
    elseif sel == "margin" then
        local new_margin = tonumber(atoms[1]) or 0
        if new_margin >= 0 and new_margin <= 32 then
            self.margin = math.floor(new_margin)
            self:update_canvas_bounds()
            pd.post("OLED Display Margin updated to: " .. self.margin .. " pixels")
        end
    elseif sel == "color_on" then
        self.color_on = {
            tonumber(atoms[1]) or 0,
            tonumber(atoms[2]) or 255,
            tonumber(atoms[3]) or 255
        }
        self:repaint()
    elseif sel == "color_off" then
        self.color_off = {
            tonumber(atoms[1]) or 30,
            tonumber(atoms[2]) or 30,
            tonumber(atoms[3]) or 30
        }
        self:repaint()
    elseif sel == "color_margin" then
        self.color_margin = {
            tonumber(atoms[1]) or 0,
            tonumber(atoms[2]) or 0,
            tonumber(atoms[3]) or 0
        }
        self:repaint()
    end
end
