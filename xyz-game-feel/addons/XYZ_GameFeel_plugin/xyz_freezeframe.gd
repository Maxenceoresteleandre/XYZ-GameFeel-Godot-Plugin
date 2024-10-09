extends Node
class_name XYZ_FreezeFrame


signal freeze_frame_ended


var default_time_scale := Engine.time_scale
var remaining_freeze_frame := 0.0
var in_freeze_frame := false


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


func slow_motion(time_scale : float, duration : float) -> void:
	if in_freeze_frame:
		await self.freeze_frame_ended
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = default_time_scale


func set_default_time_scale(time_scale : float) -> void:
	Engine.time_scale = time_scale
	default_time_scale = time_scale
