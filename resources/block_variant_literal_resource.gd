class_name BlockVariantLiteralResource
extends BlockVariantResource

@export var value: String

func _init(p_variant_type: Variant.Type, p_value: String):
	super(p_variant_type)
	value = p_value

func get_output():
	return value
