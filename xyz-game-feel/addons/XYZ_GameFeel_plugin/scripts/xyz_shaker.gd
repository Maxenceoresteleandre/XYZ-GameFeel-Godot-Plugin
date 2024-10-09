@tool
extends Node
class_name XYZ_Shaker
## The shaker class is meant to be used for camera shakes, object shakes, etc.[br][br]
## You may use one shaker for each individual object you want to shake, as trying 
## to trigger multiple shakes at the same time will fail.
##
## Class from the XYZ GameFeel Plugin.


## Emitted when object has finished shaking and can be called for a clean new shake.
@warning_ignore("unused_signal")
signal shake_finished


## Reset values if set_to_zero_after_shake is true.
const ZERO_VALUES : Dictionary = {
	TYPE_FLOAT : 0.0,
	TYPE_COLOR : Color.WHITE,
	TYPE_VECTOR2 : Vector2.ZERO,
	TYPE_VECTOR3 : Vector3.ZERO,
}

## The object you want to shake.
@export var object : Node
## The path of the affected property.
@export var property := "position"
## true: set the property value to a custom zero value after the shake.
## false: reset to the initial value after the shake.
@export var use_reset_value_after_shake := true
## The transition type used by the tween.
@export var shake_trans := Tween.TRANS_SINE
## The ease type used by the tween.
@export var shake_ease := Tween.EASE_IN_OUT

var initial_value : Variant
var amplitude := 0
var priority := 0
var shaking := false
var frequency := 0.0
var property_type : int
var final_value : Variant
var reset_value : Variant
var is_reset_value_custom := false

@onready var shake_timer : Timer = Timer.new()



func _ready() -> void:
	shake_timer.autostart = false
	shake_timer.one_shot = true


## Shake the object's property for duration_n, with jumps between -amplitude_n and 
## amplitude_n, at frequency_n. If another shake is happening, priority_n is used 
## to choose whether or not to override the previous shake with the new one.
func shake(duration_n := 0.2, frequency_n := 15, amplitude_n := 30, priority_n := 0) -> void:
	if shaking and priority_n < priority:
		return
	priority = priority_n
	amplitude = amplitude_n
	shaking = true
	initial_value = object.get(property)
	if _set_zero_value() != 0:
		return
	if use_reset_value_after_shake:
		final_value = reset_value
	else:
		final_value = initial_value
	frequency = 1/float(frequency_n)
	_new_shake()
	shake_timer.start(duration_n)
	await shake_timer.timeout
	shaking = false
	_reset()


## Set a custom reset value if use_reset_value_after_shake is true.[br]
## By default, reset_value will be 0.0, Vector2.ZERO, Vector3.ZERO or Color.WHITE,
## depending on the property type.
func custom_reset_value(val : Variant) -> void:
	reset_value = val
	is_reset_value_custom = true


func _set_zero_value() -> int:
	## check object validity
	if object == null or not is_instance_valid(object):
		if Engine.is_editor_hint():
			print_debug("XYZ_Shaker: selected object is null or not valid")
		return 1
	## check has property
	var property_val : Variant = object.get(property)
	if property_val == null:
		if Engine.is_editor_hint():
			print_debug("XYZ_Shaker: property doesn't exist on selected object")
		return 1
	property_type = typeof(property_val)
	if property_type in ZERO_VALUES.keys():
		if not is_reset_value_custom:
			reset_value = ZERO_VALUES[property_type]
	else:
		if Engine.is_editor_hint():
			print_debug("XYZ_Shaker: property type can't be shaken")
		return 1
	return 0

func _get_random_float_offset(f_amplitude : float) -> float:
	return randf_range(-f_amplitude, f_amplitude)


func _get_random_color_offset(f_amplitude : float, transparency : float) -> Color:
	return Color(
		randf_range(-f_amplitude, f_amplitude), 
		randf_range(-f_amplitude, f_amplitude), 
		randf_range(-f_amplitude, f_amplitude), 
		transparency
	)


func _get_random_vector2_offset(f_amplitude : float) -> Vector2:
	return Vector2(
		randf_range(-f_amplitude, f_amplitude),
		randf_range(-f_amplitude, f_amplitude)
	)


func _get_random_vector3_offset(f_amplitude : float) -> Vector3:
	return Vector3(
		randf_range(-f_amplitude, f_amplitude),
		randf_range(-f_amplitude, f_amplitude),
		randf_range(-f_amplitude, f_amplitude)
	)


func _new_shake() -> void:
	var offset_val : Variant
	match property_type:
		TYPE_FLOAT:
			offset_val = _get_random_float_offset(amplitude)
		TYPE_COLOR:
			@warning_ignore("unsafe_call_argument")
			offset_val = _get_random_color_offset(amplitude, initial_value.a)
		TYPE_VECTOR2:
			offset_val = _get_random_vector2_offset(amplitude)
		TYPE_VECTOR3:
			offset_val = _get_random_vector3_offset(amplitude)
	await _tween_shake(offset_val).finished
	if shaking:
		_new_shake()


func _tween_shake(offset_val : Variant) -> Tween:
	var tween : Tween = create_tween().set_ease(shake_ease).set_trans(shake_trans)
	tween.tween_property(object, property, initial_value + offset_val, frequency)
	return tween


func _reset() -> void:
	var tween : Tween = create_tween().set_ease(shake_ease).set_trans(shake_trans)
	tween.tween_property(object, property, final_value, frequency)
	priority = 0
	emit_signal("shake_finished")
