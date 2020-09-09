name = "git-hydra"

all: linux macos windows web

linux:
	mkdir -p /tmp/$(name)-linux
	/usr/bin/godot --export "Linux" "/tmp/$(name)-linux/$(name)"
	zip -r /tmp/$(name)-linux.zip /tmp/$(name)-linux

macos:
	/usr/bin/godot --export "Mac OS" "/tmp/$(name)-macos.app"
	mv "/tmp/$(name)-macos.app" "/tmp/$(name)-macos.zip"

windows: dependencies/windows/git/
	mkdir -p /tmp/$(name)-windows
	/usr/bin/godot --export "Windows" "/tmp/$(name)-windows/$(name).exe"
	cp -r --parents dependencies/windows/git/ /tmp/$(name)-windows/
	zip -r /tmp/$(name)-windows.zip /tmp/$(name)-windows

web:
	mkdir -p /tmp/$(name)-web
	/usr/bin/godot --export "HTML5" "/tmp/$(name)-web/index.html"
	zip -r /tmp/$(name)-web.zip /tmp/$(name)-web

# Dependencies:

cache/portablegit.7z.exe:
	wget https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/PortableGit-2.28.0-64-bit.7z.exe -O cache/portablegit.7z.exe

dependencies/windows/git/: cache/portablegit.7z.exe
	wine cache/portablegit.7z.exe -o dependencies/windows/git/ -y
