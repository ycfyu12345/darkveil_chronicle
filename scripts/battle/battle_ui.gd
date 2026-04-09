extends Node2D

## 战斗UI灰盒占位符
## 白底黑字显示角色名、HP，按钮可点击

@onready var team_panel: VBoxContainer = $TeamPanel
@onready var enemy_panel: VBoxContainer = $EnemyPanel
@onready var card_hand: HBoxContainer = $CardHand
@onready var action_queue: VBoxContainer = $ActionQueue
@onready var command_panel: HBoxContainer = $CommandPanel
@onready var battle_log: RichTextLabel = $BattleLog

func _ready() -> void:
	print("[BattleUI] Placeholder UI ready")
	_create_command_buttons()

## 根据队伍数据更新UI（供 BattleSystem 调用）
func update_team_units(player_units: Array) -> void:
	team_panel.clear_children()
	for unit in player_units:
		if unit is CharacterInstance:
			var hp = unit.current_hp
			var max_hp = unit.get_max_hp()
			var name = unit.character_data.name
			var card = _create_unit_card(name, hp, max_hp)
			team_panel.add_child(card)

## 根据敌人数据更新UI（供 BattleSystem 调用）
func update_enemy_units(enemy_units: Array) -> void:
	enemy_panel.clear_children()
	for enemy in enemy_units:
		var data = enemy.get("data", null)
		if data:
			var hp = enemy.get("current_hp", 0)
			var max_hp = enemy.get("max_hp", 0)
			var name = data.name
			var card = _create_unit_card(name, hp, max_hp)
			enemy_panel.add_child(card)

## 创建单位卡片占位符
func _create_unit_card(name: String, current_hp: int, max_hp: int) -> Control:
	var panel = PanelContainer.new()
	panel.set_custom_minimum_size(Vector2(150, 80))

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var hp_label = Label.new()
	hp_label.text = str(current_hp) + " / " + str(max_hp) + " HP"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)

	var progress = ProgressBar.new()
	progress.max_value = max_hp
	progress.value = current_hp
	progress.set_custom_minimum_size(Vector2(130, 10))
	vbox.add_child(progress)

	return panel

## 创建命令按钮
func _create_command_buttons() -> void:
	command_panel.clear_children()

	var attack_btn = Button.new()
	attack_btn.text = "攻击"
	attack_btn.pressed.connect(_on_attack_pressed)
	command_panel.add_child(attack_btn)

	var skill_btn = Button.new()
	skill_btn.text = "技能"
	skill_btn.pressed.connect(_on_skill_pressed)
	command_panel.add_child(skill_btn)

	var item_btn = Button.new()
	item_btn.text = "道具"
	item_btn.pressed.connect(_on_item_pressed)
	command_panel.add_child(item_btn)

	var defend_btn = Button.new()
	defend_btn.text = "防御"
	defend_btn.pressed.connect(_on_defend_pressed)
	command_panel.add_child(defend_btn)

## 按钮回调
func _on_attack_pressed() -> void:
	print("[BattleUI] Attack button pressed")

func _on_skill_pressed() -> void:
	print("[BattleUI] Skill button pressed")

func _on_item_pressed() -> void:
	print("[BattleUI] Item button pressed")

func _on_defend_pressed() -> void:
	print("[BattleUI] Defend button pressed")

## 根据技能验证结果更新按钮状态
## skill_validation: Dictionary {skill_id: bool}
func update_skill_buttons(skill_validation: Dictionary) -> void:
	for skill_id in skill_validation:
		var is_valid = skill_validation[skill_id]
		_set_skill_button_state(skill_id, is_valid)

## 设置技能按钮状态
func _set_skill_button_state(skill_id: String, is_enabled: bool) -> void:
	# 遍历卡牌手牌，设置对应技能的按钮状态
	for card in card_hand.get_children():
		if card is Button and card.get_meta("skill_id", "") == skill_id:
			card.disabled = not is_enabled
			if not is_enabled:
				card.modulate = Color(0.5, 0.5, 0.5)  # 灰显

## 添加战斗日志
func add_log(message: String) -> void:
	if battle_log:
		battle_log.append_text(message + "\n")
