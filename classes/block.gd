class_name Block
extends Object

enum Type {
	LITERAL,
	VARIABLE,
	EXPRESSION,
	STATEMENT,
	CONTROL,
	METHOD,
}

enum Category {
	PHYSICS,
	MATH,
}
@export var block_type: Type
@export var category: Category

func _init(p_block_type: Type, p_category: Category):
	block_type = p_block_type
	category = p_category

## Fuzzy means that the block is missing data. So it can't generate code yet.
func is_fuzzy() -> bool:
	push_error("Not implemented.")
	return true

func get_generated_code() -> String:
	push_error("Not implemented.")
	return ""
