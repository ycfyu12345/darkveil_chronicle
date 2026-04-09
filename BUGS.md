# Darkveil Chronicle - 问题记录

## 发现的问题

### [Bug-1] debug_manager.gd 满血函数实现错误

**文件**: `autoload/debug_manager.gd`
**行号**: 48
**严重程度**: 高
**状态**: ✓ 已修复

**修复内容**:
```gdscript
# 修复前
member.current_hp = member.character_data.base_stats.hp

# 修复后
member.current_hp = member.get_max_hp()
```

---

### [Bug-2] 技能 effects 数组为空

**文件**: `resources/skills/*.tres`, `scripts/battle/skill_card.gd`, `scripts/battle/battle_logic.gd`
**严重程度**: 高
**状态**: ✓ 已修复

**修复内容**:

1. **skill_card.gd** - 新增简化效果属性:
   ```gdscript
   @export var effect_type: int = 0          # Effect.EffectType
   @export var effect_base_value: int = 0    # 效果基础值
   @export var effect_multiplier: float = 1.0 # 效果倍率
   ```

2. **技能文件** - 更新效果数据:

   | 技能文件 | effect_type | effect_base_value | effect_multiplier |
   |---------|-------------|-------------------|------------------|
   | skill_attack.tres | 0 (DAMAGE) | 30 | 1.0 |
   | skill_heal.tres | 2 (HEAL) | 30 | 1.0 |
   | skill_ultimate_attack.tres | 0 (DAMAGE) | 60 | 1.5 |
   | skill_defend.tres | 1 (DAMAGE_BUFF) | 0 | 1.5 |

3. **battle_logic.gd** - `calculate_damage()` 支持 skill 参数:
   ```gdscript
   func calculate_damage(attacker, defender, multiplier: float = 1.0, skill: SkillCard = null) -> int:
       # 优先使用技能的效果基础值
       if skill != null and skill.effect_base_value > 0:
           base_damage = skill.effect_base_value
       ...
   ```

---

### [Warn-1] signal_manager.gd 信号未使用警告

**文件**: `autoload/signal_manager.gd`
**严重程度**: 低
**状态**: 已知/设计如此

**问题描述**:
以下信号被声明但从未显式使用:
- `battle_won`
- `battle_lost`
- `gold_changed`
- `building_interacted`

**说明**: 根据 T1.2 设计，这些信号供其他脚本连接使用。警告不影响功能，但说明没有脚本主动发射这些信号。

**实际使用情况**:
- `gold_changed`: 在 `game_manager.gd:add_gold()` 中被发射 ✓
- `building_interacted`: 在 `town_manager.gd:interact_with_building()` 中被发射 ✓
- `battle_won`: 在 `battle_system.gd:_handle_battle_over()` 中被发射 ✓
- `battle_lost`: 未找到发射位置 ✗

**建议**: 检查 `battle_lost` 信号是否应该在某处被发射。

---

## 验证状态总结

| Phase | 任务 | 状态 |
|-------|------|------|
| Phase 0 | T0.1-T0.3 | ✓ 通过 |
| Phase 1 | T1.1-T1.8 | ✓ 通过 (有警告) |
| Phase 2 | T2.1-T2.6 | ✓ 通过 |
| Phase 3 | T3.1-T3.5 | ✓ 通过 |
| Phase 4 | T4.1-T4.4 | ✓ 通过 |
| Phase 5 | T5.1-T5.3 | ✓ 通过 |
| Phase 6 | T6.1-T6.3 | ✓ 通过 |
| Phase 7 | T7.1-T7.3 | 待手动测试 |

**可运行**: 项目可正常启动，城镇场景加载正常。

---

## 待手动验证项目

由于 MCP 无法模拟用户输入，以下功能需要手动验证:

1. **F1 跳转战斗** - 按 F1 应进入战斗场景
2. **F2 满血** - 按 F2 应恢复队伍 HP ✓ 已修复
3. **F3 +1000金** - 按 F3 应增加金币
4. **医院交互** - 点击医院按钮应扣 50 金并治疗
5. **进入地牢** - 点击地牢入口应切换到地牢场景
6. **地牢前进** - 点击前进应遭遇怪物并进入战斗
7. **完整战斗流程** - 选择技能 → 确认 → 观看行动 → 结算

---

*文档创建时间: 2026-04-09*
*最后更新: 2026-04-09 - Bug-1, Bug-2 已修复*
