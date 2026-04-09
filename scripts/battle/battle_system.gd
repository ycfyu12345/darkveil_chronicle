extends Node2D

## 战斗系统核心管理器

## 子系统
var battle_logic: BattleLogic
var state_machine: BattleStateMachine
var monster_ai: MonsterAI
var position_system: PositionSystem

## 战斗单位
var player_units: Array[CharacterInstance] = []
var enemy_units: Array = []  # 运行时怪物对象

## 行动队列
var action_queue: Array = []

## 运行时技能使用次数
var runtime_skill_uses: Dictionary = {}

## 当前回合
var current_turn: int = 0

## 战斗场景根节点
@onready var battle_ui: Node = $BattleUI

func _ready() -> void:
	print("[BattleSystem] Initializing...")

	# 初始化子系统
	battle_logic = BattleLogic.new()
	state_machine = BattleStateMachine.new(func(state): _on_state_changed(state))
	monster_ai = MonsterAI.new()
	position_system = PositionSystem.new()

	# 连接信号
	battle_logic.damage_dealt.connect(_on_damage_dealt)
	battle_logic.character_died.connect(_on_character_died)
	battle_logic.battle_ended.connect(_on_battle_ended)

	# 从 GameManager 拉取战斗数据
	_pull_battle_setup()

	# 开始战斗
	_start_battle()

## 从 GameManager.current_battle_setup 拉取数据
func _pull_battle_setup() -> void:
	var setup = GameManager.current_battle_setup
	if setup == null:
		push_warning("[BattleSystem] No battle setup found in GameManager")
		return

	print("[BattleSystem] Loading battle setup - Dungeon Level: ", setup.dungeon_level)

	# 加载玩家队伍
	player_units = setup.player_party
	print("[BattleSystem] Player units: ", player_units.size())

	# 加载怪物
	for monster_data in setup.monster_party:
		var runtime_monster = _create_runtime_monster(monster_data)
		enemy_units.append(runtime_monster)
	print("[BattleSystem] Enemy units: ", enemy_units.size())

## 创建运行时怪物对象
func _create_runtime_monster(monster_data: MonsterData) -> Dictionary:
	return {
		"data": monster_data,
		"current_hp": monster_data.base_hp,
		"max_hp": monster_data.base_hp,
		"is_alive": true,
		"current_slot_index": monster_data.position,
	}

## 开始战斗
func _start_battle() -> void:
	print("[BattleSystem] Battle starting...")
	current_turn = 1
	_initialize_skill_uses()
	state_machine.transition_to(BattleStateMachine.BattleState.PLAYER_INPUT)
	_print_battle_state()

## 初始化技能使用次数
func _initialize_skill_uses() -> void:
	runtime_skill_uses.clear()
	for unit in player_units:
		if unit is CharacterInstance:
			for skill_id in unit.character_data.skill_ids:
				runtime_skill_uses[skill_id] = -1  # -1 表示每回合恢复

## 状态改变回调
func _on_state_changed(state: BattleStateMachine.BattleState) -> void:
	print("[BattleSystem] State changed to: ", state)
	match state:
		BattleStateMachine.BattleState.PLAYER_INPUT:
			_handle_player_input()
		BattleStateMachine.BattleState.EXECUTION:
			_execute_actions()
		BattleStateMachine.BattleState.DEATH_CHECK:
			_check_deaths()
		BattleStateMachine.BattleState.TURN_END:
			_end_turn()
		BattleStateMachine.BattleState.BATTLE_OVER:
			_handle_battle_over()

## 玩家输入处理
func _handle_player_input() -> void:
	print("[BattleSystem] Awaiting player input...")
	# 验证所有技能可用性
	_validate_all_skills()

## 验证所有技能的可用性
## 返回: Dictionary {skill_id: bool} true=可用, false=不可用
func _validate_all_skills() -> Dictionary:
	var validation_result: Dictionary = {}

	# 获取当前存活的玩家单位
	var alive_units = player_units.filter(func(u): return u.is_alive)
	if alive_units.is_empty():
		return validation_result

	var current_unit = alive_units[0]  # 当前行动单位

	# 获取当前单位的位置
	var current_position = current_unit.current_slot_index

	# 构建位置字典
	var position_dict: Dictionary = {}
	for i in range(enemy_units.size()):
		position_dict[i] = enemy_units[i]

	# 验证每个技能
	for skill_id in current_unit.character_data.skill_ids:
		var skill_res = load("res://resources/skills/" + skill_id + ".tres") if not skill_id.begins_with("skill_") else load("res://resources/skills/" + skill_id + ".tres")
		if skill_res == null:
			validation_result[skill_id] = false
			continue

		# 检查技能是否还有使用次数
		var uses = runtime_skill_uses.get(skill_id, -1)
		if uses == 0:
			validation_result[skill_id] = false
			continue

		# 检查技能目标位置是否合法
		var is_valid = position_system.check_position_validity(skill_res, current_position, position_dict)
		validation_result[skill_id] = is_valid

	print("[BattleSystem] Skill validation: ", validation_result)
	return validation_result

## 获取技能验证结果（供UI调用）
func get_skill_validation() -> Dictionary:
	return _validate_all_skills()

## 添加行动到队列
func queue_action(unit, skill: SkillCard, target_position: int) -> void:
	action_queue.append({
		"unit": unit,
		"skill": skill,
		"target_position": target_position,
	})
	print("[BattleSystem] Action queued for: ", unit.character_data.name if unit is CharacterInstance else unit.get("data", {}).get("name", "?"))

	# 当队列满时（玩家+怪物都行动完），进入执行阶段
	if action_queue.size() >= _get_expected_action_count():
		state_machine.transition_to(BattleStateMachine.BattleState.EXECUTION)

## 获取预期的行动数量
func _get_expected_action_count() -> int:
	var count = 0
	for unit in player_units:
		if unit.is_alive:
			count += 1
	count += enemy_units.size()  # 假设所有怪物都活着
	return count

## 执行行动队列
func _execute_actions() -> void:
	print("[BattleSystem] Executing action queue...")
	action_queue.clear()
	# TODO: 按行动顺序执行，使用 await 等待动画

	state_machine.transition_to(BattleStateMachine.BattleState.DEATH_CHECK)

## 死亡检查
func _check_deaths() -> void:
	print("[BattleSystem] Checking deaths...")

	# 检查玩家单位
	var all_dead = true
	for unit in player_units:
		if unit.is_alive:
			all_dead = false
			break

	if all_dead:
		print("[BattleSystem] All player units dead - DEFEAT")
		battle_logic.battle_ended.emit(false)
		SignalManager.battle_lost.emit()
		state_machine.transition_to(BattleStateMachine.BattleState.BATTLE_OVER)
		return

	# 检查怪物
	var enemy_dead = true
	for enemy in enemy_units:
		if enemy.get("is_alive", false):
			enemy_dead = false
			break

	if enemy_dead:
		print("[BattleSystem] All enemies dead - VICTORY")
		battle_logic.battle_ended.emit(true)
		state_machine.transition_to(BattleStateMachine.BattleState.BATTLE_OVER)
		return

	state_machine.transition_to(BattleStateMachine.BattleState.TURN_END)

## 回合结束
func _end_turn() -> void:
	print("[BattleSystem] Turn ", current_turn, " ended")
	current_turn += 1
	_reset_skill_uses()
	state_machine.transition_to(BattleStateMachine.BattleState.PLAYER_INPUT)

## 重置技能使用次数（每回合恢复）
func _reset_skill_uses() -> void:
	for skill_id in runtime_skill_uses:
		if runtime_skill_uses[skill_id] == 0:
			runtime_skill_uses[skill_id] = -1  # 恢复

## 战斗结束处理
func _handle_battle_over() -> void:
	print("[BattleSystem] Battle OVER")
	var victory = state_machine.get_state() == BattleStateMachine.BattleState.BATTLE_OVER
	SignalManager.battle_won.emit(victory)

## 信号处理
func _on_damage_dealt(amount: int, target, is_critical: bool) -> void:
	var target_name = target.character_data.name if target is CharacterInstance else target.get("data", {}).get("name", "?")
	print("[BattleSystem] Damage dealt: ", amount, " to ", target_name, " (critical: ", is_critical, ")")

func _on_character_died(character) -> void:
	print("[BattleSystem] Character died: ", character.character_data.name)

func _on_battle_ended(victory: bool) -> void:
	print("[BattleSystem] Battle ended - Victory: ", victory)

## 打印战斗状态
func _print_battle_state() -> void:
	print("=== Battle State ===")
	print("Turn: ", current_turn)
	print("Player units: ", player_units.size(), " alive")
	for unit in player_units:
		print("  - ", unit.character_data.name, ": ", unit.current_hp, "/", unit.get_max_hp(), " HP")
	print("Enemy units: ", enemy_units.size())
	for enemy in enemy_units:
		if enemy.get("is_alive", false):
			print("  - ", enemy.get("data", {}).get("name", "?"), ": ", enemy.get("current_hp", 0), "/", enemy.get("max_hp", 0), " HP")
	print("===================")
