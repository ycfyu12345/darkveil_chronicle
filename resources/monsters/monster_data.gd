extends Resource
class_name MonsterData

## 怪物基础数据模板

## 属性
@export var id: String = ""
@export var name: String = ""
@export var position: int = 0  # 站位位置

## 基础属性
@export var base_hp: int = 0
@export var base_attack: int = 0
@export var base_defense: int = 0
@export var base_speed: int = 0

@export var skill_ids: Array[String] = []
@export var drop_gold: int = 10
@export var emergency_skill_id: String = ""  # 保命技能ID，血量<30%时优先使用
