extends Node
class_name PositionSystem

## 位置系统 - 管理战斗中的站位和死亡替换

## 检查技能对当前站位是否合法
## skill: 技能
## target_position: 目标位置索引
## current_positions: 当前站位状态字典 {position_index: unit}
func check_position_validity(skill: SkillCard, target_position: int, current_positions: Dictionary) -> bool:
	if skill.target_position == SkillCard.TargetPosition.ANY:
		return true

	# 获取目标位置上的单位
	var target_unit = current_positions.get(target_position, null)
	if target_unit == null:
		return false

	# 检查目标是否活着
	if target_unit is CharacterInstance and not target_unit.is_alive:
		return false

	# 根据 target_position 判断是否合法
	match skill.target_position:
		SkillCard.TargetPosition.FRONT:
			# 需要目标是前排单位
			# 前排通常是位置 0, 1
			return target_position in [0, 1]
		SkillCard.TargetPosition.BACK:
			# 需要目标是后排单位
			# 后排通常是位置 2, 3
			return target_position in [2, 3]

	return true

## 应用死亡并填充站位
## 只修改 current_slot_index，不修改数组顺序
## dead_unit: 死亡的单位
## all_units: 所有单位数组
func apply_death_and_fill(dead_unit, all_units: Array) -> void:
	if dead_unit is CharacterInstance:
		dead_unit.is_alive = false
		# current_slot_index 保持不变，用于UI显示死亡状态

## 重新排列站位
## 根据 current_slot_index 更新显示位置
## units: 存活单位数组
## positions: 位置数组 (通常 4 个位置: [0, 1, 2, 3] 代表前排2+后排2)
func rearrange_positions(units: Array, positions: Array) -> Dictionary:
	var result: Dictionary = {}

	# 将存活单位分配到空位置
	# 前排优先填充
	var front_positions = [0, 1]
	var back_positions = [2, 3]

	var alive_units: Array = []
	for unit in units:
		if unit is CharacterInstance and unit.is_alive:
			alive_units.append(unit)

	# 分配前排
	var front_index = 0
	for pos in front_positions:
		if front_index < alive_units.size():
			result[pos] = alive_units[front_index]
			alive_units[front_index].current_slot_index = pos
			front_index += 1

	# 分配后排
	var back_index = 0
	for pos in back_positions:
		if front_index + back_index < units.size():
			if not result.has(pos):
				result[pos] = null  # 空位置

	return result

## 获取有效目标位置列表
func get_valid_target_positions(skill: SkillCard, units: Array) -> Array:
	var valid_positions: Array = []

	for i in range(4):  # 假设4个位置
		if check_position_validity(skill, i, _get_position_dict(units)):
			valid_positions.append(i)

	return valid_positions

## 获取位置字典
func _get_position_dict(units: Array) -> Dictionary:
	var dict: Dictionary = {}
	for i in range(units.size()):
		dict[i] = units[i]
	return dict
