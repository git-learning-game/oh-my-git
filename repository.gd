extends Node2D

export var path: String setget set_path, get_path
export var size: Vector2
var objects = {}
var node = preload("res://node.tscn")

func _ready():
	pass

func _process(delta):
	if path:
		update_head()
		update_refs()
		update_index()
		update_objects()
		apply_forces()

func set_path(new_path):
	path = new_path
	
func get_path():
	return path
	
func update_index():
	$Index.text = git("ls-files")

func random_position():
	return Vector2(rand_range(0, size.x), rand_range(0, size.y))
		
func update_objects():
	for o in all_objects():
		if objects.has(o):
			continue
		var n = node.instance()
		n.id = o
		n.type = object_type(o)
		n.content = object_content(o)
		n.position = random_position()
		n.repository = self
	
		if true:
			#print(" ")
			#print(o)
			var type = object_type(o)
			#print(type)
			#print(object_content(o))
			match type:
				"blob":
					pass
				"tree":
					#print("Children:")
					#print(tree_children(o))
					n.children = tree_children(o)
				"commit":
					#print("Tree:")
					#print(commit_tree(o))
					
					#print("Parents:")
					#print(commit_parents(o))
					
					var c = {}
					c[commit_tree(o)] = ""
					for p in commit_parents(o):
						c[p] = ""
					n.children = c
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
			n.position = random_position()
			objects[r] = n
			add_child(n)
		var n = objects[r]
		n.children = {ref_id(r): ""}
	
func apply_forces():
	for o in objects.values():
		for o2 in objects.values():
			if o == o2:
				continue
			var d = o.position.distance_to(o2.position)
			var dir = (o.global_position - o2.global_position).normalized()
			var f = 3000/pow(d+0.00001,1.5)
			o.position += dir*f
			o2.position -= dir*f
		var d = o.position.distance_to(Vector2(size.x/2, size.y/2))
		var dir = (o.position - Vector2(size.x/2, size.y/2)).normalized()
		var f = (d+0.00001)*0.02
		o.position -= dir*f

func git(args, splitlines = false):
	var output = []
	var a = args.split(" ")
	#print ("Running: ", a)
	a.insert(0, "-C")
	a.insert(1, path)
	OS.execute("git", a, true, output, true)
	var o = output[0]
	
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
		n.position = random_position()   
		objects["HEAD"] = n
		add_child(n)
	var n = objects["HEAD"]
	n.children = {symref_target("HEAD"): ""}

func all_objects():
	return git("cat-file --batch-check=%(objectname) --batch-all-objects", true)

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

func all_refs():
	var refs = []
	for line in git("show-ref", true):
		line = line.split(" ")
		var id = line[0]
		var name = line[1]
		refs.push_back(name)
	return refs
	
func ref_id(ref):
	return git("show-ref "+ref).split(" ")[0]

func symref_target(symref):
	var ret = git("symbolic-ref -q "+symref)
	if ret != "":
		return ret
	return git("show-ref --head "+symref).split(" ")[0]
