#CONFIG_OPTS = -v
all: build

build:
	swift build $(CONFIG_OPTS)

release:
	swift build --configuration release $(CONFIG_OPTS)

test:
	swift test $(CONFIG_OPTS)

runtest:
	swift test --skip-build

docs:
	swift package generate-xcodeproj

clean:
	swift package clean

.PHONY: build release test runtest docs clean
