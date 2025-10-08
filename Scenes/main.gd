extends PanelContainer

enum UnsavedState {NONE, NEW_FILE, OPENING_FILE, EXITING_PROGRAM}
@onready var text_edit = $VBoxContainer/Body/TextEdit;
@onready var menu_bar = $VBoxContainer/Top/MenuBar;
@onready var bottom_bar = $VBoxContainer/Bottom;

@onready var settings_menu = $VBoxContainer/Top/MenuBar/SettingsMenu;

@onready var zoom_container = $VBoxContainer/Bottom/MarginContainer/HBoxContainer/ZoomContainer;
@onready var zoom_label = $VBoxContainer/Bottom/MarginContainer/HBoxContainer/ZoomContainer/ZoomLabel;

@onready var wordcount_container = $VBoxContainer/Bottom/MarginContainer/HBoxContainer/WordcountContainer;
@onready var wordcount_label = $VBoxContainer/Bottom/MarginContainer/HBoxContainer/WordcountContainer/WordcountLabel;

@onready var open_file_dialogue = $OpenFileDialog;
@onready var write_file_dialogue = $SaveFileDialog;
@onready var unsaved_dialogue = $UnsavedConfirmDialogue;
@onready var search_dialogue = $SearchDialogue;

@onready var text_done_changing_timer = $TextDoneChangingTimer;

var accepting_input: bool = true;
var cur_file_path: String = "";
var is_saved: bool = true;
var unsaved_confirm_state: UnsavedState = UnsavedState.NONE;
var wordcount_regex = RegEx.new();

var previously_selecting: bool = false;


func _ready() -> void:
	refresh_window_title();
	unsaved_dialogue.close_requested.connect(_on_window_close_requested.bind(unsaved_dialogue));
	search_dialogue.close_requested.connect(_on_window_close_requested.bind(search_dialogue));
	wordcount_regex.compile("[\\w-]+");
	update_wordcount();
	
	
func _process(_delta: float) -> void:
	if accepting_input:
		pass
				
func set_zoom(in_zoom: int)	-> void:
	zoom_label.text = str(in_zoom) + "%";
	
func count_words(in_text: String = text_edit.text) -> int:
	return wordcount_regex.search_all(in_text).size();
	
func set_wordcount(in_wordcount: int) ->void:
	var string_wordcount: String = str(in_wordcount);
	var result: String = "";
	var count: int = 0
	for i in range(string_wordcount.length() - 1, -1, -1):
		result = string_wordcount[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	wordcount_label.text = result + " words";

func update_wordcount() -> void:
	if wordcount_container.visible:
		if text_edit.has_selection():
			set_wordcount(count_words(text_edit.get_selected_text()));
		else:
			set_wordcount(count_words(text_edit.text));

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
		update_wordcount();
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

func convert_offset_to_caret_position(origin: Vector2i, char_offset: int) -> Vector2i:
	var out: Vector2i = Vector2i.ZERO;
	var remaining_offset: int = origin.x + char_offset;
	var i: int = origin.y;
	if remaining_offset < 0:
		i -= 1
	var dir = char_offset / abs(char_offset);
	while true:
		if i >= text_edit.get_line_count():
			i = 0;
		elif i < 0:
			i = text_edit.get_line_count() - 1;
		var line_length: int = text_edit.get_line(i).strip_escapes().length();
		if  abs(remaining_offset) > line_length:
			remaining_offset -= (line_length * dir);
		elif remaining_offset < 0:
			out = Vector2i(line_length - remaining_offset - 1, i);
			break;
		else:
			out = Vector2i(remaining_offset, i);
			break;
		i += dir;
	return out;

func search(search_dict: Dictionary) -> bool:
	if text_edit.text.is_empty():
		return false;
	var search_flags: int = 0;
	var adj_caret_pos: Vector2i = Vector2i(text_edit.get_caret_column(), text_edit.get_caret_line());
	if search_dict.match_case:
		search_flags += 1;
	if search_dict.direction == Global.Direction.UP:
		adj_caret_pos = Vector2i(text_edit.get_selection_origin_column(), text_edit.get_selection_origin_line());
		adj_caret_pos = convert_offset_to_caret_position(adj_caret_pos, -1);
		search_flags += 4;
	text_edit.grab_focus();	 
	var match_location: Vector2i = text_edit.search(search_dict.search_term, search_flags, adj_caret_pos.y, adj_caret_pos.x);
	if match_location == Vector2i(-1, -1):
		return false;
	elif !search_dict.wrap && search_dict.direction == Global.Direction.UP && match_location.y > text_edit.get_caret_line():
		return false;
	elif !search_dict.wrap && search_dict.direction == Global.Direction.DOWN && match_location.y < text_edit.get_caret_line():
		return false;
	var caret_position: Vector2i = convert_offset_to_caret_position(match_location, search_dict.search_term.length());
	text_edit.select(match_location.y, match_location.x, caret_position.y , caret_position.x);
	text_edit.scroll_vertical = text_edit.get_scroll_pos_for_line(match_location.y);
	return true;
	
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
	update_wordcount();
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

func _on_edit_menu_id_pressed(id: int) -> void:
	match id:
		0:
			text_edit.undo();
		2:
			text_edit.cut();
		3:
			text_edit.copy();
		4:
			text_edit.paste();
		5:
			text_edit.delete_selection();
		7:
			search_dialogue.set_search_term(text_edit.get_selected_text());
			search_dialogue.show();
		8:
			var search_dict: Dictionary = {
				"search_term": text_edit.get_selected_text(),
				"match_case": false,
				"wrap": false,
				"direction": Global.Direction.DOWN,
			}
			search(search_dict);
		9:
			var search_dict: Dictionary = {
				"search_term": text_edit.get_selected_text(),
				"match_case": false,
				"wrap": false,
				"direction": Global.Direction.UP,
			}
			search(search_dict);
		10:
			# Find and Replace
			pass
			
		11:
			# Go to
			pass
			
		12:
			text_edit.select_all();
		13:
			# time and date
			pass

func _on_settings_menu_id_pressed(id: int) -> void:
	match id:
		4:
			settings_menu.set_item_checked(4, !settings_menu.is_item_checked(4))
			wordcount_container.visible = settings_menu.is_item_checked(4);

func _on_zoom_menu_id_pressed(id: int) -> void:
	match id:
		0:
			var font_size = text_edit.get_theme_font_size("font_size");
			text_edit.add_theme_font_size_override("font_size", font_size + 2);
		1:
			var font_size = text_edit.get_theme_font_size("font_size");
			if font_size > 2:
				text_edit.add_theme_font_size_override("font_size", font_size - 2);
		2:
			text_edit.add_theme_font_size_override("font_size", 18);
		
	var font_size = text_edit.get_theme_font_size("font_size");
	set_zoom(round((font_size/18.0) * 100));

func _on_text_edit_text_changed() -> void:
	is_saved = false;
	refresh_window_title();
	text_done_changing_timer.start();

			
func _on_window_close_requested(window: Node) -> void:
	window.hide();

func _on_cancel_button_pressed() -> void:
	unsaved_confirm_state = UnsavedState.NONE;
	unsaved_dialogue.hide();

func _on_dont_save_button_pressed() -> void:
	unsaved_dialogue.hide();
	unsaved_followup();

func _on_save_button_pressed() -> void:
	unsaved_dialogue.hide();
	save();

func _on_search_dialogue_search_for(search_dict: Dictionary) -> void:
	var match_found: bool = search(search_dict);
	if !match_found:
		print("NO MATCH!");

func _on_text_done_changing_timer_timeout() -> void:
	update_wordcount();
	# Put autosave here

func _on_text_edit_caret_changed() -> void:
	if text_edit.has_selection():
		update_wordcount();
		previously_selecting = true;
	elif previously_selecting:
		previously_selecting = false;
		update_wordcount();
