extends Node

## 游戏状态枚举
enum GameState {
	TOWN,
	DUNGEON,
	BATTLE,
}

## 战斗上下文数据结构
class BattleSetup:
	var player_party: Array = []
	var monster_party: Array = []
	var dungeon_level: int = 1

## 全局游戏状态
var game_state: GameState = GameState.TOWN
var gold: int = 100
var party: Array = []

## 战斗上下文（供 BattleSystem 拉取）
var current_battle_setup: BattleSetup = null

func _ready() -> void:
	print("[GameManager] Initialized - GameState: ", game_state, ", Gold: ", gold)

## 切换场景
func change_scene(scene_path: String) -> void:
	print("[GameManager] Changing scene to: ", scene_path)
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[GameManager] Failed to change scene: ", err)
	else:
		print("[GameManager] Scene changed successfully")

## 初始化玩家队伍
func init_party(characters: Array) -> void:
	party = characters
	print("[GameManager] Party initialized with ", party.size(), " members")

## 获取队伍中活着的成员
func get_alive_party_members() -> Array:
	var alive: Array = []
	for member in party:
		if member.is_alive:
			alive.append(member)
	return alive

## 修改金币
func add_gold(amount: int) -> void:
	gold += amount
	SignalManager.gold_changed.emit(gold)
	print("[GameManager] Gold changed: ", gold)