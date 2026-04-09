extends Node2D

## 城镇系统管理器

@onready var gold_label: Label = $GoldLabel
@onready var hospital_btn: Button = $BuildingList/HospitalButton
@onready var quest_btn: Button = $BuildingList/QuestBoardButton
@onready var dungeon_btn: Button = $BuildingList/DungeonEntranceButton

## 建筑类型枚举
enum BuildingType {
	HOSPITAL,
	QUEST_BOARD,
	DUNGEON_ENTRANCE,
}

## 金币
var current_gold: int = 100

func _ready() -> void:
	print("[TownManager] Town initialized")

	# 如果队伍为空，初始化默认队伍
	if GameManager.party.is_empty():
		_init_default_party()

	current_gold = GameManager.gold
	_update_gold_display()

	# 连接信号
	SignalManager.gold_changed.connect(_on_gold_changed)
	SignalManager.building_interacted.connect(_on_building_interacted)

	# 连接按钮信号
	hospital_btn.pressed.connect(_on_hospital_pressed)
	quest_btn.pressed.connect(_on_quest_pressed)
	dungeon_btn.pressed.connect(_on_dungeon_pressed)

## 初始化默认队伍
func _init_default_party() -> void:
	print("[TownManager] Initializing default party...")

	# 加载角色数据
	var alice_data = load("res://resources/characters/character_data_alice.tres")
	var lily_data = load("res://resources/characters/character_data_lily.tres")
	var shana_data = load("res://resources/characters/character_data_shana.tres")

	# 创建角色实例
	var alice = CharacterInstance.new(alice_data)
	var lily = CharacterInstance.new(lily_data)
	var shana = CharacterInstance.new(shana_data)

	# 设置位置
	alice.current_slot_index = 0
	lily.current_slot_index = 1
	shana.current_slot_index = 2

	# 添加到队伍
	GameManager.party = [alice, lily, shana]
	GameManager.init_party(GameManager.party)

	print("[TownManager] Default party created: ", GameManager.party.size(), " members")

## 与建筑交互
func interact_with_building(building_type: BuildingType) -> void:
	print("[TownManager] Interacting with building: ", building_type)
	SignalManager.building_interacted.emit(BuildingType.keys()[building_type])

## 医院交互
func hospital_interact() -> void:
	print("[TownManager] Hospital interact called")
	var heal_cost = 50

	if current_gold < heal_cost:
		print("[TownManager] Not enough gold! Need ", heal_cost, " but have ", current_gold)
		return

	# 扣金币
	GameManager.add_gold(-heal_cost)

	# 加血 - 恢复所有队伍成员
	var healed_count = 0
	for member in GameManager.party:
		if member and member.is_alive:
			var max_hp = member.get_max_hp()
			if member.current_hp < max_hp:
				member.current_hp = max_hp
				healed_count += 1

	print("[TownManager] Healed ", healed_count, " party members for ", heal_cost, " gold")
	print("[TownManager] Remaining gold: ", GameManager.gold)

## 任务板交互（暂时只打印日志）
func quest_board_interact() -> void:
	print("[TownManager] Quest board - no quests available yet")

## 进入地牢
func enter_dungeon() -> void:
	print("[TownManager] Entering dungeon...")
	GameManager.change_scene("res://scenes/dungeon/dungeon_scene.tscn")

## 按钮回调
func _on_hospital_pressed() -> void:
	print("[TownManager] Hospital button pressed")
	hospital_interact()

func _on_quest_pressed() -> void:
	print("[TownManager] Quest button pressed")
	quest_board_interact()

func _on_dungeon_pressed() -> void:
	print("[TownManager] Dungeon button pressed")
	enter_dungeon()

## 信号回调
func _on_gold_changed(new_gold: int) -> void:
	current_gold = new_gold
	_update_gold_display()

func _on_building_interacted(building_type: String) -> void:
	print("[TownManager] Building interacted: ", building_type)

## 更新金币显示
func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: " + str(current_gold)
