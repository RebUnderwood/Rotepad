extends PanelContainer

signal text_changed;

const SIZE_LIMIT: int = 100000000;

@onready var text_edit = $HBoxContainer/TextEdit;
@onready var scroll_bar = $HBoxContainer/VScrollBar;

@export var mode: Global.TextEditMode = Global.TextEditMode.NORMAL;
@export var byte_array: PackedByteArray = []:
	set(value):
		byte_array = value;
		if byte_array.size() > SIZE_LIMIT:
			mode = Global.TextEditMode.BIG_FILE;
		else:
			mode = Global.TextEditMode.NORMAL;
		if mode == Global.TextEditMode.BIG_FILE:
			_on_text_edit_resized();
			get_page();
		elif mode == Global.TextEditMode.NORMAL:
			apply_text();
@export var page_size: int = 3000;
@export var page_center: int = 0;

var page_start: int = 0;
var page_adj_start: int = page_start;
var page_end: int = page_start + page_size;
var page_adj_end: int = page_end;

var page_lines_size: int = 100;
var page_lines_start: int = 0;
var page_lines_center: int = 0;
var page_lines_end: int = 0;

var prev_scroll_val: float = 0.0;

var approx_width_columns: int = 0;



var text: String = "";

var relative_scroll_flag: bool = false;
var relative_scroll_amount: float = 0.0;


var lines_index_array: PackedInt32Array = [];



var my_value = 0;


var scroll_val: float = 0;
func _process(delta: float) -> void:
	if mode == Global.TextEditMode.BIG_FILE:
		if Input.is_action_just_released("mouse_down"):
			scroll_val += 1;
			scroll_bar.value = scroll_val;
		if Input.is_action_just_released("mouse_up"):
			scroll_val -= 1;
			scroll_bar.value = scroll_val;
	
func apply_text() -> void:
	text_edit.text = byte_array.get_string_from_utf8();
		 

func index_lines() -> void:
	var last_index = 0;
	while true:
		var next_newline = find_next_newline(last_index, 1);
		if next_newline == -1:
			break;
		lines_index_array.push_back(next_newline)
		last_index = next_newline + 1;
	
		

func get_page_start_end(in_center: int) -> void:
	page_center = max(in_center, 0);
	page_start = page_center - int(page_size / 2.0);
	page_end = page_center + int(page_size / 2.0);
	if page_start < 0:
		page_start = 0;
		relative_scroll_amount = (page_center - page_start) / float(page_size);
		relative_scroll_flag = true;
	elif page_start >= byte_array.size():
		page_start = (byte_array.size() - 1) - int(page_size / 2.0);
	elif page_end >= byte_array.size():
		page_end = byte_array.size() - 1;
		relative_scroll_amount = 1 - ((page_end - page_center) / float(page_size));
		relative_scroll_flag = true;
	else:
		relative_scroll_flag = false;

func find_next_newline(start_index: int, direction: int) -> int:
	const newline: int = 10;
	const carraige_return: int = 13;
	var closest_newline = -1;
	var closest_return = -1;
	if direction < 0:
		closest_newline = byte_array.rfind(newline, start_index);
		closest_return = byte_array.rfind(carraige_return, start_index);
	else:
		closest_newline = byte_array.find(newline, start_index);
		closest_return = byte_array.find(carraige_return, start_index);
	if closest_newline == -1 && closest_return == -1:
		return -1;
	elif closest_newline != -1:
		return closest_newline;
	else:
		return closest_return;

func adjust_for_newlines() -> void:
	if page_start > 0:
		page_adj_start = find_next_newline(page_start - 1, -1);
		if page_adj_start == -1:
			page_adj_start = 0;
	else:
		page_adj_start = 0;
		
	if page_end < byte_array.size() - 1:
		page_adj_end = find_next_newline(page_end + 1, 1);
		if page_adj_end == -1:
			page_adj_end = byte_array.size() - 1;
	else:
		page_adj_end = byte_array.size() - 1;
		
func get_lines_page_start_end(in_center: int = page_center) -> void:
	page_lines_start = in_center - int(page_lines_size / 2.0);
	page_lines_end = in_center + int(page_lines_size / 2.0);
	var lines_count = max(byte_array.count(10), byte_array.count(13));
	if page_lines_start < 0:
		page_lines_start = 0;
		relative_scroll_amount = (page_lines_center - page_lines_start) / float(page_lines_size);
		relative_scroll_flag = true;
	elif page_lines_end >= lines_count:
		page_lines_end = lines_count - 1;
		relative_scroll_amount = 1 - ((page_lines_end - page_lines_center) / float(page_lines_size));
		relative_scroll_flag = true;
	else:
		relative_scroll_flag = false;
		
	if page_lines_start >= lines_count:
		page_lines_start = (lines_count - 1) - int(page_lines_size / 2.0);
		
	
func get_page() -> void:
	get_page_start_end(page_center);
	adjust_for_newlines();
	var slice: PackedByteArray = byte_array.slice(page_adj_start, page_adj_end);
	text_edit.text = slice.get_string_from_utf8();
	page_start = page_adj_start;
	page_end = page_adj_end;


	
	
func scroll_page(index: float, change: float) -> void:
	print("scroll_change: " + str(change))
	var previous_textedit_scroll: int = text_edit.scroll_vertical;
	var previous_textedit_lines: int = text_edit.get_line_count();
	
	print("APPROX WIDTH COLUMNS: " + str(approx_width_columns))
	page_center = page_center + ((change * approx_width_columns) + ((change / abs(change)) * 10));
	print("PAGE CENTER: " + str(page_center))
	get_page();
		
	#var textedit_line_count_change = text_edit.get_line_count() - previous_textedit_lines;
	#text_edit.scroll_vertical = previous_textedit_scroll + textedit_line_count_change + change;
		
	
	
func adjust_relative_scroll(direction: int) -> void:
	if !relative_scroll_flag:
		pass;
		if direction > 0:
			text_edit.scroll_vertical = ceil(text_edit.get_line_count()/2.0);
		elif direction < 0:
			text_edit.scroll_vertical = floor(text_edit.get_line_count()/2.0);
		#print("TEXT EDIT SCROLL: " + str(text_edit.get_line_count()/2.0))
		#print("DIRECTION: " + str(direction));
		#if direction > 0:
			#if text_edit.text[-1] != "\n":
				#text_edit.scroll_vertical += 1;
			#else:
				#text_edit.scroll_vertical = text_edit.get_line_count()/2;
		#elif direction < 0:
			#if text_edit.text[0] != "\n":
				#text_edit.scroll_vertical -= 1;
			#else:
				#text_edit.scroll_vertical = text_edit.get_line_count()/2;
		#else:
				#text_edit.scroll_vertical = text_edit.get_line_count()/2;
	else:
		var line_count = text_edit.get_line_count();
		text_edit.scroll_vertical = round(line_count * relative_scroll_amount);
		print(relative_scroll_amount)
		
	
func has_selection() -> bool:
	return text_edit.has_selection();

func _on_text_edit_text_changed() -> void:
	#index_lines();
	text = text_edit.text;
	text_changed.emit();


func _on_v_scroll_bar_value_changed(value: float) -> void:
	print("SCROLL VAL: " + str(value))
	scroll_val = value;
	scroll_page(value, value - prev_scroll_val);
	prev_scroll_val = value;
	#page_center = int(value * 8);
	#var cur_text_scroll_pos = text_edit.scroll_vertical;
	#get_page();
	#text_edit.scroll_vertical = cur_text_scroll_pos
	#
	adjust_relative_scroll((value - prev_scroll_val)/abs(value - prev_scroll_val));
	#prev_scroll_val = value;


func _on_text_edit_resized() -> void:
	if is_instance_valid(text_edit):
		var char_width: float = text_edit.get_theme_font("font").get_char_size('a'.to_ascii_buffer()[0], text_edit.get_theme_font_size("font_size")).x;
		
		approx_width_columns = round(text_edit.size.x / char_width);
		scroll_bar.max_value = (byte_array.size() - 1) / float(approx_width_columns);
