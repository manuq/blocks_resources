class_name BlockLiteralResource
extends BlockResource

@export var value: String

var _variant_type: Variant.Type
var _error_message: String

func _init(p_category: BlockResource.Category, p_value: String, p_variant_type = null):
	value = p_value
	if p_variant_type != null:
		_variant_type = p_variant_type
	else:
		_infer_variant_type()
	super(BlockResource.Type.LITERAL, p_category)

func get_type() -> Variant.Type:
	return _variant_type

func has_errors() -> bool:
	return not _error_message.is_empty()

func get_error_message() -> String:
	return _error_message

func _infer_variant_type():
	var expression = Expression.new()
	var error = expression.parse(value)
	if error != OK:
		_error_message = expression.get_error_text()
		return
	var result = expression.execute()
	if expression.has_execute_failed():
		_error_message = expression.get_error_text()
		return
	_variant_type = typeof(result) as Variant.Type

func get_generated_code():
	return value
