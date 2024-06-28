extends Node2D

func _ready():
	var a = BlockVariantLiteralResource.new(TYPE_VECTOR2, "Vector2(100, 100)")
	print(a.get_output())

	var b = BlockVariantLiteralResource.new(TYPE_VECTOR2, "Vector2(200, 0)")
	print(b.get_output())

	var c = BlockVariantLiteralResource.new(TYPE_VECTOR2, "Vector2(1, 2)")
	print(c.get_output())

	var a_plus_b = BlockVariantExpressionResource.new(TYPE_VECTOR2, "{a} + {b}")
	a_plus_b.arguments = {'a': a, 'b': b}
	print(a_plus_b.get_output())

	var a_plus_b_divided = BlockVariantExpressionResource.new(TYPE_VECTOR2, "{a} / {b}")
	a_plus_b_divided.arguments = {'a': a_plus_b, 'b': c}
	print(a_plus_b_divided.get_output())
