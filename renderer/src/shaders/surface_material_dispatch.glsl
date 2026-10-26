#ifdef @RIVE_SURFACE_MATERIAL
#define SURFACE_MATERIAL_NONE 0.0
#define SURFACE_MATERIAL_GOLD 1.0
#define SURFACE_MATERIAL_RAINBOW 2.0

INLINE half3 apply_surface_material(half3 baseColor,
                                    float2 materialCoord,
                                    float materialMode,
                                    float timeSeconds)
{
    if (materialMode == SURFACE_MATERIAL_GOLD)
    {
        return apply_gold_material(baseColor, materialCoord, timeSeconds);
    }
    if (materialMode == SURFACE_MATERIAL_RAINBOW)
    {
        // Rive preprojects UVs onto Rainbow's axis so the mapping can use each
        // surface's aspect ratio without widening the per-path GPU data.
        return apply_rainbow_material(baseColor,
                                      materialCoord,
                                      float2(1.0, 0.0),
                                      1.0,
                                      1.0,
                                      0.0,
                                      1.0);
    }
    return baseColor;
}

INLINE half4 apply_surface_material_to_paint(half4 paintColor,
                                             float4 materialData,
                                             bool paintIsPremultiplied)
{
    // MSAA and raster-ordering draws interpolate the mode as a varying, which
    // need not reproduce the per-vertex constant exactly; comparing it raw
    // left ~14% of pixels unmaterialized on SwiftShader WebGL2.
    materialData.z = floor(materialData.z + 0.5);
    if (materialData.z == SURFACE_MATERIAL_NONE)
    {
        return paintColor;
    }

    half3 baseColor = paintIsPremultiplied ? unmultiply_rgb(paintColor)
                                           : paintColor.rgb;
    paintColor.rgb = apply_surface_material(baseColor,
                                            materialData.xy,
                                            materialData.z,
                                            materialData.w);
    if (paintIsPremultiplied)
    {
        paintColor.rgb *= paintColor.a;
    }
    return paintColor;
}
#endif // RIVE_SURFACE_MATERIAL
