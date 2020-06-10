extends Node2D

var node = preload("res://node.tscn")

var objects = {}

var dragged = null

var viewport_size

func _ready():
    viewport_size = get_viewport_rect().size

func _process(delta):
    if true or get_global_mouse_position().x < get_viewport_rect().size.x*0.7:
        if Input.is_action_just_pressed("click"):
            var mindist = 9999999
            for o in objects.values():
                var d = o.position.distance_to(get_global_mouse_position())
                if d < mindist:
                    mindist = d
                    dragged = o
        if Input.is_action_just_released("click"):
                dragged = null
        if dragged:
            dragged.position = get_global_mouse_position()
    
    update_head()
    update_refs()
    update_index()
    update_objects()
    apply_forces()
    
func update_index():
    $Index.text = git("ls-files")
        
func update_objects():
    for o in all_objects():
        if objects.has(o):
            continue
        var n = node.instance()
        n.id = o
        n.type = object_type(o)
        n.content = object_content(o)
        n.position = Vector2(rand_range(0, viewport_size.x), rand_range(0, viewport_size.y))
    
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
            n.position = Vector2(rand_range(0, viewport_size.x), rand_range(0, viewport_size.y))
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
        var d = o.position.distance_to(Vector2(viewport_size.x/3, viewport_size.y/2))
        var dir = (o.global_position - Vector2(viewport_size.x/3, viewport_size.y/2)).normalized()
        var f = (d+0.00001)*0.02
        o.position -= dir*f

func git(args, splitlines = false):
    var output = []
    var a = args.split(" ")
    #print ("Running: ", a)
    a.insert(0, "-C")
    a.insert(1, "/home/seb/tmp/godotgit")
    OS.execute("git", a, true, output, true)
    var o = output[0]
    if splitlines:
        o = o.split("\n")
        o.remove(len(o)-1)
    else:
        o = o.substr(0,len(o)-1)
    return o

func update_head():
    if not objects.has("HEAD"):
        var n = node.instance()
        n.id = "HEAD"
        n.type = "head"
        n.content = ""
        n.position = Vector2(rand_range(0, viewport_size.x), rand_range(0, viewport_size.y))   
        objects["HEAD"] = n
        add_child(n)
        
        n = node.instance()
        n.id = "refs/heads/master"
        n.type = "ref"
        n.content = ""
        n.position = Vector2(rand_range(0, viewport_size.x), rand_range(0, viewport_size.y))
        objects[n.id] = n
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
