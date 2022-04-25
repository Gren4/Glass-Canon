extends Control

var weapon_ui
var health_ui
var display_ui
var slot_ui
var loading_screen
var hit_confirm
var heat_progress
var health_state
var damage

onready var indicator = preload("res://Players and Enemies/Player/HUD/Indicator.tscn")

func _enter_tree():
	loading_screen = $LoadingScreen
	weapon_ui = $Background/WeaponUI
	health_ui = $Background/HealthUI
	display_ui = $Background/Weapon/TextureRect
	slot_ui = $Background/Weapon/WeaponSlot
	hit_confirm = $Crosshair/TextureRect
	heat_progress = $Crosshair/TextureProgress
	health_state = $HealtState
	damage = $HealtState/Damage
	
func _ready():
	$LoadingScreen.visible = true
	$Background.visible = false
	$Crosshair.visible = false
	$InteractionPrompt.visible = false
	
func _process(delta):
	hit_confirm.visible = false

func hide_loading_screen():
	$LoadingScreen.visible = false
	#$Background.visible = true
	hide_interaction_promt()
	
func update_health(hp):
	#health_ui.text = "Health: " + String(hp)
	health_state.self_modulate.a = (0.25*(100-hp))/100
	damage.self_modulate.a = (100.0-hp)/100.0
	

func show_indicator(degree : float):
	var new = indicator.instance()
	new.rect_rotation = degree
	self.add_child(new)

func update_weapon_ui(weapon_data, weapon_slot):
#	slot_ui.text = weapon_slot
	if weapon_data["Name"] == "Unarmed":
#		weapon_ui.text = weapon_data["Name"]
		return
#	weapon_ui.text = weapon_data["Name"] + ":" + weapon_data["Ammo"]# + "/" + weapon_data["ExtraAmmo"]
	heat_progress.value = weapon_data["Ammo"]
	heat_progress.tint_progress.a = (20.0 + (0.75 * weapon_data["Ammo"]))/100

func show_interaction_promt(description = "Interact"):
	$InteractionPrompt.visible = true
	$InteractionPrompt/Description.text = description
	$InteractionPrompt/Key.text = OS.get_scancode_string(InputMap.get_action_list("interact")[0].scancode)
	$Crosshair.visible = false

func hide_interaction_promt():
	$InteractionPrompt.visible = false
	$Crosshair.visible = true
