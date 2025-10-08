extends Window

signal search_for(search_dict: Dictionary);

@onready var searchbar = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Searchbar;
@onready var find_button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/FindButton;
@onready var cancel_button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/CancelButton;
@onready var match_case_box = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer/MatchCaseBox;
@onready var wrap_box = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer2/WrapBox;
@onready var up_radio_button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/PanelContainer/MarginContainer/HBoxContainer/UpDirectionRadioButton;
@onready var down_radio_button = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/PanelContainer/MarginContainer/HBoxContainer/DownDirectionRadioButton;

var search_dict_base: Dictionary = {
	"search_term": "",
	"match_case": false,
	"wrap": false,
	"direction": Global.Direction.DOWN,
}

func set_search_term(in_term: String) -> void:
	searchbar.text = in_term;

func _on_cancel_button_pressed() -> void:
	close_requested.emit();

func _on_find_button_pressed() -> void:
	if searchbar.text.is_empty():
		return;
	var new_search_dict = search_dict_base.duplicate();
	new_search_dict.search_term = searchbar.text;
	new_search_dict.match_case = match_case_box.button_pressed;
	new_search_dict.wrap = wrap_box.button_pressed;
	if up_radio_button.button_pressed:
		new_search_dict.direction = Global.Direction.UP;
	elif down_radio_button.button_pressed:
		new_search_dict.direction = Global.Direction.DOWN;
	search_for.emit(new_search_dict);
