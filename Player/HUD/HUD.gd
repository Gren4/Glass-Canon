extends Control

var weapon_ui
var health_ui
var display_ui
var slot_ui
var loading_screen

func _enter_tree():
	loading_screen = $LoadingScreen
	weapon_ui = $Background/WeaponUI
	health_ui = $Background/HealthUI
	display_ui = $Background/Weapon/TextureRect
	slot_ui = $Background/Weapon/WeaponSlot
	
func _ready():
	$LoadingScreen.visible = true
	$Background.visible = false
	$Crosshair.visible = false
	$InteractionPrompt.visible = false

func hide_loading_screen():
	$LoadingScreen.visible = false
	$Background.visible = true
	hide_interaction_promt()

func update_weapon_ui(weapon_data, weapon_slot):
	slot_ui.text = weapon_slot
	if weapon_data["Name"] == "Unarmed":
		weapon_ui.text = weapon_data["Name"]
		return
	weapon_ui.text = weapon_data["Name"] + ":" + weapon_data["Ammo"] + "/" + weapon_data["ExtraAmmo"]

func show_interaction_promt(description = "Interact"):
	$InteractionPrompt.visible = true
	$InteractionPrompt/Description.text = description
	$Crosshair.visible = false

func hide_interaction_promt():
	$InteractionPrompt.visible = false
	$Crosshair.visible = true
