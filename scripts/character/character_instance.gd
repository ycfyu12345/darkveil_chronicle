class_name CharacterInstance

## 角色实例（运行时状态，不修改 Resource 模板）

## 属性
var character_data: CharacterData
var current_hp: int
var experience: int = 0
var is_alive: bool = true
var current_slot_index: int = 0

func _init(data: CharacterData) -> void:
	character_data = data
	current_hp = data.base_stats.hp
	is_alive = current_hp > 0

## 获取当前HP
func get_current_hp() -> int:
	return current_hp

## 获取最大HP
func get_max_hp() -> int:
	return character_data.base_stats.hp

## 受到伤害
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	if current_hp <= 0:
		is_alive = false
		print("[CharacterInstance] ", character_data.name, " died")

## 治疗
func heal(amount: int) -> void:
	if is_alive:
		current_hp = min(get_max_hp(), current_hp + amount)

## 获取属性
func get_attack() -> int:
	return character_data.base_stats.attack

func get_defense() -> int:
	return character_data.base_stats.defense

func get_speed() -> int:
	return character_data.base_stats.speed

func get_magic() -> int:
	return character_data.base_stats.magic
