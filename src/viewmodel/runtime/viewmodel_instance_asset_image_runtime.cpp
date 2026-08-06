
#include "rive/viewmodel/runtime/viewmodel_instance_asset_image_runtime.hpp"

// Default namespace for Rive Cpp code
using namespace rive;

void ViewModelInstanceAssetImageRuntime::value(RenderImage* renderImage)
{
    m_viewModelInstanceValue->as<ViewModelInstanceAssetImage>()->value(
        renderImage);
}

void ViewModelInstanceAssetImageRuntime::setSurfaceMaterial(uint32_t value)
{
    m_viewModelInstanceValue->as<ViewModelInstanceAssetImage>()
        ->setSurfaceMaterial(surfaceMaterialFromValue(value));
}

#ifdef TESTING
RenderImage* ViewModelInstanceAssetImageRuntime::testing_value()
{
    return m_viewModelInstanceValue->as<ViewModelInstanceAssetImage>()
        ->asset()
        ->renderImage();
}
#endif
