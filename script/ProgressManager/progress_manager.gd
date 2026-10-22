
extends Node

const SAVE_PATH := "user://mathventure_progress.cfg"
const TOTAL_LEVELS := 4

var highest_unlocked_level: int = 1
var completed_levels: Array[int] = []
var level_stars: Dictionary = {}
var level_scores: Dictionary = {}


func _ready() -> void:
	load_progress()


func complete_level(
	level: int,
	stars: int,
	score: int = 0
) -> void:
	if level < 1 or level > TOTAL_LEVELS:
		return

	if not completed_levels.has(level):
		completed_levels.append(level)

	# Simpan hasil terbaik untuk setiap level.
	level_stars[level] = maxi(
		int(level_stars.get(level, 0)),
		clampi(stars, 0, 3)
	)

	level_scores[level] = maxi(
		int(level_scores.get(level, 0)),
		maxi(score, 0)
	)

	# Buka level berikutnya setelah level selesai.
	if level < TOTAL_LEVELS:
		highest_unlocked_level = maxi(
			highest_unlocked_level,
			level + 1
		)

	save_progress()


func get_total_stars() -> int:
	var total := 0

	for level in level_stars:
		total += int(level_stars[level])

	return total


func get_total_score() -> int:
	var total := 0

	for level in level_scores:
		total += int(level_scores[level])

	return total


func save_progress() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"progress", "highest_unlocked_level",
		highest_unlocked_level
	)
	config.set_value(
		"progress", "completed_levels",
		completed_levels
	)
	config.set_value("progress", "level_stars", level_stars)
	config.set_value("progress", "level_scores", level_scores)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_error("Gagal menyimpan progres MathVenture.")


func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error != OK:
		return

	highest_unlocked_level = clampi(
		int(config.get_value(
			"progress", "highest_unlocked_level", 1
		)),
		1, TOTAL_LEVELS
	)

	completed_levels = config.get_value(
		"progress", "completed_levels", []
	)

	level_stars = config.get_value(
		"progress", "level_stars", {}
	)

	level_scores = config.get_value(
		"progress", "level_scores", {}
	)
