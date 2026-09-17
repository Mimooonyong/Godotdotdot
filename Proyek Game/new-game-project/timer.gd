extends RichTextLabel

var elapsed_time: float = 0.0

func _process(delta: float) -> void:
	elapsed_time += delta
	update_display()

func update_display() -> void:
	var minutes: int = int(elapsed_time) / 60
	var seconds: int = int(elapsed_time) % 60
	text = "%02d:%02d" % [minutes, seconds]
