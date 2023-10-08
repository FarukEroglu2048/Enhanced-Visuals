#version 450 core

in vec2 texture_position;

uniform sampler2D simulator_texture;

uniform float saturation_boost;
uniform float saturation_compression;

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

float compress_luminance(float input_luminance)
{
    float coefficient_1 = 2.51;
    float coefficient_2 = 0.03;
    float coefficient_3 = 2.43;
    float coefficient_4 = 0.59;
    float coefficient_5 = 0.14;

    return clamp((input_luminance * ((coefficient_1 * input_luminance) + coefficient_2)) / ((input_luminance * ((coefficient_3 * input_luminance) + coefficient_4)) + coefficient_5), 0.0, 1.0);
}

vec3 srgb_to_oklab(vec3 input_color)
{
    mat3 srgb_lms_matrix = mat3(vec3(0.4122214708, 0.2119034982, 0.0883024619), vec3(0.5363325363, 0.6806995451, 0.2817188376), vec3(0.0514459929, 0.10739699566, 0.6299787005));
    mat3 lms_oklab_matrix = mat3(vec3(0.2104542553, 1.977998495, 0.0259040371), vec3(0.7936177850, -2.4285922050, 0.782771662), vec3(-0.0040720468, 0.4505937099, -0.8086757660));

    vec3 lms_color = srgb_lms_matrix * input_color;
    lms_color = pow(lms_color, vec3(1.0 / 3.0));

    return lms_oklab_matrix * lms_color;
}

vec3 oklab_to_srgb(vec3 input_color)
{
    mat3 oklab_lms_matrix = inverse(mat3(vec3(0.2104542553, 1.977998495, 0.0259040371), vec3(0.7936177850, -2.4285922050, 0.782771662), vec3(-0.0040720468, 0.4505937099, -0.8086757660)));
    mat3 lms_srgb_matrix = inverse(mat3(vec3(0.4122214708, 0.211903498, 0.0883024619), vec3(0.5363325363, 0.6806995451, 0.2817188376), vec3(0.0514459929, 0.10739699566, 0.6299787005)));

    vec3 lms_color = oklab_lms_matrix * input_color;
    lms_color = pow(lms_color, vec3(3.0));

    return lms_srgb_matrix * lms_color;
}

vec3 tonemapper(vec3 input_color)
{
    float input_luminance = dot(input_color, vec3(0.2126, 0.7152, 0.0722));
    float output_luminance = compress_luminance(input_luminance);

    vec3 srgb_color = input_color * (output_luminance / input_luminance);

    vec3 oklab_color = srgb_to_oklab(srgb_color);
    oklab_color = mix(srgb_to_oklab(vec3(output_luminance)), oklab_color, (1.0 + saturation_boost) * ((1.0 - pow(saturation_compression, 1.0 - output_luminance)) / (1.0 - saturation_compression)));

    srgb_color = oklab_to_srgb(oklab_color);

    return clamp(srgb_color, 0.0, 1.0);
}

float srgb_gamma(float input_value)
{
    if (input_value > 0.0031308) return (1.055 * pow(input_value, 1.0 / 2.4)) - 0.055;
    else return 12.92 * input_value;
}

void main()
{
    vec4 simulator_texture_color = texture(simulator_texture, texture_position);

    simulator_texture_color.xyz = inverse_tonemapper(simulator_texture_color.xyz);
    simulator_texture_color.xyz = tonemapper(simulator_texture_color.xyz);

    simulator_texture_color.xyz = vec3(srgb_gamma(simulator_texture_color.x), srgb_gamma(simulator_texture_color.y), srgb_gamma(simulator_texture_color.z));
    
    output_color = simulator_texture_color;
}