extends Control

const BODY_REGIONS = [Rect2(0, 50, 268, 398), Rect2(0, 76, 280, 444), Rect2(0, 54, 372, 472)]
const EYE_REGIONS = [Rect2(2, 2, 77, 43), Rect2(2, 2, 76, 36), Rect2(2, 2, 75, 42)]
const EYE_OFFSETS = [Vector2(2.5, -105.5), Vector2(1, -121), Vector2(-7, -144)]

func ShowItem(item: Item) -> void:
	var stage = Daughterstatus.age_stage
	var paths = Globaljson.clothes_path[Daughterstatus.age_stage_names[stage]]
	if not paths.has(item.name):
		hide()
		return
	var texture = load(paths[item.name])
	var body_texture = AtlasTexture.new()
	body_texture.atlas = texture
	body_texture.region = BODY_REGIONS[stage]
	$Body.texture = body_texture
	var ratio = minf(302.0 / BODY_REGIONS[stage].size.x, 410.0 / BODY_REGIONS[stage].size.y)
	$Body.scale = Vector2.ONE * ratio
	var eye_texture = AtlasTexture.new()
	eye_texture.atlas = texture
	eye_texture.region = EYE_REGIONS[stage]
	$Eyes.texture = eye_texture
	$Eyes.scale = Vector2.ONE * ratio
	$Eyes.position = $Body.position + EYE_OFFSETS[stage] * ratio
	$Eyes.visible = item.name != "结婚礼服"
	show()
