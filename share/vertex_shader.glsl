#version 450 core

layout(location = 0) in vec2 input_vertex;

out vec2 texture_position;

void main()
{
    texture_position = (input_vertex / 2.0) + 0.5;
    gl_Position = vec4(input_vertex, 0.0, 1.0);
}