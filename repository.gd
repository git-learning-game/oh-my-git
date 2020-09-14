extends Container

export var label: String setget set_label
export var path: String setget set_path, get_path

var node = preload("res://node.tscn")

var shell = Shell.new()
var objects = {}

func _ready():
	pass

func _process(_delta):
	if path:
		apply_forces()
		
func update_everything():
	update_head()
	update_refs()
	update_index()
	update_objects()

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
	$Label.text = new_label
	
func update_index():
	$Index.text = git("ls-files")

func random_position():
	return Vector2(rand_range(0, rect_size.x), rand_range(0, rect_size.y))
		
func update_objects():
	for o in all_objects():
		if objects.has(o):
			continue
		var n = node.instance()
		n.id = o
		n.type = object_type(o)
		n.content = object_content(o)
		n.repository = self
	
		if true:
			var type = object_type(o)
			match type:
				"blob":
					pass
				"tree":
					n.children = tree_children(o)
				"commit":
					var c = {}
					c[commit_tree(o)] = ""
					for p in commit_parents(o):
						c[p] = ""
					n.children = c
				"tag":
					print("tag")
					n.children = tag_target(o)
		
		n.position = find_position(n)
		add_child(n)
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
			add_child(n)
		var n = objects[r]
		n.children = {ref_target(r): ""}
	
func apply_forces():
	for o in objects.values():
		for o2 in objects.values():
			if o == o2:
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
		print(count)
		position /= count
		n.position = position + Vector2(0, -150)
	else:
		n.position = random_position()
	return n.position

func git(args, splitlines = false):
	var o = shell.run("git " + args)
	
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
		add_child(n)
	var n = objects["HEAD"]
	n.children = {ref_target("HEAD"): ""}

func all_objects():
	return git("cat-file --batch-check='%(objectname)' --batch-all-objects", true)

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
	var refs = []
	# If there are no refs, show-ref will have exit code 1. We don't care.
	for line in git("show-ref || true", true):
		line = line.split(" ")
		var _id = line[0]
		var name = line[1]
		refs.push_back(name)
	return refs
	
func ref_target(ref):
	# Test whether this is a symbolic ref.
	var ret = git("symbolic-ref -q "+ref+" || true")
	# If it's not, it's probably a regular ref.
	if ret == "":
		ret = git("show-ref "+ref).split(" ")[0]
	return ret
