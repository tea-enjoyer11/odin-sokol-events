#version 450
#define SOKOL_HLSL (1)
layout(binding=0) uniform vs_params {
    mat4 mvp;
};

in vec2 position;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = mvp * vec4(position, 0, 1);
    color = color0;
}
