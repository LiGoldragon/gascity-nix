# Risk note — 2026-05-06 gascity-nix pin

## Patch risk

This patch changes the gascity source pointer from `gascity 5b14365c`
to `gascity 0bc6e585`. The new pin keeps the prior stale managed
builtin-pack pruning, daemon-only Dolt compactor disablement, and cached
metadata no-op guard. It adds session reconciliation fixes for already-clear
wake failure metadata, pending-create in-flight accounting, and immediate
retry of stopped pending-create sessions.

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
  added CachingStore no-op guards; `5b14365c` adds the direct
  `clearWakeFailures` guard and regression coverage for the reconciler path
  that was still writing the already-clear metadata.
- The same repair loop exposed pool workers being left around until stale
  cleanup after work drained. `5b14365c` also carries pending-create
  in-flight accounting so the reconciler does not mint duplicate pool
  sessions while startup is still inside its timeout window.
- Restarting Criopolis with that throttle exposed a follow-up delay: mayor
  was left `state=stopped` with `pending_create_claim=true` and was retried
  only after the full startup timeout. `0bc6e585` narrows the throttle to
  actual `state=creating` beads so stopped claims retry on the next tick.

This repository must still build after the pin update, and
`./result/bin/gc version --long` must report
`0bc6e58522eacdf3da7f2567724d97c9ab7b4ad7`.

Targeted verification passed in the gascity worktree:

- `GC_FAST_UNIT=1 go test ./internal/beads -run 'TestCachingStoreSetMetadata'`
- `GC_FAST_UNIT=1 go test ./cmd/gc -run 'TestMaterializedBuiltinPackOrdersScanWithoutWarnings|TestMaterializeBuiltinPacks_PrunesStaleManagedFiles'`
- `GC_FAST_UNIT=1 go test ./cmd/gc -run 'TestCityRuntimeFullReconcileLoop_DoesNotMintPoolSessionWhilePendingCreateInFlight|TestComputePoolDesiredStates_InFlightCreateThrottlesNewScaleRequests|TestComputePoolDesiredStates_InFlightCreateKeepsActiveAndAddsNoNew|TestClearWakeFailuresSkipsAlreadyClearMetadata|TestReconcileSessionBeads_PendingCreateStartAttemptWaitsForStartupTimeout|TestReconcileSessionBeads_PendingCreateRetriesAfterStartupTimeout|TestReconcileSessionBeads_DrainAckHonoredAfterSessionExit'`
- `GC_FAST_UNIT=1 go test ./cmd/gc -run 'TestPendingCreateStartInFlightRequiresCreatingState|TestReconcileSessionBeads_PendingCreateStartAttemptWaitsForStartupTimeout|TestReconcileSessionBeads_PendingCreateRetriesAfterStartupTimeout'`

`GC_FAST_UNIT=1 go test ./cmd/gc ./internal/session ./internal/beads` also
passed `internal/session` and `internal/beads`, but `cmd/gc` hit its
10-minute package timeout in unrelated long-running controller/mail/Dolt
tests. Treat the targeted regression run above as the commit gate for this
pin.

## Cross-repo effects

`CriomOS-home` consumes this repository as the `gascity` flake input.
That lockfile must point at the new `gascity-nix` commit before the
home profile receives the newer `gc` binary.

## Reviewer focus

Review `flake.nix` first: the `rev`, source `hash`, and `ldflags`
commit value are the load-bearing pieces.
