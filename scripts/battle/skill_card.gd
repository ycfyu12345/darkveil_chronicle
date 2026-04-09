extends Resource
class_name SkillCard

## 技能目标类型
enum TargetType {
	SINGLE,    # 单体
	MULTI,     # 多人
	ALL_ENEMY, # 所有敌人
	ALL_ALLY,  # 所有队友
	SELF,      # 自己
}

## 技能目标位置
enum TargetPosition {
	ANY,       # 任意位置
	FRONT,     # 前排
	BACK,      # 后排
	}

## 技能卡片数据模板
@export var id: String = ""
@export var name: String = ""
@export var icon_path: String = ""
@export var description: String = ""
@export var is_ultimate: bool = false
@export var max_uses: int = -1  # -1 表示每回合恢复
@export var target_type: TargetType = TargetType.SINGLE
@export var target_position: TargetPosition = TargetPosition.ANY
@export var effects: Array[Effect.Effect] = []
@export var skill_weights: Dictionary = {}  # 权重配置

## 简化的效果属性（用于 .tres 文件序列化）
## 0 = DAMAGE, 1 = DAMAGE_BUFF, 2 = HEAL, 3 = DEBUFF
@export var effect_type: int = 0  # Effect.EffectType
@export var effect_base_value: int = 0
@export var effect_multiplier: float = 1.0

## 获取效果列表
func get_effects() -> Array[Effect.Effect]:
	return effects

## 检查是否有多目标效果
func is_multi_target() -> bool:
	return target_type in [TargetType.MULTI, TargetType.ALL_ENEMY, TargetType.ALL_ALLY]
