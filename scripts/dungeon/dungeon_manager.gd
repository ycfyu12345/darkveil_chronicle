extends Node2D

## 地牢系统管理器

@onready var progress_label: Label = $ExplorationUI/ProgressLabel
@onready var advance_btn: Button = $ExplorationUI/AdvanceButton
@onready var retreat_btn: Button = $ExplorationUI/RetreatButton

## 地牢配置
var total_rooms: int = 5
var current_room_index: int = 0

## 怪物配置（存储在 DungeonManager 内部）
var monster_pools: Dictionary = {
	1: ["monster_data_slime"],
	2: ["monster_data_slime", "monster_data_goblin"],
	3: ["monster_data_goblin"],
	4: ["monster_data_goblin", "monster_data_slime"],
	5: ["monster_data_boss"],
}

## 当前房间怪物
var current_monsters: Array = []

func _ready() -> void:
	print("[DungeonManager] Dungeon initialized - Total rooms: ", total_rooms)
	_update_ui()
	_connect_signals()

## 连接信号
func _connect_signals() -> void:
	advance_btn.pressed.connect(_on_advance_pressed)
	retreat_btn.pressed.connect(_on_retreat_pressed)

	# 连接战斗结果信号
	SignalManager.battle_won.connect(_on_battle_won)
	SignalManager.battle_lost.connect(_on_battle_lost)

## 前进到下一个房间
func advance_room() -> void:
	if current_room_index >= total_rooms:
		print("[DungeonManager] Already at final room!")
		return

	current_room_index += 1
	print("[DungeonManager] Advanced to room ", current_room_index)
	spawn_monsters(current_room_index)
	_update_ui()

## 生成房间怪物
func spawn_monsters(room_index: int) -> void:
	current_monsters.clear()

	var pool = monster_pools.get(room_index, [])
	for monster_id in pool:
		var monster_res = load("res://resources/monsters/" + monster_id + ".tres")
		if monster_res:
			current_monsters.append(monster_res)
			print("[DungeonManager] Spawned monster: ", monster_res.name)

	print("[DungeonManager] Room ", room_index, " has ", current_monsters.size(), " monsters")

## 开始战斗
func start_battle() -> void:
	print("[DungeonManager] Starting battle...")

	# 设置战斗上下文
	var battle_setup = GameManager.BattleSetup.new()
	battle_setup.player_party = GameManager.party
	battle_setup.monster_party = current_monsters.duplicate()
	battle_setup.dungeon_level = current_room_index

	GameManager.current_battle_setup = battle_setup
	GameManager.game_state = GameManager.GameState.BATTLE

	# 切换到战斗场景
	GameManager.change_scene("res://scenes/battle/battle_scene.tscn")

## 返回城镇
func return_to_town() -> void:
	print("[DungeonManager] Returning to town...")
	GameManager.game_state = GameManager.GameState.TOWN
	GameManager.change_scene("res://scenes/town/town_scene.tscn")

## 更新UI
func _update_ui() -> void:
	if progress_label:
		progress_label.text = "Room: " + str(current_room_index) + " / " + str(total_rooms)

	advance_btn.disabled = current_room_index >= total_rooms
	retreat_btn.disabled = current_room_index <= 0

## 按钮回调
func _on_advance_pressed() -> void:
	print("[DungeonManager] Advance button pressed")
	if current_monsters.size() > 0:
		start_battle()
	else:
		advance_room()

func _on_retreat_pressed() -> void:
	print("[DungeonManager] Retreat button pressed")
	return_to_town()

## 战斗结果回调
func _on_battle_won(victory: bool) -> void:
	if victory:
		print("[DungeonManager] Battle won!")
		# 清空当前房间怪物
		current_monsters.clear()

		# 检查是否通关
		if current_room_index >= total_rooms:
			print("[DungeonManager] Dungeon cleared! Returning to town with rewards...")
			GameManager.add_gold(100)  # 通关奖励
			return_to_town()
		else:
			# 显示胜利UI，让玩家选择继续或返回
			pass

func _on_battle_lost() -> void:
	print("[DungeonManager] Battle lost! Returning to town...")
	return_to_town()
