.PHONY: run-vm # nix build will handle caching builds based on files already
run-vm:
	nix build "./.#nixosConfigurations.test.config.system.build.vm"
	./result/bin/run-nixos-vm
