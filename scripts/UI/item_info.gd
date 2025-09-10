extends CanvasLayer

@onready var info_text: Label = $ItemBox/InfoText

func _ready() -> void:
	info_text.text = ""

func _on_item_panel_item_hovered(item_description: String) -> void:
	info_text.text = item_description
