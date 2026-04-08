extends Node
class_name BattleLogic

## 防御公式常量: 防御力减伤比例
const DEFENSE_REDUCTION_RATIO: float = 0.5

## 信号定义
signal damage_dealt(amount: int, target, is_critical: bool)
signal character_died(character)
signal battle_ended(victory: bool)

## 伤害计算
## attacker: 攻击方 (CharacterInstance 或 MonsterData)
## defender: 防守方 (CharacterInstance)
## multiplier: 伤害倍率
func calculate_damage(attacker, defender, multiplier: float = 1.0) -> int:
	var base_damage: int = 0

	# 获取攻击方攻击力
	if attacker is CharacterInstance:
		base_damage = attacker.get_attack()
	elif attacker is MonsterData:
		base_damage = attacker.base_stats.attack
	else:
		push_warning("[BattleLogic] Unknown attacker type")
		return 0

	# 获取防御方防御力
	var defense: int = 0
	if defender is CharacterInstance:
		defense = defender.get_defense()
	else:
		defense = defender.defense if "defense" in defender else 0

	# 最终伤害 = max(1, 基础伤害 * 倍率 - 防御力 * DEFENSE_REDUCTION_RATIO)
	var final_damage: int = max(1, int(base_damage * multiplier - defense * DEFENSE_REDUCTION_RATIO))

	# 速度平局时 randi() 结果不稳定，使用随机偏移
	var variance = randi() % 5 - 2  # -2 到 +2 的随机偏移
	final_damage = max(1, final_damage + variance)

	return final_damage

## 应用伤害
func apply_damage(target, amount: int, is_critical: bool = false) -> void:
	if target is CharacterInstance:
		target.take_damage(amount)
		damage_dealt.emit(amount, target, is_critical)
		if not target.is_alive:
			character_died.emit(target)
	elif target is MonsterData:
		# MonsterData 是只读模板，不能直接修改
		# 需要在 BattleSystem 中用运行时对象管理
		damage_dealt.emit(amount, target, is_critical)

## 获取速度平局时的随机结果
func get_speed_tie_breaker(speed1: int, speed2: int) -> bool:
	# 当速度相同时，使用 randi() 决定谁先行动
	# 返回 true 表示 speed1 先手
	if speed1 == speed2:
		return randi() % 2 == 0
	return speed1 > speed2

## 获取行动顺序
## units: 单元数组 (CharacterInstance 或运行时怪物对象)
func get_turn_order(units: Array) -> Array:
	var sorted = units.duplicate()

	# 使用自定义排序
	sorted.sort_custom(func(a, b):
		var speed_a = _get_unit_speed(a)
		var speed_b = _get_unit_speed(b)

		if speed_a != speed_b:
			return speed_a > speed_b  # 速度高的先手

		# 速度相同则随机
		return randi() % 2 == 0
	)

	return sorted

## 获取单元速度
func _get_unit_speed(unit) -> int:
	if unit is CharacterInstance:
		return unit.get_speed()
	elif unit is MonsterData:
		return unit.base_stats.speed
	elif unit.has("speed"):
		return unit.speed
	return 0
