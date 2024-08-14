build-vm:
	nix build "./.#nixosConfigurations.test.config.system.build.vm"

run-vm: build-vm
	./result/bin/run-nixos-vm
