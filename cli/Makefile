
.PHONY: build-cli
build-cli:
	mkdir -p bin
	cargo build --release
	cp ./target/release/arch-cli ./bin/arch-cli

.PHONY: install-cli
install-cli:
	cargo install --path .

.PHONY: gen-doc
gen-doc: build-cli
	 ./bin/arch-cli \
 		--source-dir ../01_arch_linux_installation/chapters \
 		--source-dir ../02_linux_handbook/chapters \
		gen --file ../README.md --verbose --force

.PHONY: clean
clean:
	rm -rf ./target
	rm -rf ./bin