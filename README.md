# 🎉 Sokol Events
A small collection of procedures that recreate raylib's key and mouse event functionality for sokol.

## Procedures
Name | Similar To | Info
---- | ---------- | ----
set_current_input_state | | Set the current `Input_State`. Useful for when you don't want to pass the pointer to the current input state into every procedure call. **I don't know how it affects performance. (Todo: test)**
get_mouse_pos | GetMousePosition | Get current mouse position
get_mouse_delta | GetMouseDelta | Get mouse movement between frames
get_scroll_delta | GetMouseWheelMoveV | Get mouse wheel movement
mouse_in_window | | Returns `true` if the mouse is inside the window, otherwise `false`.
key_down | IsKeyDown | Returns `true` if the key is pressed, otherwise `false`.
key_pressed | IsKeyPressed | Returns `true` if the key is pressed this frame, otherwise `false`.
key_released | IsKeyReleased | Returns `true` if the key is released this frame, otherwise `false`.
key_combination_down | | Returns `true` all keys are down (`key_down`), otherwise `false`.
key_combination_pressed | | Returns `true` if all keys are down and `key_pressed` is true for *at least one* key, otherwise `false`.
> Note: All listed procedures are procedure groups which have two members. One takes an additional pointer to the input state, while the other doesn't. For the latter, `set_current_input_state` must be called first, otherwise it will cause a runtime assertion error.

## Procedure call order
You must call two procedures every frame: `handle_event` and `update`

Call `handle_event` in your `event_cb` procedure:
```odin
event_cb :: proc "c" (event: ^sapp.Event) {#
    context = runtime.default_context()

    sevent.handle_event(event)

    // ... your code .... 
}
```
Call `update` in your `frame_cb` procedure:
```odin
frame_cb :: proc "c" () {
    // ... your code .... 

    sevent.update(&input_state) // CALL THIS AT THE VERY END
}
```

## How this library works
> NoteSokol's callback order:
> 1. event_cb
> 2. frame_cb

This library works by capturing events through `handle_event` and updating input states in `update`.
It is crucial that the user calls `update` at the end of his `frame_cb` procedure, otherwise processed events are already updated before the user gets to use them. This is because of sokols callback order listed above.
