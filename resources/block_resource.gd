class_name BlockResource
extends Resource

enum BlockType {
	METHOD,
	STATEMENT,
	VARIANT_EXPRESSION,
	NODE_EXPRESSION,
}

@export var block_type: BlockType

func _init(p_block_type: BlockType):
	block_type = block_type

func get_output() -> String:
	push_error("Not implemented")
	return ""
