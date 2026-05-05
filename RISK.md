# Risk note — 2026-05-06 gascity-nix pin

## Patch risk

This patch changes the gascity source pointer from `gascity a720d067`
to `gascity 6462edf3`. The new pin keeps the prior managed idle sleep
and session wake metadata fixes, adds the managed bd SQL `issue_prefix`
repair, and dirty-checks stable-session wake-failure metadata before
writing it.

The main breakage risk is a packaging mismatch: source hash drift,
Go vendor hash drift, or a runtime assumption in the newer gascity
commit that is not represented in this packaging flake.

## Coverage

`test-city` validated the source-built candidate before this packaging
pin moved:

- `nix run .#run-idle-gascity-dolt-amp-source`
- Gas City commit `6462edf36cefa88bde03f19439173a3bc821a708`
- canonical-stock, five-minute idle window
- Dolt commit count reached 14 after startup and remained 14 through the
  final sample.

This repository must still build after the pin update, and
`./result/bin/gc version --long` must report
`6462edf36cefa88bde03f19439173a3bc821a708`.

## Cross-repo effects

`CriomOS-home` consumes this repository as the `gascity` flake input.
That lockfile must point at the new `gascity-nix` commit before the
home profile receives the newer `gc` binary.

## Reviewer focus

Review `flake.nix` first: the `rev`, source `hash`, and `ldflags`
commit value are the load-bearing pieces.
