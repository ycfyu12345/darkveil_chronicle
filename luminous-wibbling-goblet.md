# Darkveil Chronicle (暗幕纪事) - 开发文档

**核心参考**: 《暗黑地牢》的战斗指令系统 + 《抽卡人生》的卡牌美术风格

---

## 项目结构 (Godot 4.x)

```
darkveil_chronicle/
├── assets/
│   ├── characters/       # 角色立绘/卡牌图
│   ├── buildings/        # 城镇建筑图片
│   ├── NPCs/             # NPC立绘
│   ├── UI/               # 卡片边框、按钮等
│   └── effects/          # 战斗特效
├── scenes/
│   ├── town/             # 城镇地图场景
│   ├── battle/           # 战斗场景
│   ├── dungeon/          # 地牢探索
│   └── ui/               # 菜单、卡组界面
├── scripts/
│   ├── town/             # 城镇系统
│   ├── battle/           # 战斗系统
│   ├── character/        # 角色数据/卡牌系统
│   └── dungeon/          # 地牢生成
├── resources/
│   ├── characters/       # CharacterData 资源
│   └── NPCs/             # NPCData 资源
└── autoload/             # 全局管理（GameManager等）
```

---

## Phase 1: 核心架构搭建

### 1.1 初始化 Godot 4.x 项目
- 创建 `project.godot` 项目文件
- **锁死基准分辨率**: `1280x720`，`stretch_mode = "canvas_items"`, `stretch_aspect = "keep"`
- 配置项目设置（窗口尺寸、渲染等）
- **在项目设置的 Input Map 中添加调试快捷键**: `debug_battle` (F1), `debug_full_heal` (F2), `debug_gold` (F3)

> **重要**: 基准分辨率必须尽早锁定，否则后期多分辨率适配会是噩梦
> **Input Map 注意**: DebugManager.gd 使用 `Input.is_action_just_pressed("debug_battle")`，这些按键需要在项目设置中提前配置，否则调试功能失效

### 1.2 全局管理系统
- **GameManager** (autoload): 游戏状态管理、场景切换
- **AudioManager** (autoload): 音效/BGM管理
- **EffectsManager** (autoload): 屏幕震动、浮动伤害数字、打击特效
- **SignalManager** (autoload): 全局信号总线，跨场景、跨层级事件通知
- **DebugManager** (autoload): 开发调试快捷功能

```gdscript
# DebugManager.gd - 开发阶段快捷功能
extends Node

func _input(event: InputEvent):
    if Input.is_action_just_pressed("debug_battle"):
        # F1: 跳转战斗场景并加载指定阵容
        get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
    if Input.is_action_just_pressed("debug_full_heal"):
        # F2: 全队满血满状态
        for char in GameManager.party:
            char.current_hp = char.character_data.base_stats.hp
```

> **重要**: 调试功能仅开发阶段使用，打包发布前必须移除或禁用

```gdscript
# SignalManager.gd - 全局信号总线
extends Node

# 战斗结束事件（跨系统）
signal battle_won()
signal battle_lost()

# 经济/城镇事件（跨系统）
signal gold_changed(new_amount: int)
signal building_interacted(building_type: String)

# 注意：以下信号**不应**放在 SignalManager 中：
# - health_changed: 高频信号，仅战斗 UI 关心，应定义在 BattleSystem 节点上
# - character_took_damage: 战斗内部信号，应定义在 BattleSystem 节点上
# - skill_selected: 战斗内部信号，应定义在 BattleSystem 节点上
#
# 避免 SignalManager 变成"上帝总线"反模式
# UI 层通过 $BattleSystem.health_changed.connect(...) 直接订阅
```

> **好处**: UI 层只需要监听跨系统信号，不需要去找具体的节点引用

### 1.3 角色数据系统
创建 `CharacterData` 资源类型（静态配置）:
```gdscript
- id: String
- name: String
- portrait_path: String (卡牌立绘路径)
- rarity: int (稀有度 1-3: 1=普通, 2=稀有, 3=史诗)
- base_stats: { hp, attack, defense, speed }
- skill_ids: Array[String] (技能ID列表)
# P2扩展: level, exp, exp_to_next_level, equipment_slots
```

### 1.4 角色实例数据 (CharacterInstance)
用于存储玩家角色的动态数据（区别于静态配置）:
```gdscript
class_name CharacterInstance
var character_data: CharacterData  # 引用静态配置
var current_hp: int
var experience: int = 0
var is_alive: bool = true
var current_slot_index: int  # 当前所在槽位索引（0-3: 前排左/前排右/后排左/后排右）
```

> **位置系统重要提示**: 不要通过修改数组物理顺序来补位！补位时只修改 `current_slot_index`，UI 层根据此值更新显示位置

---

## Phase 2: 卡牌展示系统

### 2.0 UI 布局规范 (必须遵守)

为保证多分辨率适配和后期维护，禁止在代码中写死 UI 的绝对坐标。

**布局容器优先级**:
1. `MarginContainer` - 控制屏幕边距
2. `HBoxContainer` / `VBoxContainer` - 水平/垂直排列
3. `GridContainer` - 网格布局（卡组展示）
4. `Control.anchors_preset` + `size_flags_*` - 锚点自适应

**禁止**:
```gdscript
# 禁止这样写
$Card.position = Vector2(100, 200)
$HealthBar.size = Vector2(150, 20)
```

**推荐**:
```gdscript
# 使用锚点和 Size Flags
$Card.anchors_preset = Control.PRESET_LEFT_TOP
$Card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
```

**UI 节点命名后缀规范**:
| 后缀 | 类型 | 示例 |
|------|------|------|
| `Button` | 按钮 | `ConfirmButton`, `CancelButton` |
| `Label` | 文本 | `HealthLabel`, `GoldLabel` |
| `Panel` | 面板容器 | `TeamPanel`, `CommandPanel` |
| `TextureRect` | 图片 | `PortraitRect`, `CardBackground` |
| `ProgressBar` | 进度条 | `HPBar`, `StressBar` |

### 2.1 角色卡牌场景
- **CharacterCard.tscn**: 单张卡牌
  - 尺寸比例: 2:3 (如 200x300)
  - 显示: 立绘、角色名、稀有度边框、属性图标
  - 动画: 悬浮时轻微放大+发光

### 2.2 卡组/收藏界面
- **CharacterList.tscn**: 展示玩家拥有的角色卡
- 网格布局显示所有卡牌
- 点击查看角色详情

---

## Phase 3: 暗黑地牢式战斗系统

### 3.1 战斗核心机制
参考《暗黑地牢》的指令式回合制:

**战斗流程**:
1. 敌方出现（地牢怪物）
2. 我方角色按速度排序显示行动顺序
3. 玩家从每个角色的技能卡中选择1张
4. 确认后，依次执行所有动作
5. 重复直到战斗结束

**关键特性**:
- **位置系统**: 前后排站位，不同技能有位置要求，死亡时后排自动补位
- **技能卡双轨机制**:
  - **大招（Ultimate）**: 整场战斗总次数限制，用完即空（如 1 次），需要规划收割时机
  - **普通技能**: 每回合选择一张使用，下回合自动恢复

> **卡牌机制说明**: 本游戏采用**固定技能栏（Skill Bar）**模式，而非卡组构建（Deck-building）。
> - 每个角色拥有 1 张大招 + 2-3 张普通技能
> - 大招有整场战斗使用次数限制（如 1-2 次），用完本场不再可用
> - 普通技能每回合选择一张执行，下回合自动刷新
> - **不涉及**抽牌堆（Draw Pile）、弃牌堆（Discard Pile）等机制
> - P2 阶段如需引入卡组构建，可在此基础上扩展

```gdscript
# 技能卡数据结构
SkillCard:
- id: String
- name: String
- icon_path: String
- is_ultimate: bool  # 是否为整场限制的大招
- max_uses: int     # 最大使用次数（模板值，Resource 字段）
- target_type: enum (单体/全体/自身)

> **AOE 技能警告**: 前期怪物只有 1-2 只，AOE 技能（打两排）总伤害通常比单体低，导致无人使用。确保前期（房间3-4）有足够多的怪物来体现 AOE 价值，或在数值上给予 AOE 适当加成
- target_position: enum (前排/后排/任意)
- effects: Array[Effect]

# 运行时技能状态
# 注意：技能卡是静态配置 Resource，max_uses 是模板值
# 实际运行时 uses 必须在 BattleSystem 中单独维护：
#   var runtime_skill_uses: Dictionary = {"skill_id": remaining_uses}
# 每次战斗开始时，根据 max_uses 初始化 runtime_skill_uses
```

### 3.2 位置系统规则

**死亡补位机制**:
- 当前排单位死亡时，后排单位自动填补前排空位
- 填补顺序：按原位置从左到右依次前移

```gdscript
# BattleLogic.gd 中新增
func check_position_validity(attacker: CharacterInstance, skill: SkillCard) -> bool:
    if skill.target_position == Position.FRONT:
        # 检查前排是否有有效目标
        return get_front_units().any(func(u): return u.is_alive)
    return true

func apply_death_and_fill(dead_unit: CharacterInstance):
    # 触发补位逻辑
    dead_unit.is_alive = false
    rearrange_positions()
```

**技能无效处理**: 如果技能找不到合法目标，**在 UI 层禁用该技能按钮**（灰显），从源头杜绝误触。具体做法：
- 在 `PLAYER_INPUT` 状态时，遍历当前角色技能，调用 `BattleLogic.check_position_validity()`
- UI 层根据返回结果设置技能按钮 `disabled = true`
- 玩家无法点击禁用的技能，避免"粪作"体验

### 3.3 怪物 AI 设计

垂直切片阶段怪物采用**简单权重 AI**，确保行为可控可测试：

```gdscript
class_name MonsterAI
var skill_weights: Dictionary  # { skill_id: weight }

func choose_skill(monster: CharacterInstance, available_skills: Array) -> SkillCard:
    # 血量低于30%时，直接使用 emergency_skill_id（配置在 MonsterData 中）
    if monster.current_hp < monster.character_data.base_stats.hp * 0.3:
        var monster_data = monster.character_data
        if monster_data.has("emergency_skill_id"):
            var emergency_id = monster_data.emergency_skill_id
            var emergency_skill = available_skills.find(func(s): return s.id == emergency_id)
            if emergency_skill != null:
                return available_skills[emergency_skill]

    # 否则按权重随机选择
    var total_weight = available_skills.reduce(func(sum, s): return sum + skill_weights.get(s.id, 1.0), 0.0)
    var roll = randf() * total_weight
    var current = 0.0
    for skill in available_skills:
        current += skill_weights.get(skill.id, 1.0)
        if roll <= current:
            return skill

    return available_skills[0]  # 默认返回第一个
```

> **注意**: P2 可扩展为行为树（Behavior Tree）实现更复杂 AI 逻辑
> **emergency_skill_id**: 数值策划可直接在 MonsterData 中配置，无需 AI 代码遍历判断"是不是治疗"

### 3.1.1 战斗状态机 (BattleStateMachine)

为避免"面条代码"，战斗流程使用明确的状态机管理：

```gdscript
enum BattleState {
    INIT,           # 战斗初始化
    PLAYER_INPUT,   # 玩家选择技能
    ACTION_QUEUE,   # 行动排队确认
    EXECUTION,      # 行动执行/动画播放 + 伤害结算（合并）
    DEATH_CHECK,    # 死亡判定（整轮行动队列执行完后统一判定）
    TURN_END,       # 回合结算
    BATTLE_OVER     # 战斗结束
}
```

**状态流转**:
```
INIT → PLAYER_INPUT → ACTION_QUEUE → EXECUTION → DEATH_CHECK
                                                         ↓ (如有角色死亡)
                                                    BATTLE_OVER
                                                         ↓ (无人死亡)
                                                     TURN_END → PLAYER_INPUT
```

> **时序优化**: DAMAGE_CALC 合并到 EXECUTION 末尾，每个行动执行完立即结算伤害。整轮行动队列跑完后，统一进入 DEATH_CHECK 做全局死亡补位判定

**动画异步处理机制**:
- `EXECUTION` 状态使用 `await animation_player.animation_finished` 等待动画播完
- 如果目标在动画播放前已死亡，跳过该动画并标记 `animation_cancelled = true`
- 防止"伤害数字先出来，刀光后出来"的 Bug

```gdscript
# EXECUTION 状态示例
var animation_cancelled = false
for action in action_queue:
    if action.target.is_alive == false:
        animation_cancelled = true
        continue  # 跳过已死亡目标
    await play_skill_animation(action)  # 等待 AnimationPlayer
    battle_logic.apply_damage(action.target, action.damage)
    SignalManager.character_took_damage.emit(...)

### 3.1.2 数据与表现分离 (BattleLogic)

伤害计算逻辑与 UI 完全分离：

```gdscript
# BattleLogic.gd - 纯数据类，不涉及任何 Node/UI 引用
class_name BattleLogic
signal damage_dealt(damage: int, target_id: String, is_critical: bool)
signal character_died(character_id: String)
signal battle_ended(victory: bool)

func calculate_damage(attacker: CharacterInstance, defender: CharacterInstance, skill: SkillCard) -> int:
    # 伤害 = 基础伤害 × (1 + 攻击/防御修正) × 技能倍率
    ...

func apply_damage(target: CharacterInstance, damage: int):
    target.current_hp -= damage
    if target.current_hp <= 0:
        target.is_alive = false
        emit_signal("character_died", target.character_data.id)
```

### 3.2 战斗场景结构
```
BattleScene
├── BattleSystem
│   └── (战斗逻辑、状态机、AI)
├── BattleUI
│   ├── TeamPanel (左侧：我方角色卡+血条)
│   ├── EnemyPanel (右侧：敌方怪物)
│   ├── CardHand (下方：当前选卡手牌)
│   ├── ActionQueue (中间：行动顺序预览)
│   └── CommandPanel (确认/取消按钮)
├── BattleLog (战斗信息日志)
└── TurnManager (回合/顺序管理)
```

> **数据获取机制**: BattleSystem 在 `_ready()` 时主动从 `GameManager.current_battle_setup` 拉取玩家队伍和怪物数据。不要通过 `change_scene_to_file` 传参！

### 3.3 技能卡数据结构
```gdscript
enum EffectType {
    DAMAGE,
    DAMAGE_BUFF,
    HEAL,
    DEBUFF
}

class Effect:
    var type: EffectType
    var base_value: int
    var multiplier: float = 1.0
    var condition: String = ""  # 如 "bleeding" - P2扩展用

SkillCard:
- id: String
- name: String
- icon_path: String
- target_type: enum (单体/全体/自身)
- target_position: enum (前排/后排/任意)
- effects: Array[Effect]
- uses: int (本场战斗可用次数)
```

### 3.4 数值设计框架

#### 3.4.1 角色基础属性

| 属性 | 说明 | 典型范围 |
|------|------|----------|
| `hp` | 生命值 | 50 - 200 |
| `attack` | 攻击力 | 10 - 50 |
| `defense` | 防御力 | 0 - 30 |
| `speed` | 速度（决定行动顺序） | 1 - 20 |

#### 3.4.2 职业定位参考值

| 职业 | HP | ATK | DEF | SPD | 特点 |
|------|-----|-----|-----|-----|------|
| **坦克** | 150-200 | 8-12 | 20-30 | 2-5 | 高血量高防御，低速 |
| **输出** | 80-100 | 25-40 | 5-10 | 8-12 | 高攻击，中等血量 |
| **治疗** | 70-90 | 8-15 | 5-10 | 6-10 | 辅助，中等属性 |
| **刺客** | 60-80 | 30-50 | 3-7 | 15-20 | 最高攻击，最低血防，极速 |

#### 3.4.3 怪物强度分级 (地牢难度梯度)

| 难度 | 怪物 HP | 怪物 ATK | 怪物 DEF | 示例怪物 |
|------|---------|----------|----------|----------|
| **简单 (房间1-2)** | 20-40 | 5-10 | 0-5 | 史莱姆、蝙蝠 |
| **中等 (房间3-4)** | 40-80 | 10-20 | 5-15 | 哥布林、骷髅兵 |
| **Boss** | 150-300 | 15-30 | 10-25 | 骷髅王、巨魔 |

```gdscript
# 怪物数据结构
MonsterData:
- id: String
- name: String
- position: enum (front / back)  # 前排/后排
- base_stats: { hp, attack, defense, speed }
- skill_ids: Array[String]
- drop_gold: int (掉落金币范围)
- emergency_skill_id: String  # 保命技能ID（数值策划可配置，血量<30%时优先使用）
```

#### 3.4.4 战斗公式

**伤害计算**:
```gdscript
const DEFENSE_REDUCTION_RATIO: float = 0.5  # 防御力减伤比例

func calculate_damage(attacker_atk: int, defender_def: int, skill_multiplier: float) -> int:
    var base_damage = attacker_atk * skill_multiplier
    var reduction = defender_def * DEFENSE_REDUCTION_RATIO  # 防御力取一半作为减伤
    var final_damage = max(1, base_damage - reduction)  # 最低保底1点伤害
    return final_damage
```

> **减法公式警告**: 当前使用 `base - def × 0.5` 减法公式。特点是**前期防御强，后期防御弱**（怪攻击100，你30防减15，跟没防一样）。P2 数值膨胀后需改为除法公式：`伤害 = 攻击 / (1 + 防御/常数)`
> **常量定义**: 防御公式相关常量必须在 BattleLogic.gd 顶部用 const 明确定义，便于后期调整

**暴击机制**:
```gdscript
const CRITICAL_CHANCE: float = 0.1   # 10% 暴击率
const CRITICAL_MULTIPLIER: float = 1.5  # 暴击伤害 ×1.5

var is_critical = randf() < CRITICAL_CHANCE
var damage = calculate_damage(atk, def, multiplier)
if is_critical:
    damage *= CRITICAL_MULTIPLIER
```

**行动顺序**:
```gdscript
func get_turn_order(units: Array) -> Array:
    # 所有单位按 speed 降序排列
    # 速度相同时随机打破平局
    units.sort_custom(func(a, b):
        if a.speed == b.speed:
            return randi() % 2 == 0  # 50% 几率
        return a.speed > b.speed
    )
    return units
```

#### 3.4.5 数值平衡检查点

在开发过程中使用以下检查点验证数值合理性：

| 检查项 | 预期结果 |
|--------|----------|
| **输出 vs 坦克** | 3输出能否在坦克死前击杀？ |
| **治疗必要性** | 不带治疗是否能打过第一间？ |
| **防御收益** | 30防御 vs 0防御，实际减伤多少？ |
| **速度差异** | 速20 vs 速1，一回合多几次行动？ |

**简单平衡表**:
| 玩家总输出/回合 | 怪物总HP | 预计回合数 |
|----------------|----------|------------|
| 30 | 30 (1只怪) | 1-2回合 |
| 60 | 60 (2只怪) | 2-3回合 |
| 90 | 120 (Boss) | 4-5回合 |

---

## Phase 4: 城镇地图系统

### 4.1 城镇场景结构
```
TownScene
├── TownMap (背景地图)
│   └── BuildingNodes (可点击的建筑节点)
│       ├── Hospital (医院 - 治疗NPC)
│       ├── QuestBoard (任务板 - 领取任务NPC)
│       ├── Shop (商店 - 购买道具NPC)
│       ├── Barracks (兵营 - 编队NPC)
│       └── DungeonEntrance (地牢入口 - 开始探险NPC)
├── PlayerHUD
│   ├── GoldDisplay (金币显示)
│   └── PartyPanel (当前队伍)
├── InteractionPanel (与NPC对话/交互面板)
└── TownNPCs
    └── [NPCData] (每个建筑的NPC数据)
```

### 4.2 建筑系统
- **建筑节点**: 点击可交互的建筑Sprite/Button
- **交互触发**: 点击 → 弹出NPC对话/功能面板
- **建筑类型** (垂直切片，**功能占位即可**):
  | 建筑 | NPC功能 |
  |------|---------|
  | 医院 | 点击扣金币，全队满血（打印 Log，无需复杂 UI） |
  | 任务板 | 选择关卡（简单按钮列表） |
  | 商店 | 暂不实现 |
  | 兵营 | 暂不实现 |
  | 地牢入口 | 开始探险（进入 DungeonScene） |

> **重要**: 垂直切片的本质是验证核心战斗好不好玩。城镇只做"功能性占位"，**不要**在城镇的 NPC 对话、购买 UI 上花精力！

### 4.3 NPC数据结构
```gdscript
NPCData:
- id: String
- name: String
- building_type: enum (hospital/quest/shop/barracks/dungeon)
- portrait_path: String (NPC立绘)
- dialogue_lines: Array[String] (对话文本)
- function_data: Dictionary (功能相关数据)
```

### 4.4 城镇到地牢的流程
```
TownScene → 选择地牢入口 → DungeonScene → 战斗 → 结算 → 返回TownScene
```

---

## Phase 5: 地牢探索系统 (简化版)

### 5.1 地牢关卡
垂直切片只需1个地牢关卡:
- 3-4个房间
- 每房间1波敌人
- 最终Boss

### 5.2 地牢场景
```
DungeonScene
├── DungeonManager
│   └── (房间数据、怪物生成配置)
├── RoomView (当前房间画面)
├── ExplorationUI
│   ├── ProgressIndicator (房间进度)
│   └── EventPanel (交互按钮：前进/撤退/搜索)
├── MonsterPreview (遭遇怪物预览)
└── TransitionEffect (房间切换过渡)
```

> **跨场景数据传递**: DungeonManager 在 `start_battle()` 时，先设置 `GameManager.current_battle_setup = {monsters: [...]}`, 再调用 `change_scene_to_file("res://scenes/battle/battle_scene.tscn")`。BattleScene 加载后从 GameManager 拉取数据。

---

## Phase 5: 美术资源准备

### 5.1 垂直切片期间使用占位图
- `placeholder_portrait.png`: 角色立绘占位 (128x128，白底黑字，区分角色/怪物)
- `placeholder_avatar.png`: 小头像占位 (64x64)
- `icon.svg`: 通用图标

> **重要**: `.tres` 资源文件中的 `portrait_path` 必须指向有效图片路径。Resource 加载失败是**致命错误**，会导致项目崩溃。占位图确保 `load()` 不报错。

> **灰盒测试原则**: Phase 1-3 开发阶段，所有 UI 均为"白底黑字占位符"。先跑通 `BattleStateMachine`，能在控制台打印正确伤害数字，再去做发光、悬浮动画等表现。**切忌在机制未跑通前去调 UI 特效！**

### 5.2 卡牌边框
- 使用Godot的9-patch或shader实现稀有度边框
- Rarity 1-3 对应: 白(普通)/蓝(稀有)/紫(史诗)边框

---

## Phase 6: 完整战斗流程实现

### 示例：一场完整战斗
1. 进入地牢第1房 → 遇到2只史莱姆
2. 我方3个角色：爱丽丝(输出)、莉莉(治疗)、莎娜(坦克)
3. 每个角色有3张技能卡
4. 玩家依次为3个角色选择技能
5. 确认后显示行动顺序：爱丽丝(速5)→史莱姆A(速4)→莉莉(速3)→史莱姆B(速2)→莎娜(速1)
6. 播放技能动画、计算伤害
7. 结算：击杀2只史莱姆，战斗结束
   - (掉落奖励系统 P2 后续扩展)

---

## 关键文件清单

| 文件 | 用途 | 优先级 |
|------|------|--------|
| `project.godot` | Godot项目配置（锁定基准分辨率 1280x720，Input Map 配置） | P0 |
| `autoload/game_manager.gd` | 全局状态管理，含 `current_battle_setup` 供 BattleSystem 拉取 | P0 |
| `autoload/debug_manager.gd` | **新增**：开发调试快捷功能 | P0 |
| `autoload/signal_manager.gd` | **新增**：全局信号总线（仅跨系统信号） | P0 |
| `autoload/effects_manager.gd` | Game Feel 管理 | P0 |
| `resources/characters/character_data.gd` | 角色数据资源（静态） | P0 |
| `scripts/character/character_instance.gd` | 角色实例数据（动态），含 `current_slot_index` | P0 |
| `resources/npcs/npc_data.gd` | NPC数据资源 | P0 |
| `scripts/battle/battle_state_machine.gd` | **新增**：战斗状态机（含简化后的状态流转） | P0 |
| `scripts/battle/battle_logic.gd` | **新增**：纯数据伤害计算，含防御公式常量 | P0 |
| `scripts/battle/monster_ai.gd` | **新增**：怪物 AI，使用 `emergency_skill_id` | P0 |
| `scripts/battle/battle_system.gd` | 战斗核心逻辑（重构），含 `runtime_skill_uses` | P0 |
| `scripts/character/character_card.gd` | 卡牌显示控制 | P0 |
| `scripts/town/town_manager.gd` | 城镇管理（建筑/NPC交互） | P0 |
| `scenes/town/town_scene.tscn` | 城镇地图场景（功能占位） | P0 |
| `scenes/battle/battle_scene.tscn` | 战斗场景（BattleSystem 主动从 GameManager 拉取数据） | P0 |
| `scenes/dungeon/dungeon_scene.tscn` | 地牢探索（DungeonManager 设置 battle_setup 后切换） | P1 |
| `scripts/editor/tres_generator.gd` | 数据管道工具 | P1 |

---

## 验证方式

1. **启动测试**: Godot编辑器内运行 `town_scene.tscn`
2. **城镇验证**:
   - [ ] 城镇地图显示所有建筑
   - [ ] 点击建筑弹出对应NPC交互面板
   - [ ] 医院可以治疗角色
   - [ ] 地牢入口可以进入地牢
3. **战斗验证**:
   - [ ] 角色卡牌正常显示（立绘、属性）
   - [ ] 战斗开始后显示技能卡手牌
   - [ ] 可以选择技能并确认行动
   - [ ] **战斗状态机正确流转**：`PLAYER_INPUT` → `EXECUTION` → `DEATH_CHECK` → `TURN_END`
   - [ ] **数据/表现分离验证**：UI 层不包含任何伤害计算代码（伤害计算通过 `BattleLogic` + Signal 触发）
   - [ ] **动画异步处理验证**：动画播放完毕后才进行伤害结算
   - [ ] **怪物 AI 验证**：怪物能按权重随机选择技能（血量低时优先使用 emergency_skill_id）
   - [ ] **死亡补位验证**：前排死亡后，后排单位 `current_slot_index` 更新，UI 层根据索引重新排列
   - [ ] **速度平局验证**：速度相同时随机决定先后
   - [ ] **技能按钮禁用验证**：非法技能（如目标后排为空时的大招）在 UI 层灰显，不可点击
   - [ ] 技能正确施加到目标
   - [ ] 战斗结束后显示结果
4. **地牢验证**:
   - [ ] 可以进入地牢并切换房间
   - [ ] 遭遇怪物并进入战斗

**P2功能暂不验证**: 角色升级、道具系统、掉落奖励、压力系统

---

---

## 游戏主流程

```
MainMenu
    ↓
TownScene (城镇)
    ├── 医院 → 治疗角色 (消耗金币)
    ├── 任务板 → 领取任务
    ├── 商店 → 购买道具
    ├── 兵营 → 编队调整
    └── 地牢入口 → DungeonScene
                    ↓
               BattleScene (战斗)
                    ↓
               战斗结算 → 返回TownScene
```

---

## 后续扩展 (非本切片范围 | P2优先级)

- 压力系统 (Stress) - 折磨/美德判定、不受控随机行为
- 角色升级系统 (升级后属性提升，解锁新技能)
- 道具系统 (消耗品：药水、护盾卷轴等)
- 掉落奖励系统 (击败怪物获得金币/道具)
- 抽卡系统 (gacha_system.gd)
- 多个地牢关卡
- 完整存档系统
- 声音/特效完善

---

## 附录: 命名规范 (Naming Conventions)

### 代码命名
| 类型 | 规范 | 示例 |
|------|------|------|
| 节点与类名 | PascalCase | `BattleManager`, `CharacterCard` |
| 变量与函数 | snake_case | `current_hp`, `calculate_damage()` |
| 枚举值 | SCREAMING_SNAKE_CASE | `BattleState.PLAYER_INPUT` |
| 常量 | SCREAMING_SNAKE_CASE | `MAX_TEAM_SIZE = 4` |
| 信号名 | snake_case | `character_took_damage` |
| 私有变量 | snake_case + 前置下划线 | `_internal_state` |

### 资源文件命名
- 统一使用**小写 + 下划线**
- 格式: `{类型}_{名称}.{扩展名}`
- 示例:
  - `character_data_alice.tres`
  - `npc_data_hospital.tres`
  - `skill_attack_basic.tres`
  - `portrait_alice.png`

### 场景节点命名
| 类型 | 后缀 | 示例 |
|------|------|------|
| 按钮 | `Button` | `ConfirmButton` |
| 标签 | `Label` | `HealthLabel` |
| 面板 | `Panel` | `TeamPanel` |
| 进度条 | `Bar` | `HPBar` |
| 容器 | `Container` | `CardContainer` |
| 列表 | `List` | `BuildingList` |

### 目录结构命名
- 目录名: **小写 + 下划线**
- 示例: `battle_system/`, `character_data/`, `ui_components/`
