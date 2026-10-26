#pragma once

#include <array>
#include "generated/shaders/tessellate.glsl.exports.h"

namespace rive::gpu
{
static constexpr auto ImageDrawInstanceBaseAttributes = std::array{
    VertexAttribute{
        // m_viewMatrix (2x2)
        VertexElementFormat::float4,
        ImageDrawInstanceBase::FirstAttribIdx + 0,
        0,
        GLSL_a_imageDrawViewMatrix,
    },
    VertexAttribute{
        // m_clipRectInverseMatrix (2x2)
        VertexElementFormat::float4,
        ImageDrawInstanceBase::FirstAttribIdx + 1,
        4 * sizeof(float),
        GLSL_a_imageDrawClipRectInverseMatrix,
    },
    VertexAttribute{
        // packed: m_translate (2), m_clipRectInverseTranslate(2)
        VertexElementFormat::float4,
        ImageDrawInstanceBase::FirstAttribIdx + 2,
        8 * sizeof(float),
        GLSL_a_imageDrawTranslates,
    },
    VertexAttribute{
        // m_opacity/m_modulatedColor
        VertexElementFormat::uint32,
        ImageDrawInstanceBase::FirstAttribIdx + 3,
        12 * sizeof(float),
        GLSL_a_imageDrawModulatedColor,
    },
    VertexAttribute{
        // m_clipID
        VertexElementFormat::uint32,
        ImageDrawInstanceBase::FirstAttribIdx + 4,
        13 * sizeof(float),
        GLSL_a_imageDrawClipID,
    },
    VertexAttribute{
        // m_blendMode
        VertexElementFormat::uint32,
        ImageDrawInstanceBase::FirstAttribIdx + 5,
        14 * sizeof(float),
        GLSL_a_imageDrawBlendMode,
    },
    VertexAttribute{
        // m_zIndex
        VertexElementFormat::uint32,
        ImageDrawInstanceBase::FirstAttribIdx + 6,
        15 * sizeof(float),
        GLSL_a_imageDrawZIndex,
    },
};

static_assert(std::size(ImageDrawInstanceBaseAttributes) ==
              ImageDrawInstanceBase::AttributeCount);
static_assert(std::size(ImageDrawInstanceBaseAttributes) ==
              IMAGE_COMMON_ATTRIB_COUNT);

static constexpr auto ImageRectInstanceAttributes = std::apply(
    [](auto... baseAttribs) {
        constexpr auto BaseIndex = ImageDrawInstanceBase::LastAttribIdx + 1;
        return std::array{
            baseAttribs..., // ImageDrawInstanceBase attributes come first
            VertexAttribute{
                // m_imageMatrix
                VertexElementFormat::float4,
                BaseIndex + 0,
                16 * sizeof(float),
                GLSL_a_imageRectImageMatrix,
            },
            VertexAttribute{
                // m_gradientMatrix
                VertexElementFormat::float4,
                BaseIndex + 1,
                20 * sizeof(float),
                GLSL_a_imageRectGradientMatrix,
            },
            VertexAttribute{
                // packed: m_imageTranslate and m_gradientTranslate
                VertexElementFormat::float4,
                BaseIndex + 2,
                24 * sizeof(float),
                GLSL_a_imageRectImageAndGradientTranslates,
            },
            VertexAttribute{// packed: m_gradTextureX, m_gradTextureY,
                            // m_gradientType, m_padding
                            VertexElementFormat::float4,
                            BaseIndex + 3,
                            28 * sizeof(float),
                            GLSL_a_imageRectPackedGradientData},
#ifdef RIVE_SURFACE_MATERIAL
            VertexAttribute{
                // m_surfaceMaterialMatrix
                VertexElementFormat::float4,
                BaseIndex + 4,
                32 * sizeof(float),
                GLSL_a_imageRectSurfaceMaterialMatrix,
            },
            VertexAttribute{
                // packed: m_surfaceMaterialTranslate, m_surfaceMaterialMode,
                // m_surfaceMaterialTimeSeconds
                VertexElementFormat::float4,
                BaseIndex + 5,
                36 * sizeof(float),
                GLSL_a_imageRectSurfaceMaterialData,
            },
#endif
        };
    },
    ImageDrawInstanceBaseAttributes);

static_assert(std::size(ImageRectInstanceAttributes) ==
              IMAGE_RECT_ATTRIB_COUNT +
                  ImageRectInstance::SurfaceMaterialAttributeCount);

static constexpr auto ImageMeshInstanceAttributes = std::apply(
    [](auto... baseAttribs) {
        constexpr auto BaseIndex = ImageDrawInstanceBase::LastAttribIdx + 1;
        return std::array{
            baseAttribs..., // ImageDrawInstanceBase attributes come first
            VertexAttribute{
                // packed: m_uvTranslate (x,y), m_uvScale (x,y)
                VertexElementFormat::float4,
                BaseIndex + 0,
                16 * sizeof(float),
                GLSL_a_imageMeshUVTransform,
            },
        };
    },
    ImageDrawInstanceBaseAttributes);

static_assert(std::size(ImageMeshInstanceAttributes) ==
              IMAGE_MESH_ATTRIB_COUNT);

} // namespace rive::gpu