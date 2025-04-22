# if the shader file changed, it's just calling this before building the game:
# sokol-shdc -i game/shader.glsl -o game/shader.odin -l hlsl5:wgsl -f sokol_odin

import os
import subprocess
import time
import sys

sys.tracebacklimit = 0  # for no massive error tracebacks


def has_shader_changed(shader_file, timestamp_file):
    if not os.path.exists(timestamp_file):
        return True

    shader_mtime = os.path.getmtime(shader_file)
    try:
        with open(timestamp_file, "r") as f:
            last_built_time = float(f.read().strip())
    except (FileNotFoundError, ValueError):
        return True

    return shader_mtime > last_built_time


def update_shader_timestamp(timestamp_file):
    with open(timestamp_file, "w") as f:
        f.write(str(time.time()))


def compile_shader(shader_file, shader_output, timestamp_file):
    if has_shader_changed(shader_file, timestamp_file):
        print(f"Shader \"{shader_file}\" has changed, rebuilding...")
        subprocess.run([
            "sokol-shdc", "-i", shader_file, "-o", shader_output,
            "-l", "hlsl5:wgsl", "-f", "sokol_odin", "--save-intermediate-spirv"
        ], check=True)

        update_shader_timestamp(timestamp_file)
    else:
        print(f"Shader \"{shader_file}\" has not changed, skipping rebuild.")


compile_shader("game/shader.glsl", "game/shader.odin", "game/shader.timestamp")
# compile_shader("game/text-shader.glsl", "game/text-shader.odin", "game/text-shader.timestamp")


print("Building the game...")
subprocess.run(["odin", "build", "game", "-debug"], check=True)


print("Running game.exe...")
subprocess.run(["start", "game.exe"], shell=True)
