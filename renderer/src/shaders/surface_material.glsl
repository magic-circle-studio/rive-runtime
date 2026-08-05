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

INLINE half3 surface_rainbow_spline(half3 p0,
                                     half3 p1,
                                     half3 p2,
                                     half3 p3,
                                     float t)
{
    float t2 = t * t;
    float t3 = t2 * t;
    half w0 = make_half(1.0 - 3.0 * t + 3.0 * t2 - t3);
    half w1 = make_half(4.0 - 6.0 * t2 + 3.0 * t3);
    half w2 = make_half(1.0 + 3.0 * t + 3.0 * t2 - 3.0 * t3);
    half w3 = make_half(t3);
    return (p0 * w0 + p1 * w1 + p2 * w2 + p3 * w3) /
           make_half(6.0);
}

INLINE half3 surface_rainbow_color(float t)
{
    // These are the production Rainbow colors plus their midpoints. The dense
    // controls keep the familiar saturated mix while the cyclic B-spline
    // rounds its old corners with continuous value, slope, and curvature.
    // Nonnegative spline weights prevent overshoot and gamut clipping.
    half3 c0 = make_half3(1.0, 0.09, 0.267);
    half3 c1 = make_half3(1.0, 0.3295, 0.1335);
    half3 c2 = make_half3(1.0, 0.569, 0.0);
    half3 c3 = make_half3(1.0, 0.7435, 0.0);
    half3 c4 = make_half3(1.0, 0.918, 0.0);
    half3 c5 = make_half3(0.5, 0.91, 0.2315);
    half3 c6 = make_half3(0.0, 0.902, 0.463);
    half3 c7 = make_half3(0.0805, 0.6885, 0.7315);
    half3 c8 = make_half3(0.161, 0.475, 1.0);
    half3 c9 = make_half3(0.498, 0.2375, 0.988);
    half3 c10 = make_half3(0.835, 0.0, 0.976);
    half3 c11 = make_half3(0.9175, 0.045, 0.6215);

    float scaled = fract(t) * 12.0;
    float segment = floor(scaled);
    float localT = fract(scaled);
    if (segment < 1.0)
        return surface_rainbow_spline(c11, c0, c1, c2, localT);
    if (segment < 2.0)
        return surface_rainbow_spline(c0, c1, c2, c3, localT);
    if (segment < 3.0)
        return surface_rainbow_spline(c1, c2, c3, c4, localT);
    if (segment < 4.0)
        return surface_rainbow_spline(c2, c3, c4, c5, localT);
    if (segment < 5.0)
        return surface_rainbow_spline(c3, c4, c5, c6, localT);
    if (segment < 6.0)
        return surface_rainbow_spline(c4, c5, c6, c7, localT);
    if (segment < 7.0)
        return surface_rainbow_spline(c5, c6, c7, c8, localT);
    if (segment < 8.0)
        return surface_rainbow_spline(c6, c7, c8, c9, localT);
    if (segment < 9.0)
        return surface_rainbow_spline(c7, c8, c9, c10, localT);
    if (segment < 10.0)
        return surface_rainbow_spline(c8, c9, c10, c11, localT);
    if (segment < 11.0)
        return surface_rainbow_spline(c9, c10, c11, c0, localT);
    return surface_rainbow_spline(c10, c11, c0, c1, localT);
}

INLINE half3 surface_rainbow_reflect(half3 baseColor,
                                      half3 reflectionColor,
                                      float amount)
{
    // A screen blend models colored light reflected by a clear coat: it can
    // brighten the pigment underneath, but never replace it with a dull band.
    return make_half3(1.0) -
           (make_half3(1.0) - baseColor) *
               (make_half3(1.0) - reflectionColor * make_half(amount));
}

INLINE half3 apply_rainbow_material(half3 baseColor,
                                    float2 materialCoord,
                                    float timeSeconds,
                                    float2 baseAxis,
                                    float2 sheenAxis,
                                    float aspect,
                                    float squish,
                                    float flipX,
                                    float materialAlpha)
{
    float x = mix(materialCoord.x, 1.0 - materialCoord.x, flipX);
    float2 unsquishedPosition = float2(x, materialCoord.y * aspect);
    float2 position = (unsquishedPosition - 0.5) * squish + 0.5;
    float spatialT = clamp(dot(baseAxis, position - 0.5) + 0.5,
                           0.0,
                           1.0);
    float sheenT = clamp(dot(sheenAxis, unsquishedPosition - 0.5) + 0.5,
                         0.0,
                         1.0);

    // Keep the spectrum fixed in material space so it remains attached to the
    // artwork while it deforms. Animation belongs to the reflection, not the
    // pigment beneath it.
    float t = fract(spatialT * 0.82);
    float sourceLuma = surface_material_luma(baseColor);

    // Expand subtle authored value differences in light and midtone fills.
    // Dark artwork is left alone so genuinely dark details do not get crushed.
    float structureWeight = smoothstep(0.35, 0.75, sourceLuma);
    float structuredLuma = mix(sourceLuma,
                               pow(sourceLuma, 1.40),
                               structureWeight);

    // Match authored luminosity without clipping the smooth color spline.
    half3 paletteColor = surface_rainbow_color(t);
    half3 rainbow = paletteColor;
    float paletteLuma = surface_material_luma(paletteColor);
    float shadowScale = min(structuredLuma / max(paletteLuma, 0.001), 1.0);
    rainbow *= make_half(shadowScale);
    float shadedLuma = paletteLuma * shadowScale;
    float highlightAmount = max(
        (structuredLuma - shadedLuma) / max(1.0 - shadedLuma, 0.001),
        0.0);
    rainbow = mix(rainbow,
                  make_half3(1.0),
                  make_half(highlightAmount));

    // Authored white is a bright substrate, not emitted white light. Restore
    // some palette chroma only in the brightest fills so light artwork stays
    // visibly Rainbow without muddying midtone shading or protected ink.
    float whiteChroma = smoothstep(0.72, 0.98, sourceLuma) * 0.35;
    rainbow = mix(rainbow, paletteColor, make_half(whiteChroma));

    // Reintroduce a restrained, luminance-neutral imprint of the authored
    // chroma. This keeps similarly bright adjacent fills visually distinct
    // without muting the Rainbow or requiring screen-space edge sampling.
    half3 authoredChroma = baseColor - make_half3(sourceLuma);
    rainbow = clamp(rainbow + authoredChroma * make_half(0.28),
                    make_half3(0.0),
                    make_half3(1.0));

    // Sweep a broad softbox over the stationary pigment, followed by a quiet
    // interval. The branch is coherent across the draw because time is shared.
    float sheenCycle = fract(timeSeconds / 3.0);
    // Negative time requests the stable material used by baked thumbnails.
    if (timeSeconds >= 0.0 && sheenCycle < 0.34)
    {
        float sheenProgress = sheenCycle / 0.34;
        sheenProgress = sheenProgress * sheenProgress *
                        (3.0 - 2.0 * sheenProgress);
        float sheenCenter = sheenProgress * 1.6 - 0.3;
        float sheenDistance = abs(sheenT - sheenCenter);
        float sheenHalo = 1.0 - smoothstep(0.055, 0.16, sheenDistance);
        float sheenCore = 1.0 - smoothstep(0.012, 0.052, sheenDistance);

        // Tight spectral shoulders around a crisp neutral core read as clear
        // coat rather than a broad, cloudy overlay.
        float prismaticStrength = 0.62;
        float warmDistance = abs(sheenT - (sheenCenter - 0.075));
        float coolDistance = abs(sheenT - (sheenCenter + 0.075));
        float warmFringe =
            1.0 - smoothstep(0.015, 0.105, warmDistance);
        float coolFringe =
            1.0 - smoothstep(0.015, 0.105, coolDistance);
        rainbow = surface_rainbow_reflect(rainbow,
                                      make_half3(1.0, 0.30, 0.03),
                                      warmFringe * 0.34 * prismaticStrength);
        rainbow = surface_rainbow_reflect(rainbow,
                                      make_half3(0.20, 0.36, 1.0),
                                      coolFringe * 0.34 * prismaticStrength);
        float prismWhite = sheenHalo * 0.015 + sheenCore * 0.15;
        rainbow = surface_rainbow_reflect(rainbow,
                                      make_half3(1.0),
                                      prismWhite * prismaticStrength);

        // Two tighter reflections layer the clear coat without washing a
        // broad stretch of the underlying pigment toward pastel.
        float reflectionStrength = 0.55;
        float echoDistance = abs(sheenT - (sheenCenter - 0.20));
        float echoHalo = 1.0 - smoothstep(0.045, 0.13, echoDistance);
        float echoCore = 1.0 - smoothstep(0.018, 0.060, echoDistance);
        float echoAmount = echoHalo * 0.025 + echoCore * 0.12;
        rainbow = surface_rainbow_reflect(rainbow,
                                      make_half3(1.0, 0.66, 0.22),
                                      echoAmount * reflectionStrength);

        float leadingDistance = abs(sheenT - (sheenCenter + 0.19));
        float leadingHalo = 1.0 - smoothstep(0.045, 0.13, leadingDistance);
        float leadingCore = 1.0 - smoothstep(0.018, 0.060, leadingDistance);
        float leadingAmount = leadingHalo * 0.020 + leadingCore * 0.11;
        rainbow = surface_rainbow_reflect(rainbow,
                                      make_half3(0.34, 0.48, 1.0),
                                      leadingAmount * reflectionStrength);
    }

    // Preserve genuine near-black ink rather than recoloring it.
    float inkProtection = 1.0 - smoothstep(0.025, 0.09, sourceLuma);
    half3 materialColor = mix(rainbow,
                              baseColor,
                              make_half(inkProtection * 0.94));
    return mix(baseColor, materialColor, make_half(materialAlpha));
}
