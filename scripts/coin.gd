extends Node2D
## Koin persembahan: memantul keluar dari pintu, lalu bisa dipungut kucing.

var velocity := Vector2.ZERO
var world: Node = null
var _settled := false
var _t := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * 8.0) % 4
	if not _settled:
		velocity.y += 260.0 * delta
		position += velocity * delta
		position.x = clampf(position.x, 4.0, world.world_w - 4.0)
		if position.y >= 0.0 and velocity.y > 0.0:
			position.y = 0.0
			if velocity.y > 40.0:
				velocity = Vector2(velocity.x * 0.6, -velocity.y * 0.4)
			else:
				_settled = true

	var p = world.player
	if _t > 0.3 and p.state == p.State.GROUND and absf(p.position.x - position.x) < 7.0 and p.coins < p.max_coins:
		p.coins += 1
		queue_free()
