/*
 * Copyright 2026 Rive
 */

#ifndef _RIVE_SURFACE_MATERIAL_HPP_
#define _RIVE_SURFACE_MATERIAL_HPP_

#include <cstdint>

namespace rive
{
// Material selected for an artboard or an individual image binding. Inherit
// is meaningful only on nested draws; the artboard itself has no parent.
enum class SurfaceMaterial : uint32_t
{
    none = 0,
    gold = 1,
    rainbow = 2,
    inherit = 3,
};

static_assert(static_cast<uint32_t>(SurfaceMaterial::none) == 0);
static_assert(static_cast<uint32_t>(SurfaceMaterial::gold) == 1);
static_assert(static_cast<uint32_t>(SurfaceMaterial::rainbow) == 2);
static_assert(static_cast<uint32_t>(SurfaceMaterial::inherit) == 3);

constexpr SurfaceMaterial surfaceMaterialFromValue(uint32_t value)
{
    return value <= static_cast<uint32_t>(SurfaceMaterial::inherit)
               ? static_cast<SurfaceMaterial>(value)
               : SurfaceMaterial::none;
}
} // namespace rive

#endif
