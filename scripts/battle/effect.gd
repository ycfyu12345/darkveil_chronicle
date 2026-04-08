## 战斗效果类型枚举
enum EffectType {
	DAMAGE,       # 伤害
	DAMAGE_BUFF,  # 伤害增益
	HEAL,         # 治疗
	DEBUFF,       # 减益
}

## 效果条件
class EffectCondition:
	var require_target_alive: bool = true
	var require_source_alive: bool = true
	var min_hp_percent: float = 0.0  # 源目标HP百分比要求
	var max_hp_percent: float = 1.0

## 战斗效果数据结构
class Effect:
	var type: EffectType
	var base_value: int = 0
	var multiplier: float = 1.0
	var condition: EffectCondition = EffectCondition.new()

	## 获取最终效果值
	func get_final_value() -> int:
		return int(base_value * multiplier)

## 创建伤害效果
static func create_damage(base_damage: int, multiplier: float = 1.0) -> Effect:
	var e = Effect.new()
	e.type = EffectType.DAMAGE
	e.base_value = base_damage
	e.multiplier = multiplier
	return e

## 创建治疗效果
static func create_heal(base_heal: int, multiplier: float = 1.0) -> Effect:
	var e = Effect.new()
	e.type = EffectType.HEAL
	e.base_value = base_heal
	e.multiplier = multiplier
	return e

## 创建伤害增益效果
static func create_damage_buff(percent: float) -> Effect:
	var e = Effect.new()
	e.type = EffectType.DAMAGE_BUFF
	e.base_value = 0
	e.multiplier = percent
	return e

## 创建减益效果
static func create_debuff(base_value: int) -> Effect:
	var e = Effect.new()
	e.type = EffectType.DEBUFF
	e.base_value = base_value
	return e
