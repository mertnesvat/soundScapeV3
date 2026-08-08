# Handoff — SoundScapeV3 Architectural Deepening Refactor

**For a fresh Claude session picking up this work.**

## Where this is in the pipeline

The user invoked `/goal` from DriftCode (`/Users/mert/Developer/AI-Experiments/DriftCode`) to refactor `/Users/mert/Developer/AI-Experiments/GenProjects/soundScapeV3` using `drift plan → execute → pr`.

Status:
- [x] Five parallel research agents completed; docs in `docs/research/`
- [x] Coding principles + 6-phase refactor plan synthesized in `docs/REFACTOR_BRIEF.md`
- [x] User confirmed scope: Phase 0 first, then auto-chain through Phases 1-5
- [x] **Phase 0 complete and shipped** — slug `wake-xctest-target`, PR **#64**, all 3 issues green, final verifier `test: pass (exit 0, 44229ms)`
- [ ] **Awaiting Phase 0 merge before Phase 1 can start** (Phase 1's verifier loop depends on Phase 0's `drift.config.yaml` change being on master)
- [ ] Continue with Phase 1 (`inline-shallow-modules`) once Phase 0 is merged

## Phase 0 outcome (2026-05-18)

- Branch: `drift/wake-xctest-target` (pushed to origin)
- PR: https://github.com/mertnesvat/soundScapeV3/pull/64
- Files changed: only `SoundScape/SoundScape.xcodeproj/xcshareddata/xcschemes/SoundScape.xcscheme` and `drift.config.yaml`
- Tests now running: `FavoritesServiceTests`, `AlarmTests`, `SleepContentTests`, `SleepRecordingTests`, `SoundRepositoryTests`
- The memory note `project_soundscape_test_step_environmental.md` has been rewritten to reflect the new reality.

## Continuing the chain

After merging PR #64 to master, kick off Phase 1 with this intent (truncated — full text in `REFACTOR_BRIEF.md` Part 2, Phase 1):

```bash
cd /Users/mert/Developer/AI-Experiments/DriftCode

bun run src/cli.tsx plan /Users/mert/Developer/AI-Experiments/GenProjects/soundScapeV3 --auto --intent "$(cat <<'EOF'
Phase 1 of the soundScapeV3 architectural deepening refactor: inline shallow modules.

Reference: docs/REFACTOR_BRIEF.md (Phase 1) and docs/research/shallow-modules-deletion-test.md for deletion-test reasoning.

Targets (each is a separate issue):
1. Inline SoundRepository + SoundRepositoryProtocol. Update SoundsViewModel to use LocalSoundDataSource directly.
2. Replace AppearanceService with @AppStorage("oled_mode_enabled") at consumers. Delete the service file.
3. Convert LocalSoundDataSource, LocalCommunityDataSource, LocalStoryDataSource to bundle JSON. Decode once into immutable arrays.
4. Collapse ReviewPromptService.recordSuccessfulSleepSession() / recordMixSaved() / recordFavoriteAction() into one recordPositiveAction(source:) method. Remove markAsDeclined() no-op. Fix YOUR_APP_STORE_ID placeholder.
5. Delete SavedMixRowView.swift (dead code).
6. SoundsViewModel: inline into SoundsView (preferred), or deepen by giving it real state.

Out of scope: no protocol introductions (Phase 3+4), no new use cases (Phase 2), no view restyling (Phase 5), no AudioEngine changes.

Acceptance: xcodebuild test exits 0 (5 scoped tests stay green), xcodebuild build exits 0, file count under SoundScape/Sources/ reduced by >=4.
EOF
)"
```

## Key docs (read in this order)

1. `docs/REFACTOR_BRIEF.md` — synthesized principles + phased plan + drift intent
2. `docs/research/testability-gaps.md` — Phase 0 lives or dies on this (one XML block fix)
3. `docs/research/architecture-layer-compliance.md` — Phases 2 and 3
4. `docs/research/state-and-coupling.md` — Phases 3 and 4 (god class, two composition roots)
5. `docs/research/shallow-modules-deletion-test.md` — Phase 1 deletions
6. `docs/research/view-layer-quality.md` — Phase 5 component extraction

## Decision points still open (ask the user)

1. **Start with Phase 0?** Recommended. It's the smallest possible plan (one `.xcscheme` XML edit) and unlocks the verifier loop for every subsequent phase. Alternative: combine Phases 0+1 if user wants fewer PRs.
2. **One mega-plan or phased plans?** Recommendation: phased. Each phase ends in a green build; reviewer cycles stay focused. DriftCode's verifier is more reliable on narrow scope.
3. **Touch `ServiceContainer.shared` (App Intents) in this run?** This is the cross-process refactor in Phase 3. Risk: Siri/Shortcuts breakage on next user query. Mitigation: Phase 3 ships with manual Siri smoke test in acceptance criteria.

## How to resume

```bash
cd /Users/mert/Developer/AI-Experiments/DriftCode

# Confirm drift is on the right base branch
cat /Users/mert/Developer/AI-Experiments/GenProjects/soundScapeV3/drift.config.yaml
# base_branch should be master; verify origin/HEAD agrees:
cd /Users/mert/Developer/AI-Experiments/GenProjects/soundScapeV3 && git remote show origin | grep "HEAD branch"
cd /Users/mert/Developer/AI-Experiments/DriftCode

# Phase 0 — wake the test target
bun run drift plan soundScapeV3 --auto --intent "$(cat <<'EOF'
Phase 0 of the soundScapeV3 architectural deepening refactor: wake the dormant XCTest target.

The codebase has 23 XCTest files in SoundScape/Tests/ that are fully wired in
project.pbxproj (TEST_HOST and BUNDLE_LOADER set correctly), but xcodebuild test
aborts because SoundScape.xcscheme's <BuildAction>/<BuildActionEntries> contains
only the app target — the test target is missing. Adding one <BuildActionEntry
buildForTesting="YES"> block referencing BlueprintIdentifier "FB96EB91000000Z1"
makes 5 test files (FavoritesServiceTests, AlarmTests, SleepContentTests,
SleepRecordingTests, SoundRepositoryTests) pass with zero code changes.

Reference: docs/research/testability-gaps.md for the full XML block and seam
catalog.

Constraints:
- No source changes in this plan. Only the .xcscheme file and drift.config.yaml.
- Update drift.config.yaml so its test verifier command runs ONLY the five tests
  that are expected to pass. Use -only-testing flags to scope. The full suite
  cannot be made green until Phase 4 introduces missing seams.
- After this plan ships, xcodebuild test exits 0 for the first time. That is the
  entire deliverable.
EOF
)"

# Then drift execute, then drift pr.
```

## Constraints to honor (from the user's CLAUDE.md and memory)

- **No emoji in code or commits** (DriftCode CLAUDE.md).
- **Verify branch before edits**: `git branch --show-current` before any edit on soundScapeV3. Default branch is `master` per `drift.config.yaml`.
- **Never auto-merge to main.** DriftCode creates `drift/<slug>` branches; humans merge.
- **Subscription-only.** `claude -p` spawned by drift strips `ANTHROPIC_API_KEY` etc. Don't try to re-inject.
- **The MEMORY note** "SoundScape test step is environmental — soundScapeV3 has no XCTest target; final verifier always times out and reports aborted even when every issue ships" — Phase 0 invalidates this. After it ships, **update the memory** at `/Users/mert/.claude/projects/-Users-mert-Developer-AI-Experiments-DriftCode/memory/project_soundscape_test_step_environmental.md`.
- **For long-running `drift execute`**: don't poll in <300s loops (kills prompt cache). Use ScheduleWakeup with 1200s+ delays, or run in background and rely on completion notifications.

## What NOT to do

- Don't re-run research — the 5 docs in `docs/research/` are the source of truth. Re-running wastes tokens and may produce contradictory findings.
- Don't author the `plan.md` directly. Drift's planner agent generates it from intent text. Only the intent goes into `drift plan`.
- Don't combine Phase 0 with later phases unless the user explicitly asks. Phase 0 is risk-free (one XML edit); every later phase touches production code.
- Don't try to make ALL 23 test files pass in Phase 0 — only the 5 that need no source changes. Phase 4 handles the rest.
