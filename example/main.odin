package main

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:time"
import "core:strings"
import "base:builtin"


import sg "../thirdparty/sokol/gfx"
import sapp "../thirdparty/sokol/app"
import sglue "../thirdparty/sokol/glue"
import slog "../thirdparty/sokol/log"

import sevent "../sokol_event_system"


// :state
State :: struct {
    draw_frame:     Draw_Frame,

    input_state: sevent.Input_State,
}
state: State


MAX_QUADS :: 8192 // 2^13
mat4 :: linalg.Matrix4x4f32
Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Color :: sg.Color

Draw_Frame :: struct {
    pip:            sg.Pipeline,
    bind:           sg.Bindings,
    pass_action:    sg.Pass_Action,
    bg_pass_action: sg.Pass_Action,

    view:           mat4,
    projection:     mat4,

    quads:          [MAX_QUADS]Quad,
    quad_count:     int,
}


Vertex :: struct {
    pos:        Vec2,
    color:      Color,
}

Quad :: [4]Vertex


start_time: time.Time
now :: proc() -> f64 {
    return time.duration_seconds(time.diff(start_time, time.now()))
}


// :init
init :: proc "c" () {
    context = runtime.default_context()
    start_time = time.now()
    
    sg.setup({
        environment = sglue.environment(),
        logger = { func = slog.func },
    })

    dframe := &state.draw_frame

    // text vertex & index buffer
    dframe.bind.vertex_buffers[0] = sg.make_buffer({
        type = .VERTEXBUFFER,
        usage = .DYNAMIC,
        data = { ptr = nil, size = size_of(Quad) * len(dframe.quads) },
        size = size_of(Quad) * len(dframe.quads),
        label = "quad-vertices",
    })
    index_buffer_count :: MAX_QUADS*6
	indices : [index_buffer_count]u16;
    for quad_idx in 0..<MAX_QUADS {
        base_vertex := quad_idx * 4
        base_index := quad_idx * 6
        
        indices[base_index + 0] = auto_cast (base_vertex + 0)
        indices[base_index + 1] = auto_cast (base_vertex + 1)
        indices[base_index + 2] = auto_cast (base_vertex + 2)
        indices[base_index + 3] = auto_cast (base_vertex + 0)
        indices[base_index + 4] = auto_cast (base_vertex + 2)
        indices[base_index + 5] = auto_cast (base_vertex + 3)
    }
	dframe.bind.index_buffer = sg.make_buffer({
        type = .INDEXBUFFER,
        usage = .IMMUTABLE,
		// data = { ptr = &indices, size = size_of(indices) },
        data = { ptr = &indices, size = len(indices) * size_of(u16) },
        size = len(indices) * size_of(u16),
        label = "quad-indices",
	})

    dframe.bg_pass_action = {
        colors = {
            0 = { load_action = .CLEAR, clear_value = to_sokol_color(200, 20, 20, 255) },
        }
    }
    dframe.pass_action = {
        colors = {
            0 = { load_action = .CLEAR, clear_value = to_sokol_color(92, 115, 50, 255) },
        },
    }

    // shader and pipeline object
    pipeline_desc := sg.Pipeline_Desc {
        shader = sg.make_shader(quad_shader_desc(sg.query_backend())),
        layout = {
            attrs = {
                ATTR_quad_position = { format = .FLOAT2 },
                ATTR_quad_color0 = { format = .FLOAT4 },
            },
        },
        index_type = .UINT16,
    }
    blend_state : sg.Blend_State = {
		enabled = true,
		src_factor_rgb = .SRC_ALPHA,
		dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
		op_rgb = .ADD,
		src_factor_alpha = .ONE,
		dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
		op_alpha = .ADD,
	}
	pipeline_desc.colors[0] = { blend = blend_state }
    dframe.pip = sg.make_pipeline(pipeline_desc)

    create_projection_matrix()
    dframe.view = mat4(1)
}

on_window_resize :: proc() {
    create_projection_matrix()
}
create_projection_matrix :: proc() {
    state.draw_frame.projection = linalg.matrix_ortho3d_f32(0, sapp.widthf(), sapp.heightf(), 0, -1, 1) // tl = {0, 0} ; br = {w, h}
}

update_buffers :: proc() {
    sg.update_buffer(
        state.draw_frame.bind.vertex_buffers[0],
        { ptr = &state.draw_frame.quads[0], size = uint(size_of(Quad) * len(state.draw_frame.quads)) }
    )
}

reset_drawframe :: proc() {
    dframe := &state.draw_frame

    dframe.quad_count = 0
    dframe.view = mat4(1)
}
global_time : f32

// :frame
frame :: proc "c" () {
    context = runtime.default_context()
    dt := f32(sapp.frame_duration() * 1)
    global_time += dt
    dframe := &state.draw_frame


    reset_drawframe()

    // background color
    sg.begin_pass({ action = dframe.bg_pass_action, swapchain = sglue.swapchain() })
    sg.end_pass()

    dframe.view = mat4(1)

    update_buffers()
    vs_params := Vs_Params {
        mvp = to_sokol_mat4(dframe.projection * dframe.view * mat4(1)),
    }

    // draw a Quad
    if state.draw_frame.quad_count < MAX_QUADS {
        pos := Vec2{ sapp.widthf() * 0.1, sapp.heightf() * 0.1 }
        size := Vec2{ sapp.widthf() * 0.8, sapp.heightf() * 0.8 }
        color := to_sokol_color(101, 157, 233, 255)
        quad := cast(^[4]Vertex)&state.draw_frame.quads[state.draw_frame.quad_count]
        poses := [4]Vec2{ { pos.x, pos.y }, { pos.x + size.x, pos.y }, { pos.x + size.x, pos.y + size.y }, { pos.x, pos.y + size.y } }
        for i in 0..<4 {
            quad[i].pos = poses[i]
            quad[i].color = color
        }
        state.draw_frame.quad_count += 1
    }

    sevent.set_current_input_state(&state.input_state)
    curr_keys := sevent.get_pressed_keys(&state.input_state)
    defer delete(curr_keys)
    fmt.println(
        // sevent.key_down(.A, &state.input_state),
        // sevent.key_down(.A),
        // sevent.key_combination_down({.A, .B}, &state.input_state),
        // sevent.key_combination_pressed({.A, .B}),
        // state.input_state._last_keys[.A], state.input_state.keys[.A], state.input_state.repeated_keys[.A]
        // sevent.key_down(.A), sevent.key_repeated(.A),
        sevent.get_input_string(&state.input_state),
        curr_keys,
    )

    sg.begin_pass({ action = dframe.pass_action, swapchain = sglue.swapchain() })
    sg.apply_pipeline(dframe.pip)
    sg.apply_bindings(dframe.bind)
    sg.apply_uniforms(UB_vs_params, { ptr = &vs_params, size = size_of(vs_params) })
    sg.draw(0, 6*dframe.quad_count, 1)
    sg.end_pass()

    sg.commit()
    sevent.update(&state.input_state)
}

// :event
event :: proc "c" (event: ^sapp.Event) {
    context = runtime.default_context()

    sevent.handle_event(event, &state.input_state)

    #partial switch event.type {
        case .RESIZED:
            on_window_resize()
    }
}

cleanup :: proc "c" () {
    context = runtime.default_context()
    sg.shutdown()
}


main :: proc () {
    sapp.run({
        init_cb = init,
        frame_cb = frame,
        cleanup_cb = cleanup,
        event_cb = event,
        width = 1280,
        height = 720,
        sample_count = 4,
        window_title = "Odin Sokol Template",
        icon = { sokol_default = true },
        logger = { func = slog.func },
    })
}

to_sokol_mat4 :: proc(mat: mat4) -> [16]f32 {
    return {
        mat[0][0], mat[0][1], mat[0][2], mat[0][3],
        mat[1][0], mat[1][1], mat[1][2], mat[1][3],
        mat[2][0], mat[2][1], mat[2][2], mat[2][3],
        mat[3][0], mat[3][1], mat[3][2], mat[3][3],
    }
}

to_sokol_color :: proc(r, g, b, a: int) -> Color {
    q := f32(1.0 / 255.0)
    return { f32(r) * q, f32(g) * q, f32(b) * q, f32(a) * q }
}
