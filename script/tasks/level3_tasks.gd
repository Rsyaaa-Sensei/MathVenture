extends Node

const TASK_TYPE_DIRECTION = "direction"
const TASK_TYPE_TALK = "talk"
const TASK_TYPE_FIND = "find"

@export var tasks: Array = [
	{"type": TASK_TYPE_DIRECTION, "description": "Arah ke veranda rumah", "hint": "Cari tangga kayu yang didekati tangga sisi kiri, veranda panjang dengan mat woven purple di atasnya", "completed": false},
	{"type": TASK_TYPE_TALK, "description": "Bicarai dengan Tempong", "hint": "Tempong berdiri di kolong rumah (di bawah), dikenakan sarung tradisional dan sarang alang-alang", "completed": false},
	{"type": TASK_TYPE_FIND, "description": "Cari kunci rahasia", "hint": "Kunci tersembunyi di antara keranjang anyaman di pojok kanan dalam rumah, di rak benda bersama keramik", "completed": false}
]
var completed_tasks: Array = []
var current_task_index: int = 0

func _ready() -> void:
	completed_tasks = []
	current_task_index = 0
	load_completed_tasks()
	start_next_task()

func load_completed_tasks() -> void:
	var config := ConfigFile.new()
	var error := config.load("user://level3_tasks.cfg")
	
	if error != OK:
		return
	
	completed_tasks = config.get_value("tasks", "completed", [])
	current_task_index = config.get_value("tasks", "current_index", 0)

func save_completed_tasks() -> void:
	var config := ConfigFile.new()
	config.set_value("tasks", "completed", completed_tasks)
	config.set_value("tasks", "current_index", current_task_index)
	config.save("user://level3_tasks.cfg")

func start_next_task() -> void:
	if current_task_index >= tasks.size():
		print("All tasks completed!")
		return
	
	var current_task = tasks[current_task_index]
	print("Tugas Aktif: " + current_task.description)
	_activate_task_ui(current_task)
	
func _activate_task_ui(task: Dictionary) -> void:
	# Fungsi ini akan dipanggil untuk menampilkan tugas di UI
	# Bisa dikoneksikan ke UI CanvasLayer di scene
	# Menampilkan hint/arah ke target berdasarkan referensi gambar
	var hint = task.hint
	print("Petunjuk Visual: " + hint)
	# Tips: lihat motif ukiran Dayak pada pagar & pagar rumah, warna mat purple & kuning

func complete_current_task() -> void:
	if current_task_index >= tasks.size():
		return
	
	completed_tasks.append(current_task_index)
	current_task_index += 1
	save_completed_tasks()
	start_next_task()

func is_task_completed(task_index: int) -> bool:
	return completed_tasks.has(task_index - 1)  # task index is 1-based

func get_current_task() -> Dictionary:
	if current_task_index < tasks.size():
		return tasks[current_task_index]
	return {}

func get_progress_percent() -> float:
	if tasks.is_empty():
		return 1.0
	return (current_task_index + 1) / tasks.size()  # +1 karena index mulai dari 0

func check_task_progress(task_index: int, condition: String, progress: float) -> void:
	# Update task progress from external sources (player, NPC, etc.)
	if current_task_index >= 1 and current_task_index <= tasks.size():
		var task = tasks[task_index - 1]  # task index is 1-based for checking
		if task.type == condition:
			# Progress bisa di-track dari sini
			print("Progress updated for task: " + task.description + " - " + str(progress))