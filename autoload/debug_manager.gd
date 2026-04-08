extends Node

## 调试功能管理器
## F1=跳转战斗, F2=满血, F3=+1000金

func _ready() -> void:
	print("[DebugManager] Debug mode enabled - F1/F2/F3 available")

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	# F1: 跳转战斗
	if event.is_action_pressed("debug_battle"):
		print("[DebugManager] F1 pressed - entering battle (debug)")
		_start_debug_battle()

	# F2: 满血
	if event.is_action_pressed("debug_full_heal"):
		print("[DebugManager] F2 pressed - full heal party")
		_full_heal_party()

	# F3: +1000金币
	if event.is_action_pressed("debug_gold"):
		print("[DebugManager] F3 pressed - adding 1000 gold")
		GameManager.add_gold(1000)

func _start_debug_battle() -> void:
	# 设置战斗上下文并跳转
	var battle_setup = GameManager.BattleSetup.new()
	battle_setup.dungeon_level = 1
	battle_setup.player_party = GameManager.party.duplicate()

	# 创建测试怪物
	var monster_res = load("res://resources/monsters/monster_data_slime.tres")
	if monster_res:
		battle_setup.monster_party = [monster_res]
	else:
		push_warning("[DebugManager] monster_data_slime.tres not found, using placeholder")

	GameManager.current_battle_setup = battle_setup
	GameManager.game_state = GameManager.GameState.BATTLE
	GameManager.change_scene("res://scenes/battle/battle_scene.tscn")

func _full_heal_party() -> void:
	for member in GameManager.party:
		if member and member.is_alive:
			member.current_hp = member.character_data.base_stats.hp
			print("[DebugManager] Healed ", member.character_data.name)
