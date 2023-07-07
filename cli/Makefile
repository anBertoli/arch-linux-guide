
.PHONY: build-cli
build-cli:
	mkdir -p bin
	cargo build --release
	cp ./target/release/arch-cli ./bin/arch-cli

.PHONY: install-cli
install-cli:
	cargo install --path .

.PHONY: gen-docs
gen-docs: build-cli
	./bin/arch-cli \
 		--source-dir ../01_arch_linux_installation/chapters \
		gen --file ../01_arch_linux_installation/README.md \
	  	--replace ../../01_arch_linux_installation#../01_arch_linux_installation	\
	  	--verbose --force

	 ./bin/arch-cli \
 		--source-dir ../02_linux_handbook/chapters \
		gen --file ../02_linux_handbook/README.md \
		--replace ../../02_linux_handbook#../02_linux_handbook	\
		--verbose --force

	#./bin/arch-cli \
# 		--source-dir ../01_arch_linux_installation/chapters \
# 		--source-dir ../02_linux_handbook/chapters \
#		gen --file ../README.md \
#		--replace ../../01_arch_linux_installation#./01_arch_linux_installation \
#		--replace ../../02_linux_handbook#./02_linux_handbook	\
#		--verbose --force

.PHONY: clean
clean:
	rm -rf ./target
	rm -rf ./bin