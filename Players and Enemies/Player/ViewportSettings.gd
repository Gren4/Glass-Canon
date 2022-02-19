extends Viewport

func _ready():
	self.size = OS.get_window_safe_area().size
