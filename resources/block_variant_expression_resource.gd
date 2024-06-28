class_name BlockVariantExpressionResource
extends BlockVariantResource

@export var expression: String
@export var arguments: Dictionary = {}

func _init(p_variant_type: Variant.Type, p_expression: String, p_arguments: Dictionary = {}):
		super(p_variant_type)
		expression = p_expression
		arguments = p_arguments

func get_output() -> String:
	var evaluated = {}
	for key in arguments:
		var argument = arguments[key]
		if argument is BlockVariantExpressionResource:
			evaluated[key] = "(%s)" % argument.get_output()
		else:
			evaluated[key] = argument.get_output()
	return expression.format(evaluated)
