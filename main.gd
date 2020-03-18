extends Node2D

var node = preload("res://node.tscn")

var objects = {}

func _ready():
    for o in all_objects():
        var n = node.instance()
        n.id = o
        n.type = object_type(o)
        n.content = object_content(o)
        var viewport_size = get_viewport_rect().size
        n.position = Vector2(rand_range(0, viewport_size.x), rand_range(0, viewport_size.y))
     
        print(" ")
        print(o)
        var type = object_type(o)
        print(type)
        #print(object_content(o))
        match type:
            "blob":
                pass
            "tree":
                print("Children:")
                print(tree_children(o))
                n.children = tree_children(o)
            "commit":
                print("Tree:")
                print(commit_tree(o))
                
                print("Parents:")
                print(commit_parents(o))
                
                n.children = [commit_tree(o)] + commit_parents(o)
        add_child(n)
        objects[o] = n

func git(args, splitlines = false):
    var output = []
    var a = args.split(" ")
    a.insert(0, "-C")
    a.insert(1, "/home/seb/tmp/godotgit")
    #print ("Running: ", a)
    OS.execute("git", a, true, output, true)
    var o = output[0]
    if splitlines:
        o = o.split("\n")
        o.remove(len(o)-1)
    else:
        o = o.substr(0,len(o)-1)
    return o

func all_objects():
    return git("cat-file --batch-check=%(objectname) --batch-all-objects", true)

func object_type(id):
    return git("cat-file -t "+id)

func object_content(id):
    return git("cat-file -p "+id)

func tree_children(id):
    var children = git("cat-file -p "+id, true)
    var ids = []
    for c in children:
        var a = c.split(" ")
        ids.push_back(a[2].split("\t")[0])
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
