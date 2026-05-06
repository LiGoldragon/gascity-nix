# Risk note — 2026-05-06 gascity-nix pin

## Patch risk

This patch changes the gascity source pointer from `gascity 881f57bd`
to `gascity 4e994724`. The new pin keeps the prior managed idle sleep,
session wake metadata, managed bd SQL `issue_prefix`, dirty wake metadata,
explicit wake-claim fixes, and stale managed builtin-pack pruning. It also
disables the daemon-only Dolt compactor order and suppresses cached no-op
metadata writes before they reach `bd update`.

The main breakage risk is a packaging mismatch: source hash drift,
Go vendor hash drift, or a runtime assumption in the newer gascity
commit that is not represented in this packaging flake.

## Coverage

`test-city` and the live Criopolis repair loop validated the source-built
candidate before this packaging pin moved:

- Criopolis exposed a stale `order-tracking-sweep` system-pack projection
  whose command no longer exists in current Gas City; `881f57bd` added
  pruning for those stale managed files.
- Criopolis then exposed `mol-dog-compactor` being poured as dog work even
  though its formula says a daemon must execute it. `4e994724` disables that
  built-in order.
- Criopolis also showed two live session beads being rewritten every few
  seconds with unchanged metadata, keeping Dolt hot while idle. `4e994724`
  adds CachingStore no-op guards and regression tests for identical metadata
  writes.

This repository must still build after the pin update, and
`./result/bin/gc version --long` must report
`4e9947249320618b8a2a1d94d13e8a2715360d5a`.

Targeted verification passed in the gascity worktree:

- `GC_FAST_UNIT=1 go test ./internal/beads -run 'TestCachingStoreSetMetadata'`
- `GC_FAST_UNIT=1 go test ./cmd/gc -run 'TestMaterializedBuiltinPackOrdersScanWithoutWarnings|TestMaterializeBuiltinPacks_PrunesStaleManagedFiles'`

## Cross-repo effects

`CriomOS-home` consumes this repository as the `gascity` flake input.
That lockfile must point at the new `gascity-nix` commit before the
home profile receives the newer `gc` binary.

## Reviewer focus

Review `flake.nix` first: the `rev`, source `hash`, and `ldflags`
commit value are the load-bearing pieces.
