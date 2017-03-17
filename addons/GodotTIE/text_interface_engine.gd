# MADE BY HENRIQUE ALVES
# LICENSE STUFF BLABLABLA
# (MIT License)
# Tweaked by @jackmakesthings


extends ReferenceFrame
# TODO: is this the best thing to extend from?

const _ARRAY_CHARS = [" ","!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~"]
# TODO: this seems super gnarly, surely there is a better way to type text...

# [INPUT]
const STATE_WAITING = 0
const STATE_OUTPUT = 1
const STATE_INPUT = 2

# [INPUT]
const BUFF_DEBUG = 0
const BUFF_TEXT = 1
const BUFF_SILENCE = 2
const BUFF_BREAK = 3
const BUFF_INPUT = 4

onready var _buffer = [] # 0 = Debug; 1 = Text; 2 = Silence; 3 = Break; 4 = Input
onready var _label = RichTextLabel.new() # The Label in which the text is going to be displayed
onready var _state = 0 # 0 = Waiting; 1 = Output; 2 = Input

onready var _output_delay = 0
onready var _output_delay_limit = 0
onready var _on_break = false
onready var _buff_beginning = true
onready var _turbo = false
onready var _break_key = KEY_RETURN

# [INPUT]
onready var _blink_input_visible = false
onready var _blink_input_timer = 0
onready var _input_timer_limit = 1
onready var _input_index = 0

# =============================================== 
# Text display properties!
export(Font) var FONT

# [INPUT]
# Text input properties!
export(bool) var PRINT_INPUT = true # If the input is going to be printed
export(bool) var BLINKING_INPUT = true # If there is a _ blinking when input is appropriate
export(int) var INPUT_CHARACTERS_LIMIT = -1 # If -1, there'll be no limits in the number of characters
# ===============================================


# Get the current contents
func get_bbcode():
	return _label.get_bbcode()

# Changes the state of the Text Interface Engine
func set_state(i): 
	emit_signal("state_change", int(i))
	if _state == STATE_INPUT:
		_blink_input(true)
	_state = i
	if(i == 2): # Set input index to last character on the label
		_input_index = _label.get_bbcode().length()


###
# Buffer operations - these push different types of output to the interface
###

# Debug-style output
func buff_debug(f, lab = false, arg0 = null, push_front = false):
	var b = {"buff_type":BUFF_DEBUG,"debug_function":f,"debug_label":lab,"debug_arg":arg0}
	if(! push_front):
		_buffer.append(b)
	else:
		_buffer.push_front(b)


# Standard text printing, at a given speed
# Not sure what 'tag' does yet...
func buff_text(text, vel = 0, tag = "", push_front = false):
	var b = {"buff_type":BUFF_TEXT, "buff_text":text, "buff_vel":vel, "buff_tag":tag}
	if !push_front:
		_buffer.append(b)
	else:
		_buffer.push_front(b)


# ...
func buff_silence(len, tag = "", push_front = false):
	var b = {"buff_type":BUFF_SILENCE, "buff_length":len, "buff_tag":tag}
	if !push_front:
		_buffer.append(b)
	else:
		_buffer.push_front(b)


# Stop output until the player hits a key (enter, by default)
# Not currently in our designs but maybe this is useful...
func buff_break(tag = "", push_front = false): 
	var b = {"buff_type":BUFF_BREAK, "buff_tag":tag}
	if !push_front:
		_buffer.append(b)
	else:
		_buffer.push_front(b)


# [INPUT]
# Tell the buffer we're going to expect some text input 
func buff_input(tag = "", push_front = false):
	var b = {"buff_type":BUFF_INPUT, "buff_tag":tag}
	if !push_front:
		_buffer.append(b)
	else:
		_buffer.push_front(b)


# Shorthand for adding a line break to the text
func add_newline():
	_label_print("\n")


###
# Cleanup functions and resets
###

# Deletes ALL the text on the label
func clear_text(): 
	_label.set_bbcode("")

# Clears all buffs in _buffer, including delays and settings
func clear_buffer(): 
	_on_break = false
	set_state(STATE_WAITING)
	_buffer.clear()
	
	_output_delay = 0
	_output_delay_limit = 0
	_buff_beginning = true
	_turbo = false

# Reset TIE to its initial 100% cleared state
func reset():
	clear_text()
	clear_buffer()


###
# On-the-fly interface changes;
# (Might scrap these functions and let the bbcode do the work, ultimately.)
###

# Changes the font of the text; 
# weird stuff will happen if you use this function after text has been printed
func set_font_bypath(str_path): 
	_label.add_font_override("font",load(str_path))

# Changes font of the text (uses the resource)
func set_font_byresource(font):
	_label.add_font_override("font", font)

# Changes the color of the text
func set_color(c): 
	_label.add_color_override("font_color", c)

# Changes the velocity of the text being printed
func set_buff_speed(v):
	if (_buffer[0]["buff_type"] == BUFF_TEXT):
		_buffer[0]["buff_vel"] = v

# Print stuff in the maximum velocity and ignore breaks
func set_turbomode(s):
	_turbo = s;

# Set a new key to resume breaks (uses scancode!)
func set_break_key_by_scancode(i):
	_break_key = i


# ==============================================
# Reserved methods

# Override
func _ready():
	set_fixed_process(true)
	set_process_input(true)
	add_child(_label)
	
	# Setting font of the text
	if(FONT != null):
		_label.add_font_override("font", FONT)
	
	# Setting size of the frame
	_label.set_size(Vector2(get_size().x,get_size().y))
	
	add_user_signal("input_enter",[{"input":TYPE_STRING}]) # When user finished an input
	add_user_signal("buff_end") # When there is no more outputs in _buffer
	add_user_signal("state_change",[{"state":TYPE_INT}]) # When the state of the engine changes
	add_user_signal("enter_break") # When the engine stops on a break
	add_user_signal("resume_break") # When the engine resumes from a break
	add_user_signal("tag_buff",[{"tag":TYPE_STRING}]) # When the _buffer reaches a buff which is tagged

func _fixed_process(delta):

	# Handle text inputs if that's the current state. 
	# Might remove this functionality later.
	if(_state == STATE_INPUT):
		if BLINKING_INPUT:
			_blink_input_timer += delta
			if(_blink_input_timer > _input_timer_limit):
				_blink_input_timer -= _input_timer_limit
				_blink_input()

	# If we're not inputting, are we outputting?
	elif(_state == STATE_OUTPUT):

		# Well, not if the buffer's empty.
		if(_buffer.size() == 0):
			set_state(STATE_WAITING)
			emit_signal("buff_end")
			return
		
		# But otherwise...
		var o = _buffer[0] # TODO: rename 'o' variable
		
		# Mode 0: Debug. Supports func calls?
		if (o["buff_type"] == BUFF_DEBUG):
			if(o["debug_label"] == false):
				if(o["debug_arg"] == null):
					print(self.call(o["debug_function"]))
				else:
					print(self.call(o["debug_function"],o["debug_arg"]))
			else:
				if(o["debug_arg"] == null):
					print(_label.call(o["debug_function"]))
				else:
					print(_label.call(o["debug_function"],o["debug_arg"]))
			_buffer.pop_front()

		########
		# Mode 1: Basic text printing
		elif (o["buff_type"] == BUFF_TEXT):

			# Maybe buff_tag is for bbcode tags...
			if(o["buff_tag"] != "" and _buff_beginning == true):
				emit_signal("tag_buff", o["buff_tag"])
			
			# Gotta go fast?
			if (_turbo):
				o["buff_vel"] = 0
			
			# Printing everything at once
			if(o["buff_vel"] == 0):
				while(o["buff_text"] != ""):
					_label_print(o["buff_text"][0])
					_buff_beginning = false
					o["buff_text"] = o["buff_text"].right(1)
			
			# Printing character by character		
			else:

				# Delay printing till enough time elapses (via delta)
				_output_delay_limit = o["buff_vel"]
				if(_buff_beginning):
					_output_delay = _output_delay_limit + delta
				else:
					_output_delay += delta

				# Once we've waited long enough, print the character
				if(_output_delay > _output_delay_limit):
					_label_print(o["buff_text"][0])
					_buff_beginning = false
					_output_delay -= _output_delay_limit
					o["buff_text"] = o["buff_text"].right(1)
	
			# This buff finished, so pop it out of the array
			if (o["buff_text"] == ""):
				_buffer.pop_front()
				_buff_beginning = true
				_output_delay = 0

		#####
		# Mode 2: silences (pause for effect)
		elif (o["buff_type"] == BUFF_SILENCE):

			if(o["buff_tag"] != "" and _buff_beginning == true):
				emit_signal("tag_buff", o["buff_tag"])
				_buff_beginning = false
			_output_delay_limit = o["buff_length"]
			_output_delay += delta

			# Wait the specified time, then advance the buffer
			if(_output_delay > _output_delay_limit):
				_output_delay = 0
				_buff_beginning = true
				_buffer.pop_front()


		#####
		# Mode 3: Break, for pausing mid-output. Might be useful?
		elif (o["buff_type"] == BUFF_BREAK):

			if(o["buff_tag"] != "" and _buff_beginning == true):
				emit_signal("tag_buff", o["buff_tag"])
				_buff_beginning = false

			# No breaks in turbo mode	
			if(_turbo):
				_buffer.pop_front()

			elif(!_on_break):
				emit_signal("enter_break")
				_on_break = true


		#####
		# Mode 4: Input mode, prompts the user for text
		# [INPUT]
		elif (o["buff_type"] == BUFF_INPUT):

			if(o["buff_tag"] != ""and _buff_beginning == true):
				emit_signal("tag_buff", o["buff_tag"])
				_buff_beginning = false
			set_state(STATE_INPUT)
			_buffer.pop_front()


# [INPUT]
func _input(event):

	if(event.type == InputEvent.KEY and event.is_pressed() == true ):
		# TODO: scroll key handler used to live here, should confirm it's not needed...

		# If we're on a break, did the user just press the un-break key?
		if(_state == 1 and _on_break):
			if(event.scancode == _break_key):
				emit_signal("resume_break")
				_buffer.pop_front() # Pop out break buff
				_on_break = false

		# If we're in the input state, stop flashing the cursor (if applicable)
		elif(_state == 2):
			if(BLINKING_INPUT):
				_blink_input(true) 
			
			var input = _label.get_bbcode().right(_input_index)
			input = input.replace("\n","")

			# Backspace key means delete the last character
			if(event.scancode == KEY_BACKSPACE): 
				_delete_last_character(true)

			# Enter key means they're done inputting
			elif(event.scancode == KEY_RETURN):
				emit_signal("input_enter", input)

				# Optionally, clear the input after it's been received
				if(!PRINT_INPUT):
					var i = _label.get_bbcode().length() - _input_index
					while(i > 0):
						_delete_last_character()
						i-=1
				set_state(STATE_OUTPUT)
			
			# Any other key means type something
			# TODO: this is so janky, needs to be reworked for sure
			elif(event.unicode >= 32 and event.unicode <= 126):
				if(INPUT_CHARACTERS_LIMIT < 0 or input.length() < INPUT_CHARACTERS_LIMIT):
					_label_print(_ARRAY_CHARS[event.unicode-32])

# [INPUT]
# Flash the input cursor
func _blink_input(reset = false):
	if(reset == true):
		if(_blink_input_visible):
			_delete_last_character()
		_blink_input_visible = false
		_blink_input_timer = 0
		return
	if(_blink_input_visible):
		_delete_last_character()
		_blink_input_visible = false
	else:
		_blink_input_visible = true
		_label_print("_")


# [INPUT]
# Used by the manual backspace handler, which is probably not staying
func _delete_last_character(scrollup = false):
	_label.set_bbcode(_label.get_bbcode().left(_label.get_bbcode().length()-1))


# Not sure this is used any more...
func _get_last_line():
	var i = _label.get_bbcode().rfind("\n")
	if (i == -1):
		return _label.get_bbcode()
	return _label.get_bbcode().substr(i,_label.get_bbcode().length()-i)


# And here's the thing that actually puts text in the box!
func _label_print(t): # Add text to the label
	_label.set_bbcode(_label.get_bbcode() + t)
	return t
