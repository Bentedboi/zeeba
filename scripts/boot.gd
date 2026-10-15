extends Node2D
## First scene of the game: auto-updater (same as Rocket Leauge / F1 Game). In an exported
## game it asks GitHub whether a newer version was published (publish.ps1), downloads its
## game data (.pck) and loads it on top of the built-in data before the title opens.
## Offline or on any error the game just starts as is. In the editor it does nothing.
## An update can change anything under res:// (scripts, scenes, levels, art), but not
## project.godot settings or autoloads (game.gd, sfx.gd): those are read before this runs,
## so changing them needs players to download the full game again.

const TITLE_SCENE := "res://scenes/title.tscn"
const RELEASE_INFO := "res://release.json"   # {"version": n, "repo": "owner/name"}; publish.ps1 bumps it
const UPDATE_DIR := "user://update"
const CHECK_TIMEOUT := 5.0

var _status := ""
var _progress := -1.0   # 0..1 while downloading
var _http: HTTPRequest
var _own_version := 0
var _repo := ""


func _ready() -> void:
	set_process(false)   # only runs to drive the download progress bar
	var info: Dictionary = _read_json(RELEASE_INFO)
	_own_version = int(info.get("version", 0))
	_repo = info.get("repo", "")
	if not OS.has_feature("template") or _repo == "":
		print("Princess Zeeba v%d" % _own_version)
		_start_game.call_deferred()   # editor, or no GitHub repo set
		return

	# A newer version was downloaded before: use it.
	var local: Dictionary = _read_json(UPDATE_DIR + "/version.json")
	if int(local.get("version", 0)) > _own_version and _load_pack(local):
		_own_version = int(local.version)
	print("Princess Zeeba v%d (files: v%d)" % [_own_version, int(_read_json(RELEASE_INFO).get("version", 0))])

	_set_status("CHECKING FOR UPDATES...")
	_http = HTTPRequest.new()
	_http.timeout = CHECK_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_version_checked)
	if _http.request("https://github.com/%s/releases/latest/download/version.json" % _repo) != OK:
		_start_game()


func _on_version_checked(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_start_game()   # offline, or nothing published yet
		return
	var remote = JSON.parse_string(body.get_string_from_utf8())
	if not remote is Dictionary or int(remote.get("version", 0)) <= _own_version:
		_start_game()
		return
	var engine: Dictionary = Engine.get_version_info()
	if remote.get("godot", "") != "%d.%d.%d" % [engine.major, engine.minor, engine.patch]:
		# Made with a different Godot: the .pck won't run on this .exe.
		_set_status("A NEW VERSION IS OUT - DOWNLOAD THE FULL GAME AGAIN FROM GITHUB.")
		await get_tree().create_timer(4.0).timeout
		_start_game()
		return
	_download(remote)


func _download(remote: Dictionary) -> void:
	_set_status("DOWNLOADING UPDATE (VERSION %d)..." % int(remote.version))
	_progress = 0.0
	DirAccess.make_dir_recursive_absolute(UPDATE_DIR)
	# Each version gets its own file: the one loaded now stays open until the game closes.
	remote.file = "game_v%d.pck" % int(remote.version)
	var tmp := UPDATE_DIR + "/download.part"
	_http.timeout = 0.0
	_http.download_file = tmp
	_http.request_completed.disconnect(_on_version_checked)
	_http.request_completed.connect(func(result: int, code: int, _h, _b):
		set_process(false)
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 \
				or FileAccess.get_sha256(tmp) != String(remote.get("sha256", "")):
			DirAccess.remove_absolute(tmp)
			_progress = -1.0
			_set_status("UPDATE FAILED - STARTING THE CURRENT VERSION.")
			await get_tree().create_timer(2.0).timeout
			_start_game()
			return
		DirAccess.rename_absolute(tmp, UPDATE_DIR + "/" + remote.file)
		var f := FileAccess.open(UPDATE_DIR + "/version.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(remote))
		f.close()
		_load_pack(remote)
		_start_game())
	var url := "https://github.com/%s/releases/latest/download/%s" % [_repo, remote.get("pck", "game.pck")]
	if _http.request(url) != OK:
		_start_game()
		return
	set_process(true)


func _process(_dt: float) -> void:
	var total := _http.get_body_size()
	if total > 0:
		_progress = float(_http.get_downloaded_bytes()) / total
		queue_redraw()


## Load a downloaded version's files over the built-in ones, and delete older downloads.
func _load_pack(info: Dictionary) -> bool:
	var file: String = info.get("file", "")
	if file == "" or not ProjectSettings.load_resource_pack(UPDATE_DIR + "/" + file, true):
		return false
	for f in DirAccess.get_files_at(UPDATE_DIR):
		if f.ends_with(".pck") and f != file:
			DirAccess.remove_absolute(UPDATE_DIR + "/" + f)   # fails harmlessly if still open
	return true


func _start_game() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


func _set_status(text: String) -> void:
	_status = text
	queue_redraw()


func _draw() -> void:
	if _status == "":
		return
	PixelFont.draw_centered(self, 160, 80, "PRINCESS ZEEBA  V%d" % _own_version, Color(Art.PAL.g), 2, Color(Art.PAL.k))
	var lines := PixelFont.wrap(_status, 48).split("\n")
	for i in lines.size():
		PixelFont.draw_centered(self, 160, 116 + i * PixelFont.LINE, lines[i], Color.WHITE, 1, Color.BLACK)
	if _progress >= 0.0:
		draw_rect(Rect2(60, 150, 200, 8), Color(Art.PAL.k))
		draw_rect(Rect2(61, 151, 198 * clampf(_progress, 0.0, 1.0), 6), Color(Art.PAL.g))
