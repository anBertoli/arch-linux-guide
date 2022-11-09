
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
	 ./bin/arch-cli ../01_arch_linux_installation/chapters gen \
 		--file ../README.md \
	 	--verbose \
	 	--force

.PHONY: clean
clean:
	rm -rf ./target
	rm -rf ./bin