INLINE half surface_material_luma(half3 color)
{
    return dot(color, make_half3(0.3, 0.59, 0.11));
}

INLINE half3 apply_gold_material(half3 baseColor,
                                 float2 materialCoord,
                                 float timeSeconds)
{
    float sourceLuma = surface_material_luma(baseColor);
    half3 shadowGold = make_half3(0.54, 0.34, 0.003);
    half3 richGold = make_half3(0.98, 0.69, 0.008);
    half3 yellowGold = make_half3(1.0, 0.86, 0.055);
    half3 reflectedGold = make_half3(1.0, 0.92, 0.26);
    half3 glintGold = make_half3(1.0, 0.97, 0.68);

    // Treat authored luminance as surface detail, not final brightness.
    float detailTone = clamp(0.52 + (sourceLuma - 0.5) * 0.40, 0.34, 0.74);
    half3 gold = mix(shadowGold,
                     richGold,
                     make_half(smoothstep(0.34, 0.55, detailTone)));
    gold = mix(gold,
               yellowGold,
               make_half(smoothstep(0.51, 0.74, detailTone)));

    // A static softbox and dark horizon retain chrome contrast between sweeps.
    float reflectionAxis = dot(materialCoord - 0.5, float2(-0.57, 0.82));
    float softbox =
        1.0 - smoothstep(0.08, 0.28, abs(reflectionAxis + 0.14));
    float darkHorizon =
        1.0 - smoothstep(0.04, 0.27, abs(reflectionAxis - 0.13));
    gold *= make_half(0.98 + 0.06 * softbox);
    gold *= make_half(1.0 - 0.045 * darkHorizon);
    gold = mix(gold, reflectedGold, make_half(softbox * 0.22));

    // Travel for 1.5 seconds, then leave an equally long quiet interval.
    float sweepCycle = fract(timeSeconds / 3.0);
    // Negative time requests the stable material used by baked thumbnails.
    if (timeSeconds >= 0.0 && sweepCycle < 0.5)
    {
        float sweepCoord = dot(materialCoord, float2(0.78, 0.62));
        float sweepCenter = sweepCycle * 2.0 * 1.9 - 0.45;
        float sweepDistance = abs(sweepCoord - sweepCenter);
        float shineHalo = 1.0 - smoothstep(0.10, 0.23, sweepDistance);
        float shineCore = 1.0 - smoothstep(0.025, 0.075, sweepDistance);
        gold = mix(gold, reflectedGold, make_half(shineHalo * 0.30));
        gold = mix(gold, glintGold, make_half(shineCore * 0.55));
    }

    // Protect only genuine near-black ink.
    float inkProtection = 1.0 - smoothstep(0.025, 0.09, sourceLuma);
    return mix(gold, baseColor, make_half(inkProtection * 0.94));
}

// This is the six-stop linear gradient used by Magic Circle's original
// Rainbow filter. Keep the branchless mix chain: dynamically indexed local
// arrays miscompile on some Mali GPUs.
INLINE half3 surface_rainbow_color(float t)
{
    float segment = clamp(t, 0.0, 1.0) * 5.0;
    half3 color = make_half3(1.0, 0.09, 0.267);
    color = mix(color,
                make_half3(1.0, 0.569, 0.0),
                make_half(clamp(segment, 0.0, 1.0)));
    color = mix(color,
                make_half3(1.0, 0.918, 0.0),
                make_half(clamp(segment - 1.0, 0.0, 1.0)));
    color = mix(color,
                make_half3(0.0, 0.902, 0.463),
                make_half(clamp(segment - 2.0, 0.0, 1.0)));
    color = mix(color,
                make_half3(0.161, 0.475, 1.0),
                make_half(clamp(segment - 3.0, 0.0, 1.0)));
    return mix(color,
               make_half3(0.835, 0.0, 0.976),
               make_half(clamp(segment - 4.0, 0.0, 1.0)));
}

INLINE half3 surface_rainbow_clip_color(half3 color)
{
    float luminosity = surface_material_luma(color);
    float minimum = min(min(color.r, color.g), color.b);
    float maximum = max(max(color.r, color.g), color.b);
    if (minimum < 0.0)
    {
        color = make_half3(luminosity) +
                ((color - make_half3(luminosity)) * luminosity) /
                    (luminosity - minimum);
    }
    if (maximum > 1.0)
    {
        color = make_half3(luminosity) +
                ((color - make_half3(luminosity)) * (1.0 - luminosity)) /
                    (maximum - luminosity);
    }
    return color;
}

INLINE half3 surface_rainbow_set_luminosity(half3 color, float luminosity)
{
    float delta = luminosity - surface_material_luma(color);
    return surface_rainbow_clip_color(color + make_half3(delta));
}

INLINE half3 apply_rainbow_material(half3 baseColor,
                                    float2 materialCoord,
                                    float2 axis,
                                    float aspect,
                                    float squish,
                                    float flipX,
                                    float materialAlpha)
{
    float x = mix(materialCoord.x, 1.0 - materialCoord.x, flipX);
    float2 position = float2(x, materialCoord.y * aspect);
    position = (position - 0.5) * squish + 0.5;
    float t = clamp(dot(axis, position - 0.5) + 0.5, 0.0, 1.0);
    half3 rainbow = surface_rainbow_set_luminosity(
        surface_rainbow_color(t), surface_material_luma(baseColor));
    return mix(baseColor, rainbow, make_half(materialAlpha));
}
