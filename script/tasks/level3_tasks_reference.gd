extends Node

const TASK_TYPE_DIRECTION = "direction"
const TASK_TYPE_COLLECT = "collect"
const TASK_TYPE_TALK = "talk"
const TASK_TYPE_FIND = "find"

@export var tasks: Array = [
	{"type": TASK_TYPE_DIRECTION, "description": "Arah ke halaman rumah", "target_node": "/root/RumahBetang/Player", "hint": "Perhatikan struktur rumah Dayak Betang di atasmu", "completed": false},
	{"type": TASK_TYPE_TALK, "description": "Bicarai dengan Tempong", "target_node": "Tempong", "hint": "NPC Tempong berdiri di bawah rumah ke kiri", "completed": false},
	{"type": TASK_TYPE_FIND, "description": "Cari kunci rahasia", "target_node": "secret_key", "hint": "Kunci tersembunyi di rak benda di pojok kanan dalam rumah", "completed": false}
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
	# Menampilkan hint/arah ke target
	var target = task.target_node
	var hint = task.hint
	print("Petunjuk: " + hint)
	# Bisa ditambahkan kode untuk menampilkan waypoint di layar

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