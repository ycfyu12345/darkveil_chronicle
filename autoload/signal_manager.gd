extends Node

## 全局跨系统信号（仅战斗无关的高频信号从此处发射）

signal battle_won(victory: bool)
signal battle_lost()
signal gold_changed(new_gold: int)
signal building_interacted(building_type: String)
