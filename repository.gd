extends Control

onready var index = $VSplitContainer/RepoVis/Index
onready var nodes = $VSplitContainer/RepoVis/Nodes
onready var file_browser = $VSplitContainer/FileBrowser
onready var label_node = $VSplitContainer/RepoVis/Label

export var label: String setget set_label
export var path: String setget set_path, get_path
export var file_browser_active = true setget set_file_browser_active

var node = preload("res://node.tscn")

var shell = Shell.new()
var objects = {}
var mouse_inside = false

var _simplified_view = false

func _ready():
	file_browser.shell = shell
	
	# Trigger these again because nodes were not ready before.
	set_label(label)
	set_file_browser_active(file_browser_active)

func _process(_delta):
	nodes.rect_pivot_offset = nodes.rect_size / 2
	if path:
		apply_forces()
		
func _input(event):
	if mouse_inside:
		if event.is_action_pressed("zoom_out") and nodes.rect_scale.x > 0.3:
			nodes.rect_scale -= Vector2(0.05, 0.05)
		if event.is_action_pressed("zoom_in") and nodes.rect_scale.x < 2:
			nodes.rect_scale += Vector2(0.05, 0.05)

func there_is_a_git():
	return shell.run("test -d .git && echo yes || echo no") == "yes\n"
	
func update_everything():
	file_browser.update()
	if there_is_a_git():
		update_head()
		update_refs()
		update_index()
		update_objects()
		remove_gone_stuff()
	else:
		index.text = ""
		for o in objects:
			objects[o].queue_free()
		objects = {}
				

func set_path(new_path):
	path = new_path
	shell.cd(new_path)
	for o in objects.values():
		o.queue_free()
	objects = {}
	update_everything()
	
func get_path():
	return path
	
func set_label(new_label):
	label = new_label
	if label_node:
		label_node.text = new_label
	
func update_index():
	index.text = git("ls-files -s --abbrev=8").replace("\t", " ")

func random_position():
	return Vector2(rand_range(0, rect_size.x), rand_range(0, rect_size.y))
		
func update_objects():
	var all = all_objects()
	
	# Create new objects, if necessary.
	for o in all:
		if objects.has(o):
			continue
			
		var type = object_type(o)
		if _simplified_view:
			if type == "tree" or type == "blob":
				continue
		
		var n = node.instance()
		n.id = o
		n.type = object_type(o)
		n.content = object_content(o)
		n.repository = self
	
		match type:
			"blob":
				pass
			"tree":
				n.children = tree_children(o)
				n.content = n.content.replacen("\t", " ")
			"commit":
				var c = {}
				c[commit_tree(o)] = ""
				for p in commit_parents(o):
					c[p] = ""
				n.children = c
			"tag":
				n.children = tag_target(o)
		
		n.position = find_position(n)
		nodes.add_child(n)
		objects[o] = n
	 
func update_refs():   
	for r in all_refs():
		if not objects.has(r):
			var n = node.instance()
			n.id = r
			n.type = "ref"
			n.content = ""
			n.repository = self
			objects[r] = n
			n.children = {ref_target(r): ""}
			n.position = find_position(n)
			nodes.add_child(n)
		var n = objects[r]
		n.children = {ref_target(r): ""}
	
func apply_forces():
	for o in objects.values():
		if not o.visible:
			continue
		for o2 in objects.values():
			if o == o2 or not o2.visible:
				continue
			var d = o.position.distance_to(o2.position)
			var dir = (o.global_position - o2.global_position).normalized()
			var f = 2000/pow(d+0.00001,1.5)
			o.position += dir*f
			o2.position -= dir*f
		var center_of_gravity = rect_size/2
		var d = o.position.distance_to(center_of_gravity)
		var dir = (o.position - center_of_gravity).normalized()
		var f = (d+0.00001)*Vector2(0.03, 0.01)
		o.position -= dir*f
	
func find_position(n):	
	var position = Vector2.ZERO
	var count = 0
	for child in n.children:
		if objects.has(child):
			position += objects[child].position
			count += 1
	if count > 0:
		position /= count
		n.position = position + Vector2(0, -150)
	else:
		n.position = random_position()
	return n.position

func git(args, splitlines = false):
	var o = shell.run("git --no-replace-objects " + args)
	
	if splitlines:
		o = o.split("\n")
		# Remove last empty line.
		o.remove(len(o)-1)
	else:
		# Remove trailing newline.
		o = o.substr(0,len(o)-1)
	return o

func update_head():
	if not objects.has("HEAD"):
		var n = node.instance()
		n.id = "HEAD"
		n.type = "head"
		n.content = ""
		n.repository = self
		n.position = find_position(n)
		   
		objects["HEAD"] = n
		nodes.add_child(n)
	var n = objects["HEAD"]
	n.children = {ref_target("HEAD"): ""}

func all_objects():
	var obj = git("cat-file --batch-check='%(objectname)' --batch-all-objects", true)
	var dict = {}
	for o in obj:
		dict[o] = ""
	return dict

func object_type(id):
	return git("cat-file -t "+id)

func object_content(id):
	return git("cat-file -p "+id)

func tree_children(id):
	var children = git("cat-file -p "+id, true)
	var ids = {}
	for c in children:
		var a = c.split(" ")
		ids[a[2].split("\t")[0]] = a[2].split("\t")[1]
	return ids

func commit_tree(id):
	var c = git("cat-file -p "+id, true)
	for cc in c:
		var ccc = cc.split(" ", 2)
		match ccc[0]:
			"tree":
				return ccc[1]
	return null

func commit_parents(id):
	var parents = []
	var c = git("cat-file -p "+id, true)
	for cc in c:
		var ccc = cc.split(" ", 2)
		match ccc[0]:
			"parent":
				parents.push_back(ccc[1])
	return parents

func tag_target(id):
	var c = git("rev-parse %s^{}" % id)
	return {c: ""}

func all_refs():
	var refs = {}
	# If there are no refs, show-ref will have exit code 1. We don't care.
	for line in git("show-ref || true", true):
		line = line.split(" ")
		var _id = line[0]
		var name = line[1]
		refs[name] = ""
	return refs
	
func ref_target(ref):
	# Test whether this is a symbolic ref.
	var ret = git("symbolic-ref -q "+ref+" || true")
	# If it's not, it's probably a regular ref.
	if ret == "":
		if ref == "HEAD":
			ret = git("show-ref --head "+ref).split(" ")[0]
		else:
			ret = git("show-ref "+ref).split(" ")[0]
	return ret


func simplify_view(pressed):
	_simplified_view = pressed

	for o in objects:
		var obj = objects[o]
		if obj.type == "tree" or obj.type == "blob":
			obj.visible = not pressed
	
	if there_is_a_git():
		update_objects()

func remove_gone_stuff():
	# FIXME: Cache the result of all_objects.
	var all = {}
	for o in all_objects():
		all[o] = ""
	for o in all_refs():
		all[o] = ""
	all["HEAD"] = ""
	# Delete objects, if they disappeared.
	for o in objects.keys():
		if not all.has(o):
			objects[o].queue_free()
			objects.erase(o)

func _on_mouse_entered():
	mouse_inside = true

func _on_mouse_exited():
	mouse_inside = false
	
func set_file_browser_active(active):
	file_browser_active = active
	if file_browser:
		file_browser.visible = active
		

