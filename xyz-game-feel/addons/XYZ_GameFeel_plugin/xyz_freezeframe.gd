extends Node
class_name XYZ_FreezeFrame
## The freeze frame class manipulates time itself using the Engine.time_scale property.[br][br]
## Use it for short freeze frames, or slow motion effects. 
## Instantiate only one object of this class, as multiple objects might conflict
## with each other.
##
## Class from the XYZ GameFeel Plugin.

## When the freeze frame and potential queued freeze frames have been completed.
signal freeze_frame_ended

var remaining_freeze_frame := 0.0
var in_freeze_frame := false

## The default engine timescale
@onready var default_time_scale := Engine.time_scale

## Freeze the game for the duration
func freeze_frame(duration : float = 0.015) -> void:
	if in_freeze_frame:
		remaining_freeze_frame += duration
		return
	in_freeze_frame = true
	Engine.time_scale = 0.0
	while in_freeze_frame:
		await get_tree().create_timer(duration, true, false, true).timeout
		if remaining_freeze_frame > 0.0:
			duration = remaining_freeze_frame
			remaining_freeze_frame = 0.0
		else:
			in_freeze_frame = false
	Engine.time_scale = default_time_scale
	emit_signal("freeze_frame_ended")


## Set the game to the desired time_scale for the duration
func slow_motion(time_scale : float, duration : float) -> void:
	if in_freeze_frame:
		await self.freeze_frame_ended
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = default_time_scale


## Change the desired default time scale.
## Default time scale affects the behaviors of the freeze_frame and slow_motion methods.
func set_default_time_scale(time_scale : float) -> void:
	Engine.time_scale = time_scale
	default_time_scale = time_scale
