extends GutTest

func test_blocks_builtin_operands():
	var a = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(100, 100)")
	assert_eq(a.category, BlockResource.Category.MATH)

	# A literal is a literal:
	assert_eq(a.get_generated_code(), "Vector2(100, 100)")
	
	# Type can be infered from builtin types:
	assert_eq(a.get_type(), TYPE_VECTOR2)

	# FIXME not a double so we can't spy:
	# assert_called(a, '_infer_variant_type')

	assert_false(a.has_errors())

	# Trying to infer type from literals that don't parse leads to error:
	var wrong = BlockLiteralResource.new(BlockResource.Category.MATH, "#%%!!")
	assert_true(wrong.has_errors())
	assert_eq(wrong.get_error_message(), "Unexpected character.")
	assert_eq(wrong.get_type(), TYPE_NIL)

	# Type can be explicit too. TODO: needed? Or do this only for variables?
	var b = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(200, 0)", TYPE_VECTOR2)
	assert_eq(b.get_type(), TYPE_VECTOR2)

	var a_plus_b = BlockExpressionResource.new(BlockResource.Category.MATH, "{a} + {b}")
	a_plus_b.argument_types = {
		{'a': TYPE_FLOAT, 'b': TYPE_FLOAT}: TYPE_FLOAT,
		{'a': TYPE_INT, 'b': TYPE_INT}: TYPE_INT,
		{'a': TYPE_FLOAT, 'b': TYPE_INT}: TYPE_FLOAT,
		{'a': TYPE_INT, 'b': TYPE_FLOAT}: TYPE_FLOAT,
		{'a': TYPE_VECTOR2, 'b': TYPE_VECTOR2}: TYPE_VECTOR2,
	}
	
	# Can tell what to bind:
	assert_eq(a_plus_b.get_argument_names(), ["a", "b"])

	# Type can't be infered before binding the arguments:
	assert_true(a_plus_b.is_inconsistent())
	assert_eq(a_plus_b.get_type(), TYPE_NIL)

	# Can bind all at once:
	a_plus_b.bind_arguments({'a': a, 'b': b})
	assert_false(a_plus_b.is_inconsistent())

	# Can do Vector2 + Vector2:
	assert_eq(a_plus_b.get_generated_code(), "Vector2(100, 100) + Vector2(200, 0)")

	# The expression type corresponds, Vector2 + Vector2 -> Vector2:
	assert_eq(a_plus_b.get_type(), TYPE_VECTOR2)

	# Confirm the type with real script:
	assert_eq(a_plus_b.get_type(), typeof(Vector2(100, 100) + Vector2(200, 0)))

	# Can bind the arguments one by one:
	a_plus_b.unbind_arguments()
	assert_true(a_plus_b.is_inconsistent())
	a_plus_b.bind_argument('a', a)
	assert_true(a_plus_b.is_inconsistent())
	a_plus_b.bind_argument('b', b)
	assert_false(a_plus_b.has_errors())
	assert_false(a_plus_b.is_inconsistent())
	assert_eq(a_plus_b.get_generated_code(), "Vector2(100, 100) + Vector2(200, 0)")
	assert_eq(a_plus_b.get_type(), TYPE_VECTOR2)

	# Vector2 + int is not possible!
	a_plus_b.bind_arguments({
		'a': a,
		'b': BlockLiteralResource.new(BlockResource.Category.MATH, "123"),
	})
	assert_true(a_plus_b.has_errors())
	assert_eq(a_plus_b.get_error_message(), "Invalid argument types.")
	assert_eq(a_plus_b.get_type(), TYPE_NIL)

	var a_plus_b_divided = BlockExpressionResource.new(BlockResource.Category.MATH, "{a} / {b}")
	a_plus_b_divided.argument_types = {
		# TODO: Complete this mapping.
		{'a': TYPE_VECTOR2, 'b': TYPE_VECTOR2}: TYPE_VECTOR2,
		{'a': TYPE_VECTOR2, 'b': TYPE_INT}: TYPE_VECTOR2,
		{'a': TYPE_VECTOR2, 'b': TYPE_FLOAT}: TYPE_VECTOR2,
	}

	# Can compose expressions:
	var c = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(1, 2)")
	a_plus_b.bind_arguments({'a': a, 'b': b})
	a_plus_b_divided.bind_arguments({'a': a_plus_b, 'b': c})
	assert_false(a_plus_b_divided.has_errors())
	assert_eq(a_plus_b_divided.get_generated_code(), "(Vector2(100, 100) + Vector2(200, 0)) / Vector2(1, 2)")
	assert_eq(a_plus_b_divided.get_type(), TYPE_VECTOR2)
	
	# int / Vector2 is not possible!
	a_plus_b_divided.bind_arguments({
		'a': BlockLiteralResource.new(BlockResource.Category.MATH, "123"),
		'b': c,
	})
	assert_true(a_plus_b_divided.has_errors())
