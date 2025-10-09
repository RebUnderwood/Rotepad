extends MenuBar

@onready var file_menu = $FileMenu;
@onready var edit_menu = $EditMenu;
@onready var settings_menu = $SettingsMenu;
@onready var zoom_menu = $SettingsMenu/ZoomMenu;
@onready var help_menu = $HelpMenu;

const FILE_MENU_SHORTCUTS = [
	[[KEY_CTRL, KEY_N]],
	[[KEY_CTRL, KEY_SHIFT, KEY_N]],
	[[KEY_CTRL, KEY_O]],
	[[null]],
	[[KEY_CTRL, KEY_S]],
	[[KEY_CTRL, KEY_SHIFT, KEY_S]],
	[[KEY_CTRL, KEY_E]],
	[[null]],
	[[null]],
]

const EDIT_MENU_SHORTCUTS = [
	[[KEY_CTRL, KEY_Z]],
	[[null]],
	[[KEY_CTRL, KEY_X]],
	[[KEY_CTRL, KEY_C]],
	[[KEY_CTRL, KEY_V]],
	[[KEY_DELETE]],
	[[null]],
	[[KEY_CTRL, KEY_F]],
	[[KEY_F3]],
	[[KEY_SHIFT, KEY_F3]],
	[[KEY_CTRL, KEY_H]],
	[[null]],
	[[KEY_CTRL, KEY_A]],
	[[KEY_F5]],
]

const SETTINGS_MENU_SHORTCUTS = [
	[[null]],
	[[null]],
	[[null]],
	[[null]],
	[[null]],
	[[null]],
	[[null]],
	[[null]],
	[[KEY_F11]],
]

const ZOOM_MENU_SHORTCUTS = [
	[[KEY_CTRL, KEY_PLUS], [KEY_CTRL, KEY_KP_ADD], [KEY_CTRL, KEY_EQUAL]],
	[[KEY_CTRL, KEY_MINUS], [KEY_CTRL, KEY_KP_SUBTRACT]],
	[[KEY_CTRL, KEY_0], [KEY_CTRL, KEY_KP_0]],
]

func apply_shortcuts(menu: PopupMenu, shortcut_array: Array) -> void:
	for i in range(shortcut_array.size()):
		var sc = Shortcut.new();
		for keys in shortcut_array[i]:
			if keys[0] == null:
				continue;
			
			var ctrl_pressed: bool = false;
			var shift_pressed: bool = false;
			var input_event = InputEventKey.new();
			for key in keys:
				if key == KEY_CTRL:
					ctrl_pressed = true;
				elif key == KEY_SHIFT:
					shift_pressed = true;
				else:
					input_event.keycode = key;
			input_event.ctrl_pressed = ctrl_pressed;
			input_event.shift_pressed = shift_pressed;
			sc.events.push_back(input_event);
		menu.set_item_shortcut(i, sc);

func _ready() -> void:
	apply_shortcuts(file_menu, FILE_MENU_SHORTCUTS);
	apply_shortcuts(edit_menu, EDIT_MENU_SHORTCUTS);
	apply_shortcuts(settings_menu, SETTINGS_MENU_SHORTCUTS);
	apply_shortcuts(zoom_menu, ZOOM_MENU_SHORTCUTS);
	settings_menu.set_item_submenu_node(0, zoom_menu);
	
