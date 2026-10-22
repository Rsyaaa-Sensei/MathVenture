extends Node

signal quest_updated

var outside_spawn_position: Vector2 = Vector2.ZERO
var entering_house := false
# Posisi pemain di interior saat membuka peti 3D (Vector2.ZERO = tidak ada).
var interior_return_position: Vector2 = Vector2.ZERO
# true hanya bila pemain memang kembali dari mini-game 3D ke ruangan yang sama,
# supaya posisi lama tidak terbawa saat pindah level.
var pending_room_return := false
var level_intro_shown := false
var talked_npcs: Dictionary = {}
var inspected_objects: Dictionary = {}
var songkok_studied := false


## Bersihkan status antar-scene yang bersifat sementara (posisi spawn).
## Panggil setiap kali pindah level/menu, supaya posisi dari scene sebelumnya
## tidak terbawa dan membuat pemain muncul di tempat yang salah.
func reset_for_new_level() -> void:
    outside_spawn_position = Vector2.ZERO
    interior_return_position = Vector2.ZERO
    pending_room_return = false
    entering_house = false
    talked_npcs.clear()
    inspected_objects.clear()
    songkok_studied = false


func mark_npc_talked(npc_id: String) -> void:
    talked_npcs[npc_id] = true
    quest_updated.emit()


func is_npc_talked(npc_id: String) -> bool:
    return talked_npcs.get(npc_id, false)


func mark_object_inspected(obj_id: String) -> void:
    inspected_objects[obj_id] = true
    quest_updated.emit()


func is_object_inspected(obj_id: String) -> bool:
    return inspected_objects.get(obj_id, false)


func mark_songkok_studied() -> void:
    songkok_studied = true
    quest_updated.emit()
