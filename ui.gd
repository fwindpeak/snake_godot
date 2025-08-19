extends CanvasLayer

func _ready():
	$GameOverPanel.visible = false
	$ScoreLabel.text = "Score: 0"
	$ScoreLabel.position = Vector2(10, 10)

func _on_RestartButton_pressed():
	get_tree().reload_current_scene()
