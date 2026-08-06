#include "rive/data_bind/context/context_value_asset_image.hpp"
#include "rive/data_bind/data_values/data_value_asset_image.hpp"
#include "rive/generated/core_registry.hpp"
#include "rive/file.hpp"

using namespace rive;

DataBindContextValueAssetImage::DataBindContextValueAssetImage(
    DataBind* dataBind) :
    DataBindContextValue(dataBind)
{}

rcp<ImageAsset> DataBindContextValueAssetImage::fileAsset(DataBind* dataBind)
{
    auto file = dataBind->file();
    auto source = dataBind->source();
    if (file != nullptr && source != nullptr &&
        source->is<ViewModelInstanceAssetImage>())
    {

        auto asset = file->asset(
            source->as<ViewModelInstanceAssetImage>()->propertyValue());
        if (asset != nullptr && asset->is<ImageAsset>())
        {
            return static_rcp_cast<ImageAsset>(asset);
        }
    }
    return nullptr;
}

void DataBindContextValueAssetImage::apply(Core* target,
                                           uint32_t propertyKey,
                                           bool isMainDirection,
                                           DataBind* dataBind)
{
    if (target->is<Image>())
    {
        auto source = dataBind->source()->as<ViewModelInstanceAssetImage>();
        auto image = target->as<Image>();
        image->surfaceMaterial(source->surfaceMaterial());
        auto asset = fileAsset(dataBind);
        if (asset != nullptr)
        {
            image->setAsset(asset);
        }
        else
        {
            image->setAsset(source->asset());
        }
    }
    else if (target->is<BindablePropertyAsset>())
    {
        auto source = dataBind->source();
        target->as<BindablePropertyAsset>()->imageValue(
            source->as<ViewModelInstanceAssetImage>()->asset()->renderImage());
        CoreRegistry::setUint(
            target,
            propertyKey,
            source->as<ViewModelInstanceAssetImage>()->propertyValue());
    }
    else if (target->is<ViewModelInstanceAssetImage>())
    {
        auto source = dataBind->source()->as<ViewModelInstanceAssetImage>();
        auto image = target->as<ViewModelInstanceAssetImage>();
        image->setSurfaceMaterial(source->surfaceMaterial());
        auto sourceValue = source->propertyValue();
        if (sourceValue == static_cast<uint32_t>(-1))
        {
            image->value(source->asset()->renderImage());
        }
        else
        {
            CoreRegistry::setUint(target, propertyKey, sourceValue);
        }
    }
    else
    {
        auto source = dataBind->source();
        CoreRegistry::setUint(
            target,
            propertyKey,
            source->as<ViewModelInstanceAssetImage>()->propertyValue());
    }
}
