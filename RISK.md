# Risk note — 2026-05-06 gascity-nix pin

## Patch risk

This patch changes the gascity source pointer from `gascity 6073275`
to `gascity 881f57bd`. The new pin keeps the prior managed idle sleep,
session wake metadata, managed bd SQL `issue_prefix`, dirty wake metadata,
and explicit wake-claim fixes. It adds pruning for stale managed builtin
pack projections so removed bundled orders cannot remain active in an
already-started city.

The main breakage risk is a packaging mismatch: source hash drift,
Go vendor hash drift, or a runtime assumption in the newer gascity
commit that is not represented in this packaging flake.

## Coverage

`test-city` and the live Criopolis repair loop validated the source-built
candidate before this packaging pin moved:

- Gas City commit `60732751665b4c70685f06a425febbe96eeb6286` passed the
  prior idle source and Nix package dolt-amp lanes.
- Criopolis exposed a stale `order-tracking-sweep` system-pack projection
  whose command no longer exists in current Gas City.
- Removing that stale projection stopped fresh `order-tracking-sweep`
  failures; `gc doctor --verbose` then reported 39 passed.
- Gas City commit `881f57bd5cc8d927ca1dcc1e5e5c1b036246ff8a` adds a
  regression test for pruning stale managed builtin files.

This repository must still build after the pin update, and
`./result/bin/gc version --long` must report
`881f57bd5cc8d927ca1dcc1e5e5c1b036246ff8a`.

Verification caveat: the targeted `go test ./cmd/gc -run
'TestMaterializeBuiltinPacks'` passed in the gascity worktree. A broader
`go test ./cmd/gc` run hit the package timeout in an existing bd recovery
status path, not in the builtin-pack materialization tests.

## Cross-repo effects

`CriomOS-home` consumes this repository as the `gascity` flake input.
That lockfile must point at the new `gascity-nix` commit before the
home profile receives the newer `gc` binary.

## Reviewer focus

Review `flake.nix` first: the `rev`, source `hash`, and `ldflags`
commit value are the load-bearing pieces.
