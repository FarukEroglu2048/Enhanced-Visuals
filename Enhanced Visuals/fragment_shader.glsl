#version 450 core

in vec2 texture_position;

uniform sampler2D simulator_texture;

layout(location = 0) out vec4 output_color;

vec3 inverse_tonemapper(vec3 input_color)
{
    const float coefficient_1 = 2.51;
    const float coefficient_2 = 0.03;
    const float coefficient_3 = 2.43;
    const float coefficient_4 = 0.59;
    const float coefficient_5 = 0.14;

    return (((coefficient_4 * input_color) - coefficient_2) + sqrt(pow(coefficient_4 * input_color, vec3(2.0)) + (-4.0 * coefficient_3 * coefficient_5 * pow(input_color, vec3(2.0))) + (4.0 * coefficient_1 * coefficient_5 * input_color) + (-2.0 * coefficient_2 * coefficient_4 * input_color) + pow(coefficient_2, 2.0))) / (2.0 * (coefficient_1 - (coefficient_3 * input_color)));
}

float luminance_compression_curve(float input_luminance)
{
    const float coefficient_1 = 2.51;
    const float coefficient_2 = 0.0875;
    const float coefficient_3 = 2.43;
    const float coefficient_4 = 0.675;
    const float coefficient_5 = 0.14;

    return clamp((input_luminance * ((coefficient_1 * input_luminance) + coefficient_2)) / ((input_luminance * ((coefficient_3 * input_luminance) + coefficient_4)) + coefficient_5), 0.0, 1.0);
}

vec3 tonemapper(vec3 input_color)
{
    const mat3 xyz_matrix = transpose(mat3(vec3(0.4124, 0.3576, 0.1805), vec3(0.2126, 0.7152, 0.0722), vec3(0.0193, 0.1192, 0.9505)));
    const mat3 lms_matrix = transpose(mat3(vec3(0.8189330101, 0.3618667424, -0.1288597137), vec3(0.0329845436, 0.9293118715, 0.0361456387), vec3(0.0482003018, 0.2643662691, 0.6338517070)));
    const mat3 oklab_matrix = transpose(mat3(vec3(0.2104542553, 0.7936177850, -0.0040720468), vec3(1.9779984951, -2.4285922050, 0.4505937099), vec3(0.0259040371, 0.7827717662, -0.8086757660)));

    const mat3 inverse_xyz_matrix = inverse(xyz_matrix);
    const mat3 inverse_lms_matrix = inverse(lms_matrix);
    const mat3 inverse_oklab_matrix = inverse(oklab_matrix);

    vec3 xyz_color = xyz_matrix * input_color;

    float uncompressed_luminance = xyz_color.y;
    float compressed_luminance = luminance_compression_curve(uncompressed_luminance);

    xyz_color *= compressed_luminance / uncompressed_luminance;

    vec3 lms_color = lms_matrix * xyz_color;
    lms_color = pow(lms_color, vec3(1.0 / 3.0));

    vec3 oklab_color = oklab_matrix * lms_color;
    oklab_color.yz = mix(oklab_color.yz, vec2(0.0, 0.0), pow(compressed_luminance, 1.75));

    lms_color = inverse_oklab_matrix * oklab_color;
    lms_color = pow(lms_color, vec3(3.0));

    xyz_color = inverse_lms_matrix * lms_color;

    return inverse_xyz_matrix * xyz_color;
}

void main()
{
    vec4 simulator_texture_color = texture(simulator_texture, texture_position);

    simulator_texture_color.xyz = inverse_tonemapper(simulator_texture_color.xyz);
    simulator_texture_color.xyz = tonemapper(simulator_texture_color.xyz);

    output_color = simulator_texture_color;
}
