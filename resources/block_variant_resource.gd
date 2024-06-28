class_name BlockVariantResource
extends BlockResource

@export var variant_type: Variant.Type

func _init(p_variant_type: Variant.Type):
		super(BlockResource.BlockType.VARIANT_EXPRESSION)
		variant_type = p_variant_type
