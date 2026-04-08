extends Node

## 视觉效果管理器

func screen_shake(intensity: int, duration: float) -> void:
	print("[EffectsManager] screen_shake - intensity: ", intensity, ", duration: ", duration)
	# TODO: 实现屏幕震动效果

func show_damage_number(value: int, position: Vector2, is_critical: bool) -> void:
	var prefix = "CRIT! " if is_critical else ""
	print("[EffectsManager] show_damage_number - ", prefix, value, " at ", position)
	# TODO: 实现伤害数字显示
