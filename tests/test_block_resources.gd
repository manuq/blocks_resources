extends GutTest

func test_blocks_builtin_operands():
	var a_vector2 = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(100, 100)")
	assert_eq(a_vector2.category, BlockResource.Category.MATH)

	# A literal is a literal:
	assert_eq(a_vector2.get_generated_code(), "Vector2(100, 100)")
	
	# Type can be infered from builtin types:
	assert_eq(a_vector2.get_type(), TYPE_VECTOR2)

	# FIXME not a double so we can't spy:
	# assert_called(a, '_infer_type')

	assert_false(a_vector2.has_errors())

	# Trying to infer type from literals that don't parse leads to error:
	var wrong = BlockLiteralResource.new(BlockResource.Category.MATH, "#%%!!")
	assert_true(wrong.has_errors())
	assert_eq(wrong.get_error_message(), "Unexpected character.")
	assert_eq(wrong.get_type(), TYPE_NIL)

	# Type can be explicit too. TODO: needed? Or do this only for variables?
	var b_vector2 = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(200, 0)", TYPE_VECTOR2)
	assert_eq(b_vector2.get_type(), TYPE_VECTOR2)

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
	assert_true(a_plus_b.has_unbound_arguments())
	assert_eq(a_plus_b.get_type(), TYPE_NIL)

	# Can bind all at once. Not realistic (blocks are attached one by one to slots) but good for testing:
	a_plus_b.bind_arguments({'a': a_vector2, 'b': b_vector2})
	assert_false(a_plus_b.has_unbound_arguments())

	# Can do Vector2 + Vector2:
	assert_eq(a_plus_b.get_generated_code(), "Vector2(100, 100) + Vector2(200, 0)")

	# The expression type corresponds, Vector2 + Vector2 -> Vector2:
	assert_eq(a_plus_b.get_type(), TYPE_VECTOR2)

	# Confirm the type with real script:
	assert_eq(a_plus_b.get_type(), typeof(Vector2(100, 100) + Vector2(200, 0)))

	# Can unbind the arguments one by one (user detaching a block from a slot):
	a_plus_b.unbind_argument('a')
	assert_true(a_plus_b.has_unbound_arguments())
	a_plus_b.unbind_argument('b')
	assert_true(a_plus_b.has_unbound_arguments())

	# Can tell beforehand if bind is possible:
	assert_true(a_plus_b.can_bind_argument('a', a_vector2))
	assert_true(a_plus_b.can_bind_argument('a', BlockLiteralResource.new(BlockResource.Category.MATH, "1.1", TYPE_FLOAT)))

	# Can bind the arguments one by one (user attaching a block from a slot):
	assert_true(a_plus_b.has_unbound_arguments())
	a_plus_b.bind_argument('a', a_vector2)
	assert_true(a_plus_b.has_unbound_arguments())
	a_plus_b.bind_argument('b', b_vector2)
	assert_false(a_plus_b.has_errors())
	assert_false(a_plus_b.has_unbound_arguments())
	assert_eq(a_plus_b.get_generated_code(), "Vector2(100, 100) + Vector2(200, 0)")
	assert_eq(a_plus_b.get_type(), TYPE_VECTOR2)

	# Can unbind all at once. Not realistic (blocks are detached one by one to slots) but good for testing:
	a_plus_b.unbind_arguments()

	# Vector2 + int is not possible!
	a_plus_b.bind_arguments({
		'a': a_vector2,
		'b': BlockLiteralResource.new(BlockResource.Category.MATH, "123"),
	})
	assert_true(a_plus_b.has_errors())
	assert_eq(a_plus_b.get_error_message(), "Invalid argument types.")
	assert_eq(a_plus_b.get_type(), TYPE_NIL)

	var a_plus_b_divided = BlockExpressionResource.new(BlockResource.Category.MATH, "{dividend} / {divisor}")
	a_plus_b_divided.argument_types = {
		# TODO: Complete this mapping.
		{'dividend': TYPE_INT, 'divisor': TYPE_INT}: TYPE_INT,
		{'dividend': TYPE_INT, 'divisor': TYPE_FLOAT}: TYPE_FLOAT,
		{'dividend': TYPE_VECTOR2, 'divisor': TYPE_VECTOR2}: TYPE_VECTOR2,
		{'dividend': TYPE_VECTOR2, 'divisor': TYPE_INT}: TYPE_VECTOR2,
		{'dividend': TYPE_VECTOR2, 'divisor': TYPE_FLOAT}: TYPE_VECTOR2,
	}

	# Can compose expressions:
	var c_vector2 = BlockLiteralResource.new(BlockResource.Category.MATH, "Vector2(1, 2)")
	a_plus_b.bind_arguments({'a': a_vector2, 'b': b_vector2})
	a_plus_b_divided.bind_arguments({'dividend': a_plus_b, 'divisor': c_vector2})
	assert_false(a_plus_b_divided.has_errors())
	assert_eq(a_plus_b_divided.get_generated_code(), "(Vector2(100, 100) + Vector2(200, 0)) / Vector2(1, 2)")
	assert_eq(a_plus_b_divided.get_type(), TYPE_VECTOR2)
	
	# int / Vector2 is not possible!
	a_plus_b_divided.bind_arguments({
		'dividend': BlockLiteralResource.new(BlockResource.Category.MATH, "123"),
		'divisor': c_vector2,
	})
	assert_false(a_plus_b_divided.has_valid_argument_types())
	assert_true(a_plus_b_divided.has_errors())
	assert_eq(a_plus_b_divided.get_error_message(), "Invalid argument types.")

	# Can compose expressions before binding:
	a_plus_b.unbind_arguments()
	a_plus_b_divided.unbind_arguments()
	a_plus_b_divided.bind_argument('dividend', a_plus_b)
	assert_false(a_plus_b_divided.has_errors())
	assert_eq(a_plus_b_divided.get_generated_code(), "")

	# Methods that return a value:
	var length_squared = BlockExpressionResource.new(BlockResource.Category.MATH, "{this}.length_squared()")
	length_squared.argument_types = {
		{'this': TYPE_VECTOR2}: TYPE_FLOAT,
	}
	a_plus_b.bind_arguments({'a': a_vector2, 'b': b_vector2})
	length_squared.bind_arguments({'this': a_plus_b})
	assert_eq(length_squared.get_generated_code(), "(Vector2(100, 100) + Vector2(200, 0)).length_squared()")
	assert_eq(length_squared.get_type(), TYPE_FLOAT)

	var lerp_block = BlockExpressionResource.new(BlockResource.Category.MATH, "{this}.lerp({to}, {weight})")
	lerp_block.argument_types = {
		{'this': TYPE_VECTOR2, 'to': TYPE_VECTOR2, 'weight': TYPE_FLOAT}: TYPE_VECTOR2,
	}
	a_plus_b.bind_arguments({'a': a_vector2, 'b': b_vector2})
	lerp_block.bind_arguments({'this': a_plus_b, 'to': c_vector2, 'weight': BlockLiteralResource.new(BlockResource.Category.MATH, "0.5")})
	assert_eq(lerp_block.get_generated_code(), "(Vector2(100, 100) + Vector2(200, 0)).lerp(Vector2(1, 2), 0.5)")
	assert_eq(lerp_block.get_type(), TYPE_VECTOR2)
