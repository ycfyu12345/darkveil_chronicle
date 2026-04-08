extends Node
class_name MonsterAI

## 怪物AI决策

## 选择技能
## monster: 怪物数据
## available_skills: 可用技能数组
func choose_skill(monster, available_skills: Array) -> SkillCard:
	if available_skills.is_empty():
		push_warning("[MonsterAI] No available skills")
		return null

	# 检查是否需要保命 (血量 < 30%)
	var needs_emergency = _check_emergency(monster)

	if needs_emergency and monster.emergency_skill_id != "":
		# 优先使用保命技能
		var emergency_skill = _find_skill_by_id(available_skills, monster.emergency_skill_id)
		if emergency_skill:
			print("[MonsterAI] Monster ", monster.name, " using emergency skill: ", emergency_skill.name)
			return emergency_skill

	# 否则按权重随机选择
	return _choose_by_weight(available_skills)

## 检查是否需要保命技能
func _check_emergency(monster) -> bool:
	var current_hp: int = 0
	var max_hp: int = 0

	if monster is MonsterData:
		current_hp = monster.current_hp if "current_hp" in monster else monster.base_stats.hp
		max_hp = monster.base_stats.hp
	elif monster is Dictionary:
		current_hp = monster.get("current_hp", 0)
		max_hp = monster.get("max_hp", 1)

	if max_hp == 0:
		return false

	var hp_percent = float(current_hp) / float(max_hp)
	return hp_percent < 0.3

## 根据权重随机选择技能
func _choose_by_weight(skills: Array) -> SkillCard:
	var total_weight = 0
	var weighted_list: Array = []

	for skill in skills:
		var weight = 1  # 默认权重
		if skill is SkillCard and skill.id in skill.skill_weights:
			weight = skill.skill_weights[skill.id]
		elif skill is Dictionary and skill.get("id") in skill.get("skill_weights", {}):
			weight = skill.skill_weights[skill.id]

		for i in range(weight):
			weighted_list.append(skill)
		total_weight += weight

	if weighted_list.is_empty():
		return skills[0] if not skills.is_empty() else null

	return weighted_list[randi() % weighted_list.size()]

## 根据ID查找技能
func _find_skill_by_id(skills: Array, skill_id: String) -> SkillCard:
	for skill in skills:
		if skill is SkillCard and skill.id == skill_id:
			return skill
		elif skill is Dictionary and skill.get("id") == skill_id:
			return skill
	return null
