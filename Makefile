ifeq "$(PLATFORM)" ""
PLATFORM := $(shell uname)
endif

ifeq "$(PLATFORM)" "Darwin"
BUILDCOMMAND := "swift build -Xcc -fblocks -Xswiftc -I/usr/local/include -Xlinker -L/usr/local/lib"
else
BUILDCOMMAND := "swift build -Xcc -fblocks"
endif

fetch:
	swift package fetch
build: fetch clean
	@echo --- Building package
	"$(BUILDCOMMAND)"
test: build
	@echo --- Running tests
	swift test
clean:
	@echo --- Invoking swift build --clean
	swift build --clean
