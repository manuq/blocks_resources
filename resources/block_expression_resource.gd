class_name BlockExpressionResource
extends BlockResource

@export var expression: String
@export var argument_types: Dictionary = {}

const ARGUMENTS_PATTERN = r"\{([^}]+)\}"

# TODO: Better do this an array of error messages.
var _error_message: String

var _arguments_regex: RegEx
var _arguments: Dictionary = {}

func _init(p_category: BlockResource.Category, p_expression: String, p_argument_types: Dictionary = {}, p_arguments: Dictionary = {}):
		expression = p_expression
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

	var results = _arguments_regex.search_all(expression)
	return results.map(regex_result_to_argument)

func _has_valid_argument_types():
	var types = _get_bound_argument_types()
	return types in argument_types

func _check_valid_argument_types():
	if not _has_valid_argument_types():
		_error_message = "Invalid argument types."
	else:
		_error_message = ""

func bind_argument(name: String, value: BlockResource):
	_arguments[name] = value
	_check_valid_argument_types()

func bind_arguments(p_arguments: Dictionary = {}):
	unbind_arguments()
	_arguments = p_arguments
	_check_valid_argument_types()

func unbind_arguments():
	_arguments = {}
	_error_message = ""

func _get_bound_argument_types():
	var types = {}
	for name in _arguments:
		types[name] = _arguments[name].get_type()
	return types

func _has_unbound_arguments():
	var to_bind = get_argument_names()
	var bound_size = 0
	for name in _arguments:
		if name in to_bind:
			bound_size += 1

	return to_bind.size() > bound_size

func is_inconsistent():
	# TODO: Isn´t this the same as asking if it has errors?
	return _has_unbound_arguments() or not _has_valid_argument_types()

func get_type() -> Variant.Type:
	if _has_unbound_arguments():
		return TYPE_NIL

	var types = _get_bound_argument_types()
	return argument_types.get(types, TYPE_NIL)

func has_errors() -> bool:
	return not _error_message.is_empty()

func get_error_message() -> String:
	return _error_message

func get_generated_code() -> String:
	if has_errors():
		push_error("Generating code from an inconsistent block.")
		return ""
	var generated_arguments = _get_generated_arguments()
	return expression.format(generated_arguments)
