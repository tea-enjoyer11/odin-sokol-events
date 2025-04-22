# 🎉 Sokol Events
A small collection of procedures which aim to recreate raylib's key- and mouseevents functionality.

## Procedures
Name | Similar To | Info
---- | ---------- | ----
set_current_input_state | | Set the current `Input_State`. Useful for when you don't want to pass the pointer to the current input state into every procedure call. **I don't know how it affects performance. (Todo: test)**
get_mouse_pos | GetMousePosition | Get current mouse position
get_mouse_delta | GetMouseDelta | Get mouse movement between frames
get_scroll_delta | GetMouseWheelMoveV | Get mouse wheel movement
mouse_in_window | | Returns `true` if the mouse is inside the window. `false` is not.
key_down | IsKeyDown | Returns `true` if the key is pressed. `false` if not.
key_pressed | IsKeyPressed | Returns `true` if the key is pressed this frame. `false` if not.
key_released | IsKeyReleased | Returns `true` if the key is released this frame. `false` if not.
key_combination_down | | Returns `true` if key_down is `true` for every key in the given combination. `false` if not.
key_combination_pressed | | Returns `true` if all keys are pressed and `key_pressed` is true for *at least one* key. `false` if not.
> Note: All listed procedures are procedure groups which have two members. One which takes an additional pointer to the input state. The other one doesn't take that pointer, however `set_current_input_state` needs to be called before. Otherwise it will cause a runtime assertion error.

## Procedure call order
You have to call two procedures every frame: `handle_event` and `update`

In your `event_cb` procedure:
```odin
event_cb :: proc "c" (event: ^sapp.Event) {#
    context = runtime.default_context()

    sevent.handle_event(event)

    // ... your code .... 
}
```
In your `frame_cb` procedure:
```odin
frame_cb :: proc "c" () {
    // ... your code .... 

    sevent.update(&input_state) // CALL THIS AT THE VERY END
}
```

## How this library works
Sokol's callback order is the following:
1. event_cb
2. frame_cb
