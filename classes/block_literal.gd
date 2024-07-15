class_name BlockLiteral
extends Block

@export var value: String

var _type: Variant.Type

# In case _type is TYPE_OBJECT, this should be the class name.
# In other case, this should be empty. See how typed arrays are constructed for reference.
var _class_name: StringName = &""

var _error_message: String

func _init(p_category: Block.Category, p_value: String, p_type = null):
	value = p_value
	if p_type != null:
		_type = p_type
	else:
		_infer_type()
	super(Block.Type.LITERAL, p_category)

func get_type() -> Variant.Type:
	return _type

func get_potential_types() -> Array:
	return [_type]

func has_errors() -> bool:
	return not _error_message.is_empty()

func get_error_message() -> String:
	return _error_message

func _infer_type():
	var expression = Expression.new()
	var error = expression.parse(value)
	if error != OK:
		_error_message = expression.get_error_text()
		return
	var result = expression.execute()
	if expression.has_execute_failed():
		_error_message = expression.get_error_text()
		return
	_type = typeof(result) as Variant.Type

func get_generated_code():
	return value
