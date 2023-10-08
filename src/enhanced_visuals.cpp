#ifdef IBM
#include <Windows.h>
#endif

#include <XPLMDataAccess.h>
#include <XPLMGraphics.h>
#include <XPLMDisplay.h>

#include <glbinding/gl/gl.h>

#include <globjects/globjects.h>
#include <globjects/Texture.h>
#include <globjects/VertexAttributeBinding.h>

#include <glm/common.hpp>
#include <glm/gtc/type_ptr.hpp>

#include <cstring>

globjects::Program* rendering_program;

globjects::Shader* rendering_vertex_shader;
globjects::Shader* rendering_fragment_shader;

globjects::VertexArray* rendering_vertex_array;
globjects::Buffer* rendering_vertex_buffer;

globjects::Texture* simulator_framebuffer_texture;

XPLMDataRef simulator_viewport_dataref;

glm::ivec4 previous_viewport = glm::ivec4(0);
glm::ivec4 current_viewport = glm::ivec4(0);

#ifdef IBM
BOOL APIENTRY DllMain(IN HINSTANCE dll_handle, IN DWORD call_reason, IN LPVOID reserved)
{
    return TRUE;
}
#endif

int draw_callback(XPLMDrawingPhase drawing_phase, int is_before, void* callback_reference)
{
    XPLMSetGraphicsState(0, 1, 0, 0, 0, 0, 0);

    previous_viewport = current_viewport;
    XPLMGetDatavi(simulator_viewport_dataref, glm::value_ptr(current_viewport), 0, current_viewport.length());

    current_viewport.z -= current_viewport.x;
    current_viewport.w -= current_viewport.y;

    if ((previous_viewport.z != current_viewport.z) || (previous_viewport.w != current_viewport.w)) simulator_framebuffer_texture->image2D(0, gl::GL_SRGB8_ALPHA8, glm::ivec2(current_viewport.z, current_viewport.w), 0, gl::GL_RGBA, gl::GL_UNSIGNED_BYTE, nullptr);

    XPLMBindTexture2d(simulator_framebuffer_texture->id(), 0);
    gl::glCopyTexSubImage2D(gl::GL_TEXTURE_2D, 0, 0, 0, current_viewport.x, current_viewport.y, current_viewport.z, current_viewport.w);

    rendering_program->use();

    int mouse_x;
    int mouse_y;

    XPLMGetMouseLocation(&mouse_x, &mouse_y);

    int window_width;
    int window_height;

    XPLMGetScreenSize(&window_width, &window_height);

    float saturation_boost = 2.0 * (float(mouse_y) / float(window_height));
    float saturation_compression = 2.0 * (float(mouse_x) / float(window_width));

    rendering_program->setUniform("saturation_boost", float(0.25));
    rendering_program->setUniform("saturation_compression", float(0.025));

    rendering_vertex_array->drawArrays(gl::GL_TRIANGLES, 0, 6);
    rendering_vertex_array->unbind();

    rendering_program->release();

    return 1;
}

PLUGIN_API int XPluginStart(char* plugin_name, char* plugin_signature, char* plugin_description)
{
    std::strcpy(plugin_name, "Enhanced Visuals");
    std::strcpy(plugin_signature, "biology.enhanced_visuals");
    std::strcpy(plugin_description, "Enhanced Visuals");

    globjects::init();

    rendering_program = new globjects::Program();
    rendering_program->ref();

    rendering_vertex_shader = globjects::Shader::fromFile(gl::GL_VERTEX_SHADER, "Resources/plugins/Enhanced Visuals/vertex_shader.glsl");
    rendering_fragment_shader = globjects::Shader::fromFile(gl::GL_FRAGMENT_SHADER, "Resources/plugins/Enhanced Visuals/fragment_shader.glsl");

    rendering_vertex_shader->ref();
    rendering_fragment_shader->ref();

    rendering_program->attach(rendering_vertex_shader);
    rendering_program->attach(rendering_fragment_shader);

    rendering_program->use();

    rendering_program->setUniform("simulator_texture", 0);

    rendering_vertex_array = new globjects::VertexArray();
    rendering_vertex_array->ref();

    globjects::VertexAttributeBinding* vertex_attribute_binding = rendering_vertex_array->binding(0);

    rendering_vertex_buffer = new globjects::Buffer();
    rendering_vertex_buffer->ref();

    glm::vec2 quad_vertices[] = {glm::vec2(-1.0, -1.0), glm::vec2(-1.0, 1.0), glm::vec2(1.0, -1.0), glm::vec2(1.0, -1.0), glm::vec2(-1.0, 1.0), glm::vec2(1.0, 1.0)};
    rendering_vertex_buffer->setData(quad_vertices, gl::GL_STATIC_DRAW);

    vertex_attribute_binding->setBuffer(rendering_vertex_buffer, 0, sizeof(glm::vec2));
    vertex_attribute_binding->setAttribute(0);
    vertex_attribute_binding->setFormat(2, gl::GL_FLOAT);

    rendering_vertex_array->enable(0);

    int texture_reference;
    XPLMGenerateTextureNumbers(&texture_reference, 1);

    simulator_framebuffer_texture = globjects::Texture::fromId(texture_reference, gl::GL_TEXTURE_2D);
    simulator_framebuffer_texture->bind();

    simulator_framebuffer_texture->setParameter(gl::GL_TEXTURE_MIN_FILTER, gl::GL_LINEAR);
    simulator_framebuffer_texture->setParameter(gl::GL_TEXTURE_MAG_FILTER, gl::GL_LINEAR);

    XPLMBindTexture2d(simulator_framebuffer_texture->id(), 0);

    rendering_vertex_array->unbind();
    rendering_program->release();

    simulator_viewport_dataref = XPLMFindDataRef("sim/graphics/view/viewport");

    XPLMRegisterDrawCallback(draw_callback, xplm_Phase_Window, 0, nullptr);

    return 1;
}

PLUGIN_API void XPluginStop(void)
{
    rendering_vertex_buffer->unref();
    rendering_vertex_array->unref();

    rendering_vertex_shader->unref();
    rendering_fragment_shader->unref();

    rendering_program->unref();
}

PLUGIN_API int XPluginEnable(void)
{
    return 1;
}

PLUGIN_API void XPluginDisable(void)
{

}

PLUGIN_API void XPluginReceiveMessage(XPLMPluginID sender_plugin, int message_type, void* callback_parameters)
{

}