# Darkveil Chronicle - 任务分解

每个任务独立可执行、可验证。

---

## 任务ID命名规则

- **T{n}.{m}**: n = Phase 编号, m = 任务序号
- 例如: T1.3 = Phase 1 的第 3 个任务

---

## Phase 0: 项目初始化 (无依赖)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T0.1 | `project.godot` | 创建项目，锁定 1280x720，`stretch_mode = "canvas_items"`；在项目设置的 Input Map 中添加 `debug_battle` (F1), `debug_full_heal` (F2), `debug_gold` (F3) | - [x] Godot 编辑器能打开项目，无警告；F1-F3 在调试模式下有响应 |
| T0.2 | 目录结构 | 创建 `autoload/`, `scripts/`, `scenes/`, `resources/`, `assets/` 等目录 | - [x] 所有目录存在 |
| T0.3 | `assets/` | 创建占位美术资源：白底黑字 `placeholder_portrait.png` (128x128)，区分角色/怪物/建筑 | - [x] `.tres` 中的 `portrait_path` 可正常加载不报错 |

---

## Phase 1: 核心架构 (P0)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T1.1 | `autoload/game_manager.gd` | 游戏状态 `game_state`，场景切换 `change_scene()`，金币 `gold`，队伍 `party`，**`current_battle_setup` (战斗上下文，供 BattleSystem 拉取)** | - [x] `Engine.get_singleton("GameManager")` 可获取实例 |
| T1.2 | `autoload/signal_manager.gd` | 全局跨系统信号: `battle_won`, `battle_lost`, `gold_changed`, `building_interacted`; **注意**: `health_changed` 等高频、仅战斗 UI 关心的信号**放在 BattleSystem 节点上**，不由 SignalManager 转发 | - [x] 其他脚本可连接这些信号 |
| T1.3 | `autoload/debug_manager.gd` | F1=跳转战斗, F2=满血, F3=+1000金 | - [x] 调试模式下按 F1-F3 有响应 |
| T1.4 | `autoload/effects_manager.gd` | `screen_shake(intensity, duration)`, `show_damage_number(value, position, is_critical)` | - [x] 方法可被调用（可以是空实现） |
| T1.5 | `autoload/audio_manager.gd` | `play_sfx(sfx_name)`, `play_bgm(bgm_name)` | - [x] 方法可被调用（可以是空实现） |
| T1.6 | `resources/characters/character_data.gd` | `CharacterData` extends Resource: `id`, `name`, `portrait_path`, `rarity`, `base_stats`, `skill_ids` | - [x] 能在编辑器创建 `character_data_*.tres` |
| T1.7 | `scripts/character/character_instance.gd` | `CharacterInstance` class: `character_data`, `current_hp`, `experience`, `is_alive`, `current_slot_index`; **运行时状态单独维护，不修改 Resource 模板** | - [x] `CharacterInstance.new(character_data)` 可创建实例 |
| T1.8 | `resources/monsters/monster_data.gd` | `MonsterData` extends Resource: `id`, `name`, `position`, `base_stats`, `skill_ids`, `drop_gold`, `emergency_skill_id` (保命技能ID，数值策划可配置) | - [x] 能在编辑器创建怪物 `.tres` |

---

## Phase 2: 战斗数据 (P0, 依赖 T1.6, T1.7, T1.8)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T2.1 | `scripts/battle/effect.gd` | `EffectType` enum: `DAMAGE`, `DAMAGE_BUFF`, `HEAL`, `DEBUFF`; `Effect` class: `type`, `base_value`, `multiplier`, `condition` | - [x] 其他脚本可引用 `Effect` 类 |
| T2.2 | `scripts/battle/skill_card.gd` | `SkillCard` extends Resource: `id`, `name`, `icon_path`, `is_ultimate`, `max_uses`, `target_type`, `target_position`, `effects`, `skill_weights`; **注意**: `max_uses` 是模板值，**运行时 uses 在 BattleSystem 的 `runtime_skill_uses` Dictionary 中独立维护** | - [x] 能在编辑器创建 `skill_*.tres` |
| T2.3 | `scripts/battle/battle_logic.gd` | signals: `damage_dealt`, `character_died`, `battle_ended`; `calculate_damage()`, `apply_damage()`, `get_turn_order()` 含速度平局随机 | - [x] 单元测试: `calculate_damage(20, 10, 1.5)` 返回正数 |
| T2.4 | `scripts/battle/monster_ai.gd` | `choose_skill(monster, available_skills)`: 血量<30%优先保命，否则按权重随机 | - [x] 多次调用，低血量时保命技能选中率 >50% |
| T2.5 | `scripts/battle/position_system.gd` | `check_position_validity()` (判断技能对当前站位是否合法), `apply_death_and_fill()` (只修改 `current_slot_index`，不修改数组顺序), `rearrange_positions()` (UI 层根据 `current_slot_index` 更新显示) | - [x] 单元测试: 前排死亡后后排单位位置索引变化 |
| T2.6 | `scripts/battle/battle_logic.gd` | **防御公式常量定义**: `DEFENSE_REDUCTION_RATIO = 0.5`; `calculate_damage()` 使用常量计算 `final_damage = max(1, base_damage * multiplier - defender.defense * DEFENSE_REDUCTION_RATIO)` | - [x] 单元测试: `calculate_damage(20, 10, 1.5)` 返回正数 |

---

## Phase 3: 战斗状态机 (P0, 依赖 Phase 2)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T3.1 | `scripts/battle/battle_state_machine.gd` | `BattleState` enum: `INIT`, `PLAYER_INPUT`, `ACTION_QUEUE`, `EXECUTION`, `DEATH_CHECK`, `TURN_END`, `BATTLE_OVER`; **`DAMAGE_CALC 合并到 EXECUTION`**；`transition_to()`, `get_valid_transitions()` | - [x] `INIT→PLAYER_INPUT` 合法，`INIT→EXECUTION` 不合法 |
| T3.2 | `scripts/battle/battle_system.gd` | 持有 `BattleLogic`, `BattleStateMachine`, `MonsterAI`; 管理 `player_units`, `enemy_units`, `action_queue`, `runtime_skill_uses`; **数据获取**: `_ready()` 时主动从 `GameManager.current_battle_setup` 拉取队伍和怪物数据; EXECUTION 状态使用 `await` 等待动画，动画结束后计算伤害 | - [x] 控制台打印完整战斗流程日志 |
| T3.3 | `scenes/battle/battle_scene.tscn` | 节点: `BattleSystem`, `BattleUI` (TeamPanel, EnemyPanel, CardHand, ActionQueue, CommandPanel), `BattleLog`, `TurnManager` | - [x] 场景存在，节点结构正确 |
| T3.4 | `scenes/battle/` | 灰盒 UI 占位符: 白底黑字 `TextureRect` 显示角色名、HP，按钮可点击 | - [x] 能看到所有 UI 元素，布局不乱 |
| T3.5 | `scripts/battle/battle_system.gd` / UI 层 | **技能可用性验证**: 在 `PLAYER_INPUT` 状态时，遍历当前角色技能调用 `BattleLogic.check_position_validity()`，**UI 层根据结果禁用非法技能按钮**（灰显），从源头杜绝误触 | - [x] 选择技能时，非法技能按钮不可点击 |

---

## Phase 4: 城镇系统 (P0, 依赖 T1.1, T1.2)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T4.1 | `scripts/town/town_manager.gd` | `interact_with_building(building_type)`, 连接 `SignalManager.building_interacted` | - [x] `town_manager.interact_with_building("hospital")` 打印日志 |
| T4.2 | `scenes/town/town_scene.tscn` | 节点: `TownManager`, `TownMap` (Sprite2D), `BuildingList` (HospitalButton, QuestBoardButton, DungeonEntranceButton), `PlayerHUD` (GoldLabel) | - [x] 点击按钮有响应 |
| T4.3 | `scripts/town/town_manager.gd` | `hospital_interact()`: 扣金币、加血、打印 Log | - [x] 100 金币时点击医院，金币变 50，HP 回满 |
| T4.4 | `scripts/town/town_manager.gd` | `enter_dungeon()`: 切换到 `DungeonScene` | - [x] 点击地牢入口切换场景 |

---

## Phase 5: 地牢系统 (P1, 依赖 T3.x, T4.x)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T5.1 | `scripts/dungeon/dungeon_manager.gd` | `current_room_index`, `advance_room()`, `spawn_monsters(room_index)`; **怪物配置存储在 DungeonManager 内部，不跨场景传递** | - [x] `advance_room()` 后 `current_room_index` 增加 |
| T5.2 | `scenes/dungeon/dungeon_scene.tscn` | 节点: `DungeonManager`, `RoomView` (Sprite2D), `ExplorationUI` (ProgressLabel, AdvanceButton, RetreatButton) | - [x] 场景可加载 |
| T5.3 | `scripts/dungeon/dungeon_manager.gd` | `start_battle()`: **先设置 `GameManager.current_battle_setup`** (包含 monster_data 数组)，再调用 `change_scene("res://scenes/battle/battle_scene.tscn")` | - [x] 遇到怪物时能进入战斗场景，BattleScene 加载后正确显示怪物 |

---

## Phase 6: 数据配置 (P0, 依赖 T1.6, T1.8, T2.2)

| 任务ID | 文件 | 操作 | 验证 |
|--------|------|------|------|
| T6.1 | `resources/characters/` | 创建 3 个角色: `character_data_alice.tres` (输出: ATK=30, SPD=10), `character_data_lily.tres` (治疗: HP=80, SPD=8), `character_data_shana.tres` (坦克: HP=180, DEF=25, SPD=3) | - [x] `load()` 可加载 |
| T6.2 | `resources/monsters/` | 创建怪物: `monster_data_slime.tres` (HP=30, ATK=8, SPD=4), `monster_data_goblin.tres` (HP=50, ATK=12, SPD=6), `monster_data_boss.tres` (HP=200, ATK=20, SPD=3) | - [x] `load()` 可加载 |
| T6.3 | `resources/skills/` | 创建技能: 普通 `skill_attack.tres`, `skill_heal.tres` (uses=-1 每回合恢复); 大招 `skill_ultimate_attack.tres` (is_ultimate=true, uses=1) | - [x] `load()` 可加载 |

---

## Phase 7: 集成测试 (P0, 依赖 Phase 1-6)

| 任务ID | 操作 | 验证 |
|--------|------|------|
| T7.1 | 完整战斗流程: Debug F1 进入战斗 → 选择技能 → 确认 → 观看行动顺序 → 结算 → 结束 | 控制台打印完整战斗日志 |
| T7.2 | 城镇→地牢→战斗→返回: 城镇点击地牢入口 → 地牢前进 → 遭遇怪物 → 战斗 → 返回城镇 | 全流程可走通 |
| T7.3 | 数值平衡检查: Phase 3.4.5 检查点 | 3 输出能否击杀坦克? 不带治疗能否打过第一间? |

---

## 任务依赖图

```
Phase 0
└── T0.1, T0.2, T0.3 (可并行)

Phase 1 (依赖 Phase 0)
├── T1.1, T1.2, T1.3, T1.4, T1.5 (可并行)
└── T1.6, T1.7, T1.8 (可并行)

Phase 2 (依赖 Phase 1)
├── T2.1, T2.2 (可并行)
├── T2.3 ← T2.4, T2.5 (T2.4, T2.5 依赖 T2.3 的数据结构)
└── T2.6 (依赖 T2.3)

Phase 3 (依赖 Phase 2)
├── T3.1 ← T3.2 ← T3.3 ← T3.4 (顺序执行)
└── T3.5 (依赖 T3.2, T3.4, T2.5)

Phase 4 (依赖 Phase 1)
└── T4.1 ← T4.2 ← T4.3, T4.4 (T4.3 和 T4.4 可并行)

Phase 5 (依赖 Phase 3, 4)
└── T5.1 ← T5.2 ← T5.3 (顺序执行)

Phase 6 (依赖 Phase 1, 2)
└── T6.1, T6.2, T6.3 (可并行)

Phase 7 (依赖所有)
└── T7.1, T7.2, T7.3 (可并行验证)
```

---

## 验证总结

每个任务完成后，在 Godot 编辑器中验证:
1. 场景/脚本无语法错误
2. 预期功能可触发
3. 控制台有对应日志输出

**最终验证清单**:
- [ ] T7.1 完整战斗流程可走通
- [ ] T7.2 城镇→地牢→战斗→返回可走通
- [ ] T7.3 数值在合理范围内
