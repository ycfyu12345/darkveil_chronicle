extends Resource
class_name CharacterData

## 角色基础数据模板（Resource，不包含运行时状态）

## 属性
@export var id: String = ""
@export var name: String = ""
@export var portrait_path: String = ""
@export var rarity: int = 1  # 1=普通, 2=稀有, 3=史诗, 4=传说

## 基础属性
@export var base_hp: int = 0
@export var base_attack: int = 0
@export var base_defense: int = 0
@export var base_speed: int = 0
@export var base_magic: int = 0

@export var skill_ids: Array[String] = []

## 获取属性值的便捷方法
func get_base_stats() -> Dictionary:
	return {
		"hp": base_hp,
		"attack": base_attack,
		"defense": base_defense,
		"speed": base_speed,
		"magic": base_magic,
	}
