class_name BlockResource
extends Resource

## The ID of the matching block object that this resource represents.
@export var block_id: StringName

## The block position in the canvas. Only relevant when the block is detached. The position of
## blocks attached to other blocks will be calculated, and this property is ignored.
@export var position: Vector2i

func _init(p_block_id: StringName, p_position: Vector2i = Vector2.ZERO):
	block_id = p_block_id
	position = p_position
