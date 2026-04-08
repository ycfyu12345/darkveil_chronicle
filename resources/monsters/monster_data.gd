extends Resource
class_name MonsterData

## 怪物基础数据模板

## 怪物属性定义
class BaseStats:
	var hp: int = 0
	var attack: int = 0
	var defense: int = 0
	var speed: int = 0

## 属性
@export var id: String = ""
@export var name: String = ""
@export var position: int = 0  # 站位位置
@export var base_stats: BaseStats = BaseStats.new()
@export var skill_ids: Array[String] = []
@export var drop_gold: int = 10
@export var emergency_skill_id: String = ""  # 保命技能ID，血量<30%时优先使用
