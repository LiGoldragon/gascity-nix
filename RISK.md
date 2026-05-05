# Risk note — cr-ygc4tl gascity-nix pin

## Patch risk

This patch changes the gascity source pointer from `gascity 992807e3`
(session sleep managed default) to `gascity a720d067` (session wake
metadata no-op suppression). Consumers of `gascity-nix` will build the
newer `gc` binary once their flake locks point at this commit.

The main breakage risk is a packaging mismatch: source hash drift,
Go vendor hash drift, or a runtime assumption in the newer gascity
commit that is not represented in this packaging flake. The `gc`
binary also carries the same version string as the prior 2026-05-05
pin, so operators should use `gc version --long` when verifying the
exact commit.

## Coverage

`nix build .#default --refresh` succeeds for the updated source pin.
`./result/bin/gc version --long` reports
`a720d067c0fcc9b77054222da5be6fac98091217`.

## Cross-repo effects

`CriomOS-home` consumes this repository as the `gascity` flake input.
That lockfile must point at the new `gascity-nix` commit before the
home profile receives the newer `gc` binary.

## Reviewer focus

Review `flake.nix` first: the `rev`, source `hash`, and `ldflags`
commit value are the load-bearing pieces.
