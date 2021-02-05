name = "oh-my-git"

all: linux macos windows

linux:
	mkdir -p build/$(name)-linux
	godot --export "Linux" "build/$(name)-linux/$(name)"
	cd build/$(name)-linux && zip -r ../$(name)-linux.zip *

macos:
	mkdir -p build
	godot --export "Mac OS" "build/$(name)-macos.zip"

windows: dependencies/windows/git/
	mkdir -p build/$(name)-windows
	# We're using the debug template here so that the bash.exe doesn't spawn a cmd.exe each time...
	godot --export-debug "Windows" "build/$(name)-windows/$(name).exe"
	cp -r --parents dependencies/windows/git/ build/$(name)-windows/
	cd build/$(name)-windows && zip -r ../$(name)-windows.zip *

clean-unzipped:
	cd build && ls | grep -v '\.zip$$' | xargs rm -r

clean:
	rm -rf build dependencies cache

# Dependencies:

cache/portablegit.7z.exe:
	mkdir -p cache
	wget https://github.com/git-for-windows/git/releases/download/v2.28.0.windows.1/PortableGit-2.28.0-64-bit.7z.exe -O cache/portablegit.7z.exe

dependencies/windows/git/: cache/portablegit.7z.exe
	7zr x cache/portablegit.7z.exe -odependencies/windows/git/ -y
