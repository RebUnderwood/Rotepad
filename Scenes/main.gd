extends PanelContainer

enum UnsavedState {NONE, NEW_FILE, OPENING_FILE, EXITING_PROGRAM}
@onready var text_edit = $VBoxContainer/Body/TextEdit;
@onready var menu_bar = $VBoxContainer/Top/MenuBar;

@onready var open_file_dialogue = $OpenFileDialog;
@onready var write_file_dialogue = $SaveFileDialog;
@onready var unsaved_dialogue = $UnsavedConfirmDialogue

var accepting_input: bool = true;
var cur_file_path: String = "";
var is_saved: bool = true;
var unsaved_confirm_state: UnsavedState = UnsavedState.NONE;

func _ready() -> void:
	refresh_window_title();

func _process(_delta: float) -> void:
	if accepting_input:
		if Input.is_key_pressed(KEY_CTRL):
			if Input.is_key_pressed(KEY_S):
				save();
			elif Input.is_key_pressed(KEY_O):
				if is_saved:
					open_file_dialogue.show();
					accepting_input = false;
				else:
					unsaved_confirm_state = UnsavedState.OPENING_FILE;
					unsaved_dialogue.show();
	
func refresh_window_title() -> void:
	var out_title : String = "";
	var filename = "Untitled";
	if cur_file_path != "":
		filename = cur_file_path.get_file();
	if !is_saved:
		filename = "*" + filename;
	DisplayServer.window_set_title(filename + " - Rotepad");
	
func write_file(content: String, in_path: String) -> bool:
	var file = FileAccess.open(in_path, FileAccess.WRITE);
	return !file.store_string(content);
	
func load_file(in_path: String) -> String:
	var file = FileAccess.open(in_path, FileAccess.READ);
	var content = file.get_as_text();
	return content;
	
func new_file() -> void:
	if is_saved:
		cur_file_path = "";
		text_edit.text = "";
	else:
		unsaved_confirm_state = UnsavedState.NEW_FILE;
		unsaved_dialogue.show();
		
func save(save_as: bool = false) -> void:
	if save_as || cur_file_path == "":
		write_file_dialogue.show();
		accepting_input = false;
	else:
		write_file(text_edit.text, cur_file_path);
		is_saved = true;
		accepting_input = true;
		refresh_window_title();
		unsaved_followup();
		
func unsaved_followup() -> void:
	match unsaved_confirm_state:
		UnsavedState.NEW_FILE:
			cur_file_path = "";
			text_edit.text = "";
		UnsavedState.OPENING_FILE:
			await get_tree().create_timer(.5).timeout;
			open_file_dialogue.show();
			accepting_input = false;
		UnsavedState.EXITING_PROGRAM:
			get_tree().quit();
		_:
			pass;
	unsaved_confirm_state = UnsavedState.NONE;

func _on_save_file_dialog_file_selected(in_path: String) -> void:
	var to_be_saved: String = text_edit.text;
	write_file(to_be_saved, in_path);
	cur_file_path = in_path;
	is_saved = true;
	accepting_input = true;
	refresh_window_title();
	unsaved_followup();

func _on_save_file_dialog_canceled() -> void:
	accepting_input = true;
	
func _on_open_file_dialog_file_selected(in_path: String) -> void:
	text_edit.text = load_file(in_path);
	accepting_input = true;
	cur_file_path = in_path;
	is_saved = true;
	refresh_window_title();

func _on_open_file_dialog_canceled() -> void:
	accepting_input = true;

func _on_file_menu_id_pressed(id: int) -> void:
	match id:
		0: # New
			new_file();
		1: # New Window
			new_file();
		2: # Open
			if is_saved:
				open_file_dialogue.show();
				accepting_input = false;
			else:
				unsaved_confirm_state = UnsavedState.OPENING_FILE;
				unsaved_dialogue.show();
		3: # Save
			save();
		4: # Save As...
			save(true);
		6:
			if is_saved:
				get_tree().quit();
			else:
				unsaved_confirm_state = UnsavedState.EXITING_PROGRAM;
				unsaved_dialogue.show();
			


func _on_text_edit_text_changed() -> void:
	is_saved = false;
	refresh_window_title();


func _on_window_close_requested() -> void:
	unsaved_dialogue.hide();

func _on_cancel_button_pressed() -> void:
	unsaved_confirm_state = UnsavedState.NONE;
	unsaved_dialogue.hide();

func _on_dont_save_button_pressed() -> void:
	unsaved_dialogue.hide();
	unsaved_followup();

func _on_save_button_pressed() -> void:
	unsaved_dialogue.hide();
	save();
