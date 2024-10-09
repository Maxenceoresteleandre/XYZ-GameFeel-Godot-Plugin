extends Node
class_name Shaker
## The shaker class is meant to be used for camera shakes, object shakes, etc.
##
## You may use one shaker for each individual object you want to shake, as trying 
## to trigger multiple shakes at the same time will fail.

enum ShakableTypes {Float, Vector2, Vector3}
const ZERO_VALUES : Dictionary = {
	ShakableTypes.Float : 0.0,
	ShakableTypes.Vector2 : Vector2.ZERO,
	ShakableTypes.Vector3 : Vector3.ZERO
}


## The object you want to shake
@export var object : Node
# The property path of the affected property
@export var property := "offset"
# The type of the property
@export var property_type : ShakableTypes = ShakableTypes.Vector2
@export var shake_trans := Tween.TRANS_SINE
@export var shake_ease := Tween.EASE_IN_OUT
@export var set_to_zero_after_shake := true

@onready var shake_timer : Timer = Timer.new()

var initial_value : Variant = Vector2.ZERO
var amplitude := 0
var priority := 0
var shaking := false
var frequency := 0.0

func _ready() -> void:
	shake_timer.autostart = false
	shake_timer.one_shot = true

func shake(duration_n := 0.2, frequency_n := 15, amplitude_n := 30, priority_n := 0) -> void:
	if shaking and priority_n < priority:
		return
	priority = priority_n
	amplitude = amplitude_n
	shaking = true
	if set_to_zero_after_shake:
		initial_value = Vector2.ZERO
	else:
		initial_value = object.get(property)
	frequency = 1/float(frequency_n)
	_new_shake()
	shake_timer.start(duration_n)
	await shake_timer.timeout
	shaking = false
	_reset()

func _new_shake() -> void:
	var rand := Vector2()
	rand.x = randf_range(-amplitude, amplitude)
	rand.y = randf_range(-amplitude, amplitude)
	await _tween_shake(rand).finished
	if shaking:
		_new_shake()

func _tween_shake(new_pos : Variant) -> Tween:
	var tween : Tween = create_tween().set_ease(shake_ease).set_trans(shake_trans)
	tween.tween_property(object, property, initial_value + new_pos, frequency)
	return tween

func _reset() -> void:
	var tween : Tween = create_tween().set_ease(shake_ease).set_trans(shake_trans)
	tween.tween_property(object, property, initial_value, frequency)
	priority = 0
