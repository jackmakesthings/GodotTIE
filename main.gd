extends Control

onready var tie = get_node("panel/text_interface_engine")

# two ways of injecting bbcode - either as "wraps" array 
# like ["[color=red]", "[/color]"] (expects two bbcode strings)
# or as a standalone line with speed set to 0.


var demo1 =[
{"text": "", "speed": 0.1},
{"text": "Chi", "speed": 0},
{"text": "", "speed": 0.2},
{"text": "ke", "speed": 0},
{"text": "", "speed": 0.1},
{"text": "ty", "speed": 0},
{"text": "", "speed": 0.1},
{"text": " Chi", "speed": 0},
{"text": "", "speed": 0.4},
{"text": "na", "speed": 0},
{"text": "", "speed": 0.4},
{"text": " the ", "speed": 0},
{"text": "", "speed": 0.1},
{"text": "[color=aqua]Chi", "speed": 0},
{"text": "", "speed": 0.4},
{"text": "nese ", "speed": 0},
{"text": "", "speed": 0.4},
{"text": "chi", "speed": 0},
{"text": "", "speed": 0.1},
{"text": "cken[/color]", "speed": 0},
]
	
var demo2 = [
{"text": "mother nature will be like", "speed": 0.03},
{"text": " SLOW DOWN", "speed": 0.3, "wraps": ["[color=yellow]", "[/color]"]},
{"text": " and you'll be like", "speed": 0.03},
{"text": " FUCK YOU", "speed": 0.01, "wraps": ["[color=red][b]", "[/b][/color]"]},
{"text": " and kick her in the face with your", "speed": 0.03},
{"text": "[color=lime]", "speed": 0},
{"text": " ENERGY LEGS", "speed": 0.01},
{"text": "[/color]", "speed": 0}
]

func type_demo(which):
		
	var i
	for i in range(0, which.size()):
		var demo_line = which[i]
		
		if demo_line.text == "":
			tie.buff_silence(demo_line.speed)
		else:
			if demo_line.has('wraps'):
				tie.buff_text(demo_line.text, demo_line.speed, demo_line.wraps)
			else:
				tie.buff_text(demo_line.text, demo_line.speed)


func select_demo(i):
	tie.reset()
	if(i == 1):
		type_demo(demo1)
	elif(i == 2):
		type_demo(demo2)
	elif(i == 3):
		tie.set_color(Color(1,1,0.3))
		tie.buff_text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras semper finibus sapien, ut fringilla nulla vehicula ac. In hac habitasse platea dictumst. Nulla lobortis tempus sem vel lobortis. Mauris facilisis mollis nunc, vitae aliquet dui dictum id. Nullam ultricies facilisis interdum. Ut id semper eros, in lobortis diam. Nam consequat, dolor pharetra imperdiet finibus, lacus turpis tincidunt velit, ut fringilla ligula orci et justo. Praesent sagittis lectus eu metus faucibus aliquam. Donec sollicitudin porttitor massa a mollis. Nulla eleifend orci lacus, et tristique dui viverra eu. Sed nec mollis ligula. Quisque eu tellus libero. Nulla id hendrerit mauris.",0)
	
	tie.set_state(tie.STATE_OUTPUT)

func _ready():
	# Add the demos in the list
	get_node("demos_list").set_focus_mode(0)
	get_node("demos_list").add_item("No demo")
	get_node("demos_list").add_item("BNL")
	get_node("demos_list").add_item("Powerthirst")
	get_node("demos_list").add_item("Lipsum")
	
	# Just for debugging/convenience
	tie.connect("buff_end", self, "_on_buff_end")
	tie.connect("state_change", self, "_on_state_change")
	tie.connect("enter_break", self, "_on_enter_break")
	tie.connect("resume_break", self, "_on_resume_break")
	tie.connect("tag_buff", self, "_on_tag_buff")
	tie.connect("size_change", self, "_on_size_change")
	pass

func _on_demos_list_item_selected( ID ):
	select_demo(ID)

func _on_buff_end():
	print("Buff End")

func _on_state_change(i):
	print("New state: ", i)

func _on_size_change(size):
	print("New height: ", size)

func _on_enter_break():
	print("Enter Break")

func _on_resume_break():
	print("Resume Break")

func _on_tag_buff(s):
	print("Tag Buff ",s)
