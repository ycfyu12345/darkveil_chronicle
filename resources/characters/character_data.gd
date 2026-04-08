extends Resource
class_name CharacterData

## 角色基础数据模板（Resource，不包含运行时状态）

## 角色属性定义
class BaseStats:
	var hp: int = 0
	var attack: int = 0
	var defense: int = 0
	var speed: int = 0
	var magic: int = 0

## 属性
@export var id: String = ""
@export var name: String = ""
@export var portrait_path: String = ""
@export var rarity: int = 1  # 1=普通, 2=稀有, 3=史诗, 4=传说
@export var base_stats: BaseStats = BaseStats.new()
@export var skill_ids: Array[String] = []
