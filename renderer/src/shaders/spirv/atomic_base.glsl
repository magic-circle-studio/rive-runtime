#extension GL_EXT_samplerless_texture_functions : require
#define ENABLE_INSTANCE_INDEX
#define USING_PLS_STORAGE_TEXTURES
#ifdef PLS_IMPL_SUBPASS_LOAD
// When using input attachments in atomic mode, we can enable srcOver blending
// on the PLS attachments for better perf.
#define PLS_BLEND_SRC_OVER
#endif
#define OPTIONALLY_FLAT flat
#include "glsl.minified.glsl"
#include "constants.minified.glsl"
#include "specialization.minified.glsl"
#include "flush_uniforms.minified.glsl"
#ifdef DRAW_IMAGE
#endif
#include "common.minified.glsl"
#include "advanced_blend.minified.glsl"
#ifdef RIVE_SURFACE_MATERIAL
#include "surface_material.minified.glsl"
#include "surface_material_dispatch.minified.glsl"
#endif
#include "draw_path_common.minified.glsl"
#include "gradient_packing_common.minified.glsl"
#include "atomic_draw.minified.glsl"
