extends Control

onready var nodes = $Rows/RepoVis/Nodes
onready var label_node = $Rows/RepoVis/Label
onready var path_node = $Rows/RepoVis/Path
onready var simplify_checkbox = $Rows/RepoVis/SimplifyCheckbox

export var label: String setget set_label
export var path: String setget set_path, get_path
export var simplified_view = true setget set_simplified_view
export var editable_path = false setget set_editable_path

var type = "remote"

var node = preload("res://scenes/node.tscn")

var shell = game.new_shell()
var objects = {}
var mouse_inside = false
var has_been_layouted = false

# Used for caching.
var all_objects_cache
var all_refs_cache
var there_is_a_git_cache

# We use this for a heuristic of when to hide trees and blobs.
var _commit_count = 0

func _ready():
	# Trigger these again because nodes were not ready before.
	set_label(label)
	set_simplified_view(simplified_view)
	set_editable_path(editable_path)
	set_path(path)
	
	#update_everything()
	#update_node_positions()

func _process(_delta):
	nodes.rect_pivot_offset = nodes.rect_size / 2
	if path:
		apply_forces()
		
func _unhandled_input(event):
	if event.is_action_pressed("zoom_out") and nodes.rect_scale.x > 0.3:
		nodes.rect_scale -= Vector2(0.05, 0.05)
	if event.is_action_pressed("zoom_in") and nodes.rect_scale.x < 2:
		nodes.rect_scale += Vector2(0.05, 0.05)

func there_is_a_git():
	return shell.run("test -d .git && echo yes || echo no") == "yes\n"
	
func update_everything():
	there_is_a_git_cache = there_is_a_git()
	if there_is_a_git_cache:
		update_head()
		update_refs()
		update_objects()
		remove_gone_stuff()
	else:
		for o in objects:
			objects[o].queue_free()
		objects = {}
	if not has_been_layouted:
		update_node_positions()
		has_been_layouted = true

func set_path(new_path):
	path = new_path
	if path_node:
		path_node.text = path
	if new_path != "":
		shell.cd(new_path)
		for o in objects.values():
			o.queue_free()
		objects = {}
#		if is_inside_tree():
#			update_everything()
	
func get_path():
	return path
	
func set_label(new_label):
	label = new_label
	if label_node:
		if new_label == "yours":
			new_label = ""
			$Rows/RepoVis/SeparatorLine/DropArea.queue_free()
			$Rows/RepoVis/SeparatorLine.hide()
		else:
			game.notify("This is the time machine of another person! To interact with it, you need special commands!", self, "remote")
		label_node.text = new_label

func random_position():
	return Vector2(rand_range(0, rect_size.x), rand_range(0, rect_size.y))
		
func update_objects():
	all_objects_cache = all_objects()
	
	# Create new objects, if necessary.
	for o in all_objects_cache:
		if objects.has(o):
			continue
			
		var type = object_type(o)

		if simplified_view:
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
				#c[commit_tree(o)] = ""
				for p in commit_parents(o):
					c[p] = ""
				n.children = c
				
				_commit_count += 1
#				if _commit_count >= 3 and not simplified_view:
#					set_simplified_view(true)
			"tag":
				n.children = tag_target(o)
		
		n.position = find_position(n)
		nodes.add_child(n)
		objects[o] = n
		
func update_node_positions():
	if there_is_a_git_cache:
		var graph_text = shell.run("git log --graph --oneline --all --no-abbrev")
		var graph_lines = Array(graph_text.split("\n"))
		graph_lines.pop_back()
		
		for line_count in range(graph_lines.size()):
			var line = graph_lines[line_count]
			if "*" in line:
				var star_idx = line.find("*")
				var hash_regex = RegEx.new()
				hash_regex.compile("[a-f0-9]+")
				var regex_match = hash_regex.search(line)
				objects[regex_match.get_string()].position = Vector2((graph_lines.size()-line_count) * 100 + 500, star_idx * 100 + 500)
				
		for ref in all_refs_cache:
			var target_reference = objects[ref].children.keys()[0]
			var target = objects[target_reference]
			objects[ref].position = Vector2(target.position.x ,target.position.y - 100)
			
		var target_reference = objects["HEAD"].children.keys()[0]
		if objects.has(target_reference):
			var target = objects[target_reference]
			objects["HEAD"].position = Vector2(target.position.x ,target.position.y - 100)
	 
func update_refs():
	all_refs_cache = all_refs()
	for r in all_refs_cache:
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
		if o.type == "head" and o.children.size() > 0 and  objects.has(o.children.keys()[0]):
			continue
		for o2 in objects.values():
			if o == o2 or not o2.visible or o2.type == "head":
				continue
			var d = o.position.distance_to(o2.position)
			var dir = (o.global_position - o2.global_position).normalized()
			var f = 2000/pow(d+0.00001,1.5)
			o.position += dir*f
			o2.position -= dir*f
		var center_of_gravity = nodes.rect_size/2
		var d = o.position.distance_to(center_of_gravity)
		var dir = (o.position - center_of_gravity).normalized()
		var f = (d+0.00001)*(Vector2(nodes.rect_size.y/10, nodes.rect_size.x/3).normalized()/30)
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
	#var obj = git("cat-file --batch-check='%(objectname)' --batch-all-objects", true)
	var obj = git("cat-file --batch-check='%(objectname) %(objecttype)' --batch-all-objects | grep '\\(tag\\|commit\\)$' | cut -f1 -d' '", true)
	var dict = {}
	for o in obj:
		dict[o] = ""
	return dict

func object_type(id):
	return git("cat-file -t "+id)

func object_content(id):
	#return git("cat-file -p "+id)
	return git("show -s --format=%B "+id).strip_edges()

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

func set_simplified_view(simplify):
	simplified_view = simplify
	if simplify_checkbox:
		simplify_checkbox.pressed = simplify
		
	for o in objects:
		var obj = objects[o]
		if obj.type == "tree" or obj.type == "blob":
			obj.visible = not simplify

func set_editable_path(editable):
	editable_path = editable
	if label_node:
		label_node.visible = not editable
	if path_node:
		path_node.visible = editable

func remove_gone_stuff():
	var all = {}
	for o in all_objects_cache:
		all[o] = ""
	for o in all_refs_cache:
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
