name = "git-hydra"

all: linux macos windows web

linux:
	mkdir -p /tmp/$(name)-linux
	/usr/bin/godot --export "Linux" "/tmp/$(name)-linux/$(name)"
	zip -r /tmp/$(name)-linux.zip /tmp/$(name)-linux
	#rm -r /tmp/$(name)-linux

macos:
	/usr/bin/godot --export "Mac OS" "/tmp/$(name)-macos.app"
	mv "/tmp/$(name)-macos.app" "/tmp/$(name)-macos.zip"

windows:
	mkdir -p /tmp/$(name)-windows
	/usr/bin/godot --export "Windows" "/tmp/$(name)-windows/$(name).exe"
	zip -r /tmp/$(name)-windows.zip /tmp/$(name)-windows
	#rm -r /tmp/$(name)-windows

web:
	mkdir -p /tmp/$(name)-web
	/usr/bin/godot --export "HTML5" "/tmp/$(name)-web/index.html"
	zip -r /tmp/$(name)-web.zip /tmp/$(name)-web
	#rm -r /tmp/$(name)-web
