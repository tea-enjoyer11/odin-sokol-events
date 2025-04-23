package sokol_event_system

import "core:fmt"
import "core:strings"
import "core:unicode"

import sapp "../thirdparty/sokol/app"


Vec2 :: [2]f32
Enum_Kind :: u8
Key_Code :: sapp.Keycode
Key_Combination :: []Key_Code
Mouse_Button :: sapp.Mousebutton

Modifier_Key_Code :: enum Enum_Kind {
    LEFT_SHIFT,
    LEFT_CONTROL,
    LEFT_ALT,
    RIGHT_SHIFT,
    RIGHT_CONTROL,
    RIGHT_ALT,
    CAPS_LOCK,
    TAB,
    UP,
    DOWN,
    RIGHT,
    LEFT,
    INSERT,
    DELETE,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
}

Code_State :: enum Enum_Kind {
    down,
    pressed,
    released,
    repeated,
}

Mouse_State :: bit_set[Code_State]
Key_State :: bit_set[Code_State]

Input_State :: struct {
    mpos: Vec2,
    mrel: Vec2,
    mscroll: Vec2,
    m_in_window: bool,

    mouse_buttons: map[Mouse_Button]Mouse_State,
    keys: map[Key_Code]Key_State,
    _last_keys: map[Key_Code]Key_State,
    caps_toggled: bool,

    _tracked_keys: map[Key_Code]bool,
    _tracked_mouse: map[Mouse_Button]bool,

    input_buffer: strings.Builder,
    input_modifires: bit_set[Modifier_Key_Code]
}

handle_event :: proc(event: ^sapp.Event, state: ^Input_State) {
    #partial switch event.type {
        case .KEY_DOWN:
            state.keys[event.key_code] += { .pressed, .down }
            state._tracked_keys[event.key_code] = true

            if state._last_keys[event.key_code] == { .down } {
                state.keys[event.key_code] += { .repeated }
            }

            if event.key_code == .CAPS_LOCK {
                state.caps_toggled = !state.caps_toggled
            }


            // Handle modiferes
            #partial switch event.key_code {
                case .LEFT_SHIFT:       state.input_modifires += { .LEFT_SHIFT }
                case .LEFT_CONTROL:     state.input_modifires += { .LEFT_CONTROL }
                case .LEFT_ALT:         state.input_modifires += { .LEFT_ALT }
                case .RIGHT_SHIFT:      state.input_modifires += { .RIGHT_SHIFT }
                case .RIGHT_CONTROL:    state.input_modifires += { .RIGHT_CONTROL }
                case .RIGHT_ALT:        state.input_modifires += { .RIGHT_ALT }
                case .CAPS_LOCK:        state.input_modifires += { .CAPS_LOCK }
                case .TAB:              state.input_modifires += { .TAB }
                case .INSERT:           state.input_modifires += { .INSERT }
                case .DELETE:           state.input_modifires += { .DELETE }
                case .UP:               state.input_modifires += { .UP }
                case .DOWN:             state.input_modifires += { .DOWN }
                case .RIGHT:            state.input_modifires += { .RIGHT }
                case .LEFT:             state.input_modifires += { .LEFT }
                case .F1:               state.input_modifires += { .F1 }
                case .F2:               state.input_modifires += { .F2 }
                case .F3:               state.input_modifires += { .F3 }
                case .F4:               state.input_modifires += { .F4 }
                case .F5:               state.input_modifires += { .F5 }
                case .F6:               state.input_modifires += { .F6 }
                case .F7:               state.input_modifires += { .F7 }
                case .F8:               state.input_modifires += { .F8 }
                case .F9:               state.input_modifires += { .F9 }
                case .F10:              state.input_modifires += { .F10 }
                case .F11:              state.input_modifires += { .F11 }
                case .F12:              state.input_modifires += { .F2 }
            }

            #partial switch event.key_code {
                case ._0..=._9, .A..=.Z, .SPACE, \\
                     .LEFT_BRACKET, .RIGHT_BRACKET, .SLASH, .BACKSLASH, \\
                     .PERIOD, .SEMICOLON, .COMMA, .MINUS, .EQUAL, \\
                     .APOSTROPHE, .GRAVE_ACCENT: {
                        r := key_to_rune(event.key_code)

                        if state.caps_toggled {
                            r = to_upper(r)
                        }
                        if key_down(.LEFT_SHIFT, state) || key_down(.RIGHT_SHIFT, state) {
                            if state.caps_toggled {
                                r = to_lower(r)
                            } else {
                                r = to_upper(r)
                            }
                        }
                        if key_down(.LEFT_ALT, state) || key_down(.RIGHT_ALT, state) {
                            r = to_special(r)
                        }

                        strings.write_rune(&state.input_buffer, r)
                     }
            }
        case .KEY_UP:
            state.keys[event.key_code] = { .released }
            state._tracked_keys[event.key_code] = false
        case .MOUSE_DOWN:
            state.mouse_buttons[event.mouse_button] = { .pressed, .down }
            state._tracked_mouse[event.mouse_button] = true
        case .MOUSE_UP:
            state.mouse_buttons[event.mouse_button] = { .released }
        case .MOUSE_ENTER:
            state.m_in_window = true
        case .MOUSE_LEAVE:
            state.m_in_window = false
        case .MOUSE_MOVE:
            state.mrel = { event.mouse_dx, event.mouse_dy }
        case .MOUSE_SCROLL:
            state.mscroll = { event.scroll_x, event.scroll_y }
    }
}

update :: proc(state: ^Input_State) {
    backup: {
        for key, val in state.keys {
            state._last_keys[key] = val
        }
    }

    mouse: {
        state.mscroll = { 0, 0 }
        state.mrel = { 0, 0 }

        for btn, _ in state._tracked_mouse {
            state.mouse_buttons[btn] -= { .pressed, .released }
        }
    }

    keys: {
        for key, _ in state._tracked_keys {
            state.keys[key] -= { .pressed, .released }
        }
    }

    modifiers: {
        state.input_modifires = {}
        strings.builder_reset(&state.input_buffer)
    }
}

// :util
@(private = "file")
curr_state: ^Input_State
// set the current input_state for easier proc calls
set_current_input_state :: proc(state: ^Input_State) {
    curr_state = state
}

m_key_to_rune := map[Key_Code]rune{
    ._0 = '0',
    ._1 = '1',
    ._2 = '2',
    ._3 = '3',
    ._4 = '4',
    ._5 = '5',
    ._6 = '6',
    ._7 = '7',
    ._8 = '8',
    ._9 = '9',

    .A = 'a',
    .B = 'b',
    .C = 'c',
    .D = 'd',
    .E = 'e',
    .F = 'f',
    .G = 'g',
    .H = 'h',
    .I = 'i',
    .J = 'j',
    .K = 'k',
    .L = 'l',
    .M = 'm',
    .N = 'n',
    .O = 'o',
    .P = 'p',
    .Q = 'q',
    .R = 'r',
    .S = 's',
    .T = 't',
    .U = 'u',
    .V = 'v',
    .W = 'w',
    .X = 'x',
    .Y = 'y',
    .Z = 'z',

    .SPACE = ' ',
    .APOSTROPHE = '\'',
    .COMMA = ',',
    .MINUS = '-',
    .PERIOD = '.',
    .SLASH = '/',
    .SEMICOLON = ';',
    .EQUAL = '=',
    .LEFT_BRACKET = '[',
    .BACKSLASH = '\"',
    .RIGHT_BRACKET = ']',
    .GRAVE_ACCENT = '`',
}
key_to_rune :: proc(key: Key_Code) -> rune {
    val, ok := m_key_to_rune[key]
    return ok ? val : rune{}
}

to_upper :: proc(r: rune) -> rune {
    // TODO: this is acutally quite naive since there are multiple keyboard layouts and I'm just assuming the user uses QWERTZ
    if unicode.is_letter(r) {
        return unicode.to_upper(r)
    }
    if unicode.is_number(r) {
        switch r {
            case '0': return '='
            case '1': return '!'
            case '2': return '"'
            case '3': return '§'
            case '4': return '$'
            case '5': return '%'
            case '6': return '&'
            case '7': return '/'
            case '8': return '('
            case '9': return ')'
        }
    }
    switch r {
        case ',': return ';'
        case '.': return ':'
        case '-': return '_'
        case '+': return '*'
        case '#': return '\''
    }
    return r
}

to_lower :: proc(r: rune) -> rune {
    // TODO: this is acutally quite naive since there are multiple keyboard layouts and I'm just assuming the user uses QWERTZ
    if unicode.is_letter(r) {
        return unicode.to_lower(r)
    }
    switch r {
        case '=': return '0'
        case '!': return '1'
        case '"': return '2'
        case '§': return '3'
        case '$': return '4'
        case '%': return '5'
        case '&': return '6'
        case '/': return '7'
        case '(': return '8'
        case ')': return '9'
        case ';': return ','
        case ':': return '.'
        case '_': return '-'
        case '*': return '+'
        case '\'': return '#'
    }
    return r
}

to_special :: proc(r: rune) -> rune {
    // Meant for when ALT-GR is pressed and any other key.
    // TODO: this is acutally quite naive since there are multiple keyboard layouts and I'm just assuming the user uses QWERTZ
    switch r {
        case '2': return '²'
        case '3': return '³'
        case '7': return '{'
        case '8': return '['
        case '9': return ']'
        case '0': return '}'
        case 'ß': return '\\'
        case '+': return '~'
        case 'm': return 'µ'
        case 'q': return '@'
        case 'e': return '€'
    }
    return r
}


// :input procs

// Get Input string
get_input_string :: proc{ get_input_string_state, get_input_string_curr_state }
get_input_string_state :: proc(state: ^Input_State) -> string { return strings.to_string(state.input_buffer) }
get_input_string_curr_state :: proc() -> string { return strings.to_string(curr_state.input_buffer) }

// Get input buffer as a copy
get_input_buffer :: proc{ get_input_buffer_state, get_input_buffer_curr_state }
get_input_buffer_state :: proc(state: ^Input_State) -> strings.Builder {
    b: strings.Builder
    strings.write_string(&b, strings.to_string(state.input_buffer))
    return b
}
get_input_buffer_curr_state :: proc() -> strings.Builder {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `get_input_buffer`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    b: strings.Builder
    strings.write_string(&b, strings.to_string(curr_state.input_buffer))
    return b
}


// :mouse procs

// get mouse pos
get_mouse_pos :: proc{ get_mouse_pos_state, get_mouse_pos_curr_state }
get_mouse_pos_state :: proc(state: ^Input_State) -> Vec2 { return state.mpos }
get_mouse_pos_curr_state :: proc() -> Vec2 {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `get_mouse_pos`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return curr_state.mpos
}

// get movement in this frame
get_mouse_delta :: proc{ get_mouse_delta_state, get_mouse_delta_curr_state }
get_mouse_delta_state :: proc(state: ^Input_State) -> Vec2 { return state.mrel }
get_mouse_delta_curr_state :: proc() -> Vec2 {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `get_mouse_delta`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return curr_state.mrel
}

// get scroll in this frame
get_scroll_delta :: proc{ get_scroll_delta_state, get_scroll_delta_curr_state }
get_scroll_delta_state :: proc(state: ^Input_State) -> Vec2 { return state.mscroll }
get_scroll_delta_curr_state :: proc() -> Vec2 {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `get_scroll_delta`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return curr_state.mscroll
}

// returns true if the mousebtn is down
mouse_down :: proc{ mouse_down_state, mouse_down_curr_state }
mouse_down_state :: proc(btn: Mouse_Button, state: ^Input_State) -> bool { return .down in state.mouse_buttons[btn] }
mouse_down_curr_state :: proc(btn: Mouse_Button) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `mouse_down`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .down in curr_state.mouse_buttons[btn]
}

// returns true if the mousebtn is pressed THIS frame
mouse_pressed :: proc{ mouse_pressed_state, mouse_pressed_curr_state }
mouse_pressed_state :: proc(btn: Mouse_Button, state: ^Input_State) -> bool { return .pressed in state.mouse_buttons[btn] }
mouse_pressed_curr_state :: proc(btn: Mouse_Button) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `mouse_pressed`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .pressed in curr_state.mouse_buttons[btn]
}

// returns true if the mousebtn is up
mouse_up :: proc{ mouse_up_state, mouse_up_curr_state }
mouse_up_state :: proc(btn: Mouse_Button, state: ^Input_State) -> bool { return .down not_in state.mouse_buttons[btn] && .pressed not_in state.mouse_buttons[btn] }
mouse_up_curr_state :: proc(btn: Mouse_Button) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `mouse_up`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .down not_in curr_state.mouse_buttons[btn] && .pressed not_in curr_state.mouse_buttons[btn]
}

// returns true if the mousebtn is released THIS frame
mouse_released :: proc{ mouse_released_state, mouse_released_curr_state }
mouse_released_state :: proc(btn: Mouse_Button, state: ^Input_State) -> bool { return .released in state.mouse_buttons[btn] }
mouse_released_curr_state :: proc(btn: Mouse_Button) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `mouse_released`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .released in curr_state.mouse_buttons[btn]
}


// return true if the mouse cursor is inside the window's frame
mouse_in_window :: proc{ mouse_in_window_state, mouse_in_window_curr_state }
mouse_in_window_state :: proc(state: ^Input_State) -> bool { return state.m_in_window }
mouse_in_window_curr_state :: proc() -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `mouse_in_window`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return curr_state.m_in_window
}


// :key procs

// return true if the key is down
key_down :: proc{ key_down_state, key_down_curr_state }
key_down_state :: proc(key: Key_Code, state: ^Input_State) -> bool { return .down in state.keys[key] }
key_down_curr_state :: proc(key: Key_Code) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_down`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .down in curr_state.keys[key]
}

// return true if the key is up
key_up :: proc{ key_up_state, key_up_curr_state }
key_up_state :: proc(key: Key_Code, state: ^Input_State) -> bool { return .down not_in state.keys[key] && .pressed not_in state.keys[key] }
key_up_curr_state :: proc(key: Key_Code) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_up`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .down not_in curr_state.keys[key] && .pressed not_in curr_state.keys[key]
}

// return true if the key is down in THIS frame
key_pressed :: proc{ key_pressed_state, key_pressed_curr_state }
key_pressed_state :: proc(key: Key_Code, state: ^Input_State) -> bool { return .pressed in state.keys[key] }
key_pressed_curr_state :: proc(key: Key_Code) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_pressed`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .pressed in curr_state.keys[key]
}

// return true if the key is released THIS frame
key_released :: proc{ key_released_state, key_released_curr_state }
key_released_state :: proc(key: Key_Code, state: ^Input_State) -> bool { return .released in state.keys[key] }
key_released_curr_state :: proc(key: Key_Code) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_released`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .released in curr_state.keys[key]
}

// return true if the key is repeated
key_repeated :: proc{ key_prepeated_state, key_prepeated_curr_state }
key_prepeated_state :: proc(key: Key_Code, state: ^Input_State) -> bool { return .repeated in state.keys[key] }
key_prepeated_curr_state :: proc(key: Key_Code) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_repeated`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    return .repeated in curr_state.keys[key]
}


// return true if all keys are down
key_combination_down :: proc{ key_combination_down_state, key_combination_down_curr_state }
key_combination_down_state :: proc(comb: Key_Combination, state: ^Input_State) -> bool {
    for key in comb {
        if !key_down_state(key, state) {
            return false
        }
    }
    return true
}
key_combination_down_curr_state :: proc(comb: Key_Combination) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_combination_down`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    for key in comb {
        if !key_down_curr_state(key) {
            return false
        }
    }
    return true
}


// returns true if at least one of the keys are pressed in THIS frame. Else it returns false.
key_combination_pressed :: proc{ key_combination_pressed_state, key_combination_pressed_curr_state }
key_combination_pressed_state :: proc(comb: Key_Combination, state: ^Input_State) -> bool {
    if len(comb) == 0 { return false }

    one_pressed_this_frame := false
    for key in comb {
        if !key_down_state(key, state) {
            return false
        }
        // Check if any of the keys have been pressed THIS frame
        if key_pressed_state(key, state) {
            one_pressed_this_frame = true
        }
    }

    return one_pressed_this_frame
}
key_combination_pressed_curr_state :: proc(comb: Key_Combination) -> bool {
    assert(curr_state != nil, fmt.tprintf("To use `%s` (which was most likely called by `key_combination_pressed`) you must provide a valid pointer for the current state. To fix this issue either provide a valid pointer to a `Input_state` or use `set_current_input_state`.", #procedure))
    if len(comb) == 0 { return false }

    one_pressed_this_frame := false
    for key in comb {
        if !key_down_curr_state(key) {
            return false
        }
        // Check if any of the keys have been pressed THIS frame
        if key_pressed_curr_state(key) {
            one_pressed_this_frame = true
        }
    }

    return one_pressed_this_frame // This automatically only returns if all are keys are down AND at least ONE key is pressed THIS frame
}
