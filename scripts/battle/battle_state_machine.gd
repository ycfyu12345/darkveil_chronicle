extends Node
class_name BattleStateMachine

## 战斗状态枚举
enum BattleState {
	INIT,           # 初始化
	PLAYER_INPUT,   # 玩家输入
	ACTION_QUEUE,   # 行动队列
	EXECUTION,      # 执行（含伤害计算）
	DEATH_CHECK,    # 死亡检查
	TURN_END,       # 回合结束
	BATTLE_OVER,    # 战斗结束
}

## 当前状态
var current_state: BattleState = BattleState.INIT

## 状态转换回调
var _on_state_changed: Callable

func _init(callback: Callable = Callable()) -> void:
	_on_state_changed = callback

## 获取有效转换列表
func get_valid_transitions() -> Array[BattleState]:
	match current_state:
		BattleState.INIT:
			return [BattleState.PLAYER_INPUT]
		BattleState.PLAYER_INPUT:
			return [BattleState.ACTION_QUEUE]
		BattleState.ACTION_QUEUE:
			return [BattleState.EXECUTION]
		BattleState.EXECUTION:
			return [BattleState.DEATH_CHECK]
		BattleState.DEATH_CHECK:
			return [BattleState.TURN_END, BattleState.BATTLE_OVER]
		BattleState.TURN_END:
			return [BattleState.PLAYER_INPUT]
		BattleState.BATTLE_OVER:
			return []  # 终态

	return []

## 转换到新状态
func transition_to(new_state: BattleState) -> bool:
	var valid = get_valid_transitions()

	if not new_state in valid:
		push_warning("[BattleStateMachine] Invalid transition: ", current_state, " -> ", new_state)
		return false

	var old_state = current_state
	current_state = new_state

	print("[BattleStateMachine] State transition: ", old_state, " -> ", new_state)

	if _on_state_changed.is_valid():
		_on_state_changed.call(current_state)

	return true

## 获取当前状态
func get_state() -> BattleState:
	return current_state

## 检查是否终态
func is_battle_over() -> bool:
	return current_state == BattleState.BATTLE_OVER
