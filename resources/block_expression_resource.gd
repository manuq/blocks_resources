class_name BlockExpressionResource
extends BlockResource

@export var template: String
@export var argument_types: Dictionary = {}

const ARGUMENTS_PATTERN = r"\{([^}]+)\}"

# TODO: Better do this an array of error messages.
var _error_message: String

var _arguments_regex: RegEx
var _arguments: Dictionary = {}

func _init(p_category: BlockResource.Category, p_template: String, p_argument_types: Dictionary = {}, p_arguments: Dictionary = {}):
		template = p_template
		argument_types = p_argument_types
		_arguments_regex = RegEx.new()
		_arguments_regex.compile(ARGUMENTS_PATTERN)
		if p_arguments:
			bind_arguments(p_arguments)
		super(BlockResource.Type.EXPRESSION, p_category)

func _get_generated_code_from_argument(argument: BlockResource):
	if argument is BlockExpressionResource:
		# Add parens even if redundant, for safety:
		return "(%s)" % argument.get_generated_code()
	elif argument is BlockLiteralResource:
		return argument.get_generated_code()
	# TODO: Add variables here.
	else:
		push_error("Only literals, variables and other expressions are allowed as expression arguments.")

func _get_generated_arguments():
	var generated = {}
	for name in _arguments:
		var argument = _arguments[name]
		generated[name] = _get_generated_code_from_argument(argument)
	return generated

func get_argument_names():
	var regex_result_to_argument = func (result: RegExMatch):
		return result.get_string().left(-1).right(-1)

	var results = _arguments_regex.search_all(template)
	return results.map(regex_result_to_argument)

func has_valid_argument_types():
	var types = _get_bound_argument_types()
	return types in argument_types

func _check_valid_argument_types():
	if has_unbound_arguments():
		return
	if not has_valid_argument_types():
		_error_message = "Invalid argument types."
	else:
		_error_message = ""

func _check_errors():
	_check_valid_argument_types()

func can_bind_argument(name: String, value: BlockResource):
	for types in argument_types:
		if types[name] in value.get_potential_types():
			return true
	return false

func bind_argument(name: String, value: BlockResource):
	if not can_bind_argument(name, value):
		# This shouldn't be possible, the UI should try can_bind_argument() first:
		push_error("Tried to bind an argument with a type that's not allowed.")
		return
	_arguments[name] = value
	_check_valid_argument_types()

func bind_arguments(p_arguments: Dictionary = {}):
	unbind_arguments()
	for name in p_arguments:
		bind_argument(name, p_arguments[name])

func unbind_argument(name: String):
	_arguments.erase(name)
	_check_valid_argument_types()

func unbind_arguments():
	_arguments = {}
	_error_message = ""

func _get_bound_argument_types():
	var types = {}
	for name in _arguments:
		types[name] = _arguments[name].get_type()
	return types

func has_unbound_arguments():
	var to_bind = get_argument_names()
	var bound_size = 0
	for name in _arguments:
		if name in to_bind:
			bound_size += 1

	return to_bind.size() > bound_size

func is_fuzzy():
	return has_unbound_arguments()

func get_type() -> Variant.Type:
	if has_unbound_arguments():
		return TYPE_NIL

	var types = _get_bound_argument_types()
	return argument_types.get(types, TYPE_NIL)

func get_potential_types() -> Array:
	return argument_types.values()

func has_errors() -> bool:
	_check_errors()
	return not _error_message.is_empty()

func get_error_message() -> String:
	return _error_message

func get_generated_code() -> String:
	if is_fuzzy():
		push_error("Tried to generate code from a fuzzy block.")
		return ""
	if has_errors():
		push_error("Tried to generate code from a block with errors.")
		return ""
	var generated_arguments = _get_generated_arguments()
	return template.format(generated_arguments)
