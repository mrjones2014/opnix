run-vm:
	nix build "./.#nixosConfigurations.test.config.system.build.vm"
	./result/bin/run-nixos-vm
