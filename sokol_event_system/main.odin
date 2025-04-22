package sokol_event_system

import "core:fmt"

import sapp "../thirdparty/sokol/app"


Vec2 :: [2]f32
Enum_Kind :: u8
Key_Code :: sapp.Keycode
Key_Combination :: []Key_Code
Mouse_Button :: sapp.Mousebutton

Code_State :: enum Enum_Kind {
    down,
    pressed,
    released,
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

    _tracked_keys: map[Key_Code]bool,
    _tracked_mouse: map[Mouse_Button]bool,
}

handle_event :: proc(event: ^sapp.Event, state: ^Input_State) {
    #partial switch event.type {
        case .KEY_DOWN:
            state.keys[event.key_code] = { .pressed, .down }
            state._tracked_keys[event.key_code] = true
        case .KEY_UP:
            state.keys[event.key_code] = { .released }
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
}

// :util
@(private = "file")
curr_state: ^Input_State
// set the current input_state for easier proc calls
set_current_input_state :: proc(state: ^Input_State) {
    curr_state = state
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
key_prepeated_state :: proc(key: Key_Code, state: ^Input_State) -> bool {
    panic("Not implemented yet") // TODO
}
key_prepeated_curr_state :: proc(key: Key_Code) -> bool {
    panic("Not implemented yet") // TODO
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
