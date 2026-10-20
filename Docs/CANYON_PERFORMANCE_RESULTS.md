# Saved lake/canyon results, 2026-10-01

Implemented, built, and validated on the user's lake/canyon state. No reliable overall gameplay FPS
or smoothness improvement is established by the preparation changes. The initial apparent gain
does not survive comparisons with similar background load. The optional blur switch removes an
identified camera-motion pass, but its FPS effect is also inconclusive. No interpolation, simulation
speed increase, physics change, or altered VU arithmetic was introduced.

## Build and private launch

The runnable executable is `build/port/bin/sotc.exe`, SHA-256
`93D5B9D0157A05DAB25BD3BB824EDE32DCC94C5F81F2276C73162F00981CCCAC`.
Rebuild with `build.bat`. The existing CMake configuration reuses the unchanged generated EE archive
at `build/performance-baseline-20261001/sotc_game_code.lib`; the changed host/runtime sources are rebuilt.
The generated EE and VU program sources were not edited.

From the repository directory, launch this scene with private cards and a separate F5/F9 slot:

```powershell
.\Tools\private_state_launch.ps1 -State .\build\canyon-20261001\canyon.state
```

The launcher copies the executable, INI, state and cards into `build/private-play`. Existing private
cards and INI choices persist. It loads `input.state` once and leaves `states/quick.state` separate.
Add `-DisableMotionBlur` to enable the optional switch for that launch. The launcher was exercised
in `build/canyon-20261001/play-test`: the game loaded field 104074, used that directory's card, and
closed normally. `run.bat` remains the ordinary launcher for the main installation.

The original executable and PDB are preserved in `build/canyon-20261001/baseline-bin`; the diagnostic
baseline is in `instrumented-baseline-bin`, and the preparation build before the fingerprint experiment
is in `pre-hash-fix-bin`. The original repository commits remain `11c62a1` and submodule `1808cc1`.
Changes are left in the working trees. Both trees were clean before this task.

## Fixture and camera constraint

The state is the user's `build/port/bin/states/quick.state`, copied privately to
`build/canyon-20261001/canyon.state`. Both retain SHA-256
`3ACA61445C3E00836FA19A8BCF22BBE34888B4A5D94C6C01F72739FBCC5CC74D`.
The original `build/port/bin/memcards/Mcd001.ps2` retains SHA-256
`4B3700109CCF7C994770A97B745D513A40C6FC4184167F87D0069E29F7AA1027`.
Every timed launch used another private state/card copy. No original quick-slot or card writes occurred.

Framebuffer captures show Wander on Agro above a lake, a stone bridge, and the canyon walls.
The shrine was not substituted. The initial view and four slow-circle extremes were inspected in
`identify` and `camera-calibration`. The command
`SOTC_CAMERA_TEST=104200:240:10:5` approaches the circle over 60 fields, performs five four-second
circles, and returns to center over 60 fields. It supplies mouse deltas through the existing native
camera path, with no player movement input. Yaw and pitch remain within approximately ±1.43 degrees.
The measured window is fields 104260 through 105460, approximately 20 seconds.

The inspected extremes and before/after images keep the same expensive view. Contact sheets are
`primary-views.jpg`, `full-views.jpg` and `blur-views.jpg` in the evidence directory. Window captures
after private reload and resize also show that canyon. Camera CSVs corroborate the entire scripted
path: the maximum component residual against the circle, allowing the previous camera update's field,
is below 0.009 degrees in all six final hashed comparisons. The returned center differs by roughly
0.007 degrees from the initial angles, from float accumulation. Target motion is ordinary horse/rider
idle motion; the input never moves the player. Visual sampling is not continuous recorded video.

## Measurements and acceptance

Hardware: Ryzen 5 5500, 12 logical processors, RTX 3060, NVIDIA OpenGL driver 616.64. The window
swaps near 75 Hz with VSync enabled. NTSC and both existing host-pacing switches remain enabled.
The previous direct presentation, compact commands, eight-chunk queue, VIF unpack and VU clipping
optimizations stay enabled in both sides. This task's baseline disables only its four preparation switches.

Primary comparisons omit hashing, profiling, GPU queries and camera CSVs. Screenshots are outside
the measured window. Baseline/new order alternates, including reversed pairs. There are four pairs
for the first three changes (`primary-*`), four for all preparation changes (`full-*`), and three on
the final executable (`final-*`). Separate hashed/camera-trace comparisons are `hash-*` and `hash2-*`.
Resource samples record system and game CPU time; no competing application was stopped or changed.
All 52 capture launches closed with exit 0.

The following are medians of three final alternating pairs. Percentiles are calculated per run and
then summarized by their median, rather than pooling intervals from different loads.

| Primary timing metric | Baseline | New |
|---|---:|---:|
| Emulated VBlanks/s | 59.936 | 59.947 |
| Actual scheduler updates/s | 52.201 | 51.856 |
| Scheduler rate range | 49.697–53.445 | 49.656–54.347 |
| Completed compositor sources observed/s | 59.161 | 58.690 |
| New compositor sources delivered/s | 59.111 | 58.690 |
| Host swaps/s | 74.974 | 74.973 |
| Repeated-source swaps per approximately 20 s | 316 | 320 |
| Update interval median / p95 / p99, ms | 17.184 / 32.866 / 35.927 | 17.095 / 32.725 / 39.345 |
| Source delivery interval median / p95 / p99, ms | 13.400 / 26.740 / 26.963 | 13.400 / 26.733 / 27.200 |
| Worst observed update gap across the three runs, ms | 237.656 | 218.259 |
| Update gaps above 50 ms across all three windows | 3 | 13 |
| Game-clock seconds per wall second | 0.99991 | 1.00001 |
| Other processes' busy CPU cores | 2.358 | 2.548 |

The final submission p95 medians are 0.850 / 0.434 ms, but this does not translate into a robust
update-rate or tail improvement. The earlier four-pair preparation comparison gives median rates
54.495 / 53.569 updates/s, with 2.204 / 2.461 other busy cores. Its update p99 medians are
34.987 / 35.105 ms. The first three-change comparison looked better, but its baseline had substantially
more background load. Similar-load samples overlap. No general FPS percentage gain is accepted.

Changed-image measurements below are a separate three-pair cohort, with substantially lighter load
in most windows. They must not be combined with the primary update rates as though recorded together.

| Fingerprinted diagnostic metric | Baseline | New |
|---|---:|---:|
| Actual scheduler updates/s in these runs | 59.345 | 58.640 |
| Changed images delivered/s | 56.742 | 56.693 |
| Changed-image rate range | 55.656–57.392 | 47.851–56.904 |
| Completed sources delivered/s | 59.839 | 59.839 |
| Host swaps/s | 75.023 | 75.024 |
| Repeated-image swaps per approximately 20 s | 366 | 366 |
| Changed-image interval median / p95 / p99, ms | 13.400 / 39.900 / 40.076 | 13.400 / 39.900 / 40.100 |
| Median of per-run maximum image gap, ms | 53.400 | 53.400 |
| Other processes' busy CPU cores | 0.775 | 1.002 |

The new third hashed run had 2.636 other busy cores and fell to 49.450 updates/s and 47.851 changed
images/s; the first two new runs had approximately 0.76–1.00 other cores and 58.64–59.09 updates/s.
The baseline hashed runs were all near 0.75–0.79 other cores. This is further reason not to claim a gain.
Across final primary, hashed and blur cohorts, game-clock progression is 0.99811–1.00010 seconds per
wall second. Idle animations continue; no timing, cycle-accounting or pacing policy was changed.

The 64-bit fingerprint covers the composited source pixels and dimensions, not physical scanout;
collisions remain possible. Completed source sequence span also counts published sources skipped by
the window through its last acquired completed fence. It is not an exact GPU completion timestamp trace.
Field-sampled update gaps can miss multiple updates inside a field. Camera CSVs provide direct camera
entry intervals in the separate diagnostic runs. Swap returns do not establish input-to-photon latency.

Early hash runs showed only roughly 41–46 changed images/s under higher background load. A diagnostic
experiment reduces the hash in an unmapped GPU buffer, then copies eight bytes to the coherent mapped
readback slot. `PS2X_FRAME_HASH_DEVICE=0` restores the old destination. A later quiet old-path repeat
also delivered 59.889 sources/s and 57.192 changed images/s, versus 59.839 and 56.693 for the new-path
quiet sample. A reliable fingerprint speedup is not established. The experiment is separate from gameplay
performance and has no effect when hashing is disabled. No sparse-pixel approximation was substituted.

## Causes found and implemented work

The evidence supports costly CPU game/graphics preparation and VU geometry, strongly affected by
background load, as the main sources of missed actual updates. Completed composition can remain
near 60/s while actual updates are near 50/s: many outputs repeat game content. A 75 Hz window then
quantizes fresh-image delivery into roughly 13.3, 26.7 and sometimes 40 ms gaps. Frequent swaps are
therefore not evidence of smooth 60 FPS gameplay.

Separate canyon stack samples include profiler overhead and intentional pacing waits. The VU sample
spends approximately 64.5% inclusive in VU execution and 25.8% waiting; three compiled blocks account
for approximately 30% self time. Ordinary logs show approximately 11–13 ms VU work per field.
EE work includes dispatch, game/model/graphics preparation, memory operations, IOP/audio and pacing.
The hottest generated VU segments already use SIMD and normalized register locals; their exact FMAC,
pipeline flags and register-pressure costs remain. Approximate arithmetic and timing shortcuts were rejected.

GPU-query profiling observes substantial raster and transfer/page-copy work, but query resolution itself
adds large driver waits. Its per-presentation figures are not whole-game frame times and cannot establish
the GPU's primary critical path. Shared presentation submission is short in ordinary runs; the evidence
does not identify the previous RAM presentation round trip as the current main problem. Transfer hazards,
copy-on-write, ordering, and the bounded queue were retained.

Implemented changes, all independently reversible by setting the named switch to `0` and restarting:

| Change | Purpose | Acceptance |
|---|---|---|
| `SOTC_FAST_OBSERVERS` | Reuse an immutable observer list instead of copying vectors/functions at each guest hook | Correctness passes; FPS/smoothness gain inconclusive |
| `PS2X_EE_SINGLE_LOOKUP` | Resolve a valid guest call target once instead of checking and looking it up again | Missing-target/unwind/runtime tests pass; FPS gain inconclusive |
| `PS2X_GS_TEXTURE_PAGE_CACHE` | Reuse an identical texture address footprint across primitives | Live pixel/hazard handling retained; GPU/VRAM equivalence passes; FPS gain inconclusive |
| `PS2X_GS_FAST_TRIANGLE_SETUP` | Replace expensive library rounding/bounds calls in valid bounded GS coordinates | Rounding, edges and coverage match; FPS gain inconclusive |

These preparation switches default to `1`. Their reduced work is supported by the profiles and code
paths, but no change is accepted as a reliably measured increase in overall gameplay FPS or smoothness.
The camera trace follows the requested circle closely, including quiet runs with near-stable source
delivery. It supplies no evidence of an additional native-mouse angle-response defect. Physical mouse
feel and the original right-stick easing path were not directly assessed. Camera behavior was not changed.

## Motion blur

The separate framebuffer-feedback level at `0x128F520` is zero throughout the diagnostic scene;
`feedbackBlur` and `feedbackBlur2` were not called. The camera-blur enable at `0x128A134` is one.
The game's `cameraBlur` at `0x1180800` computes camera-motion history and conditionally calls
`screenBlur` at `0x117FDF8`, returning to `0x1180F90`. That draw does not fire in the slow circle,
but does fire in `104200:60:20:20`, a one-second circle within approximately ±2.86 degrees.
This identifies an actual motion-dependent blur pass, independently of fog, bloom and low-FPS judder.
It does not establish broader temporal framebuffer accumulation in this scene.

`SOTC_DISABLE_MOTION_BLUR=0` preserves original behavior and is the default. `1` bypasses only that
specific `screenBlur` call. The original motion-history and intensity calculations continue, and the
guest enable flags are neither overwritten nor persisted differently. Other callers, feedback passes,
ordinary blending, bloom, fog and shadows remain. The setting is added to missing INI files as `0`.

Three alternating fast-circle pairs measure median 58.895 updates/s with blur and 58.998 without.
Update p99 is 30.268 / 32.622 ms; source delivery remains approximately 59.9/s. This does not establish
a blur-disable FPS or smoothness gain. `blur-visual-0` and `blur-visual-1` show the canyon, characters,
bright-wall bloom, haze and bridge correctly with the same bounded input. The subtle effect and different
capture phases do not establish a strong subjective clarity benefit from these stills. The switch is an
optional clarity preference, not a cure for missed updates or display persistence.

## Validation, limits and rollback

- Runtime suite: **499/499 passed**, including a coordinate oracle checking 524,292 signed/halfway/
  neighboring rounding cases plus 16,384 random triangle setups and the existing dispatch/unwind tests.
  Log: `build/canyon-20261001/runtime-tests-final.txt`. The initial invocation used the wrong working
  directory for a pre-existing source-inspection test; rerunning from `External/PS2Recomp` resolves it.
- Fresh canyon VU trace: **3,192 executions over three fields, zero interpreter mismatches**.
  Log: `vu-canyon-verify.txt`, fixture: `profile-ee/trace.bin` and its captured microprogram images.
- Original versus optimized GPU preparation: **zero pixel and VRAM differences** at the two compared
  canyon checkpoints and every compared checkpoint in menu language, menu Hz, loading, logo and
  cutscene recordings. Logs: `equivalence-*-final.txt`. Use `--compare-backends gputhreadoriginal gpu`:
  each GPU backend needs its own owning context/thread. The initial same-thread two-GPU comparison
  was invalid and is excluded. The replay tool now returns failure for detected differences.
- State/window: private F5 save, F9 reload, F11 fullscreen both directions, resize to a 1264×681 client,
  verified minimization, restore and normal close pass in `window-minimize-final`. Its post-restore
  `field-105650.png` shows the correct canyon. The earlier PostMessage minimize test did not confirm
  minimization; the helper now uses `ShowWindow`, and the final run reports minimized true then false.
  PrintWindow captures are blank for this OpenGL window and are excluded from visual evidence.
- Stable gameplay/audio intervals report **zero missing frames, underruns and dropped frames**;
  state-load queue resets are separate. Physical listening, controller vibration and audio fidelity are
  not established by queue health. Existing SPU2 fidelity limitations remain.
- Original state/card hashes were checked again after all tests. Controls, guest timing, save formats,
  animation/physics code and audio synthesis were not modified. This is short scene validation, not a
  complete playthrough, ordinary card-save test, physical-display measurement or end-to-end input test.

Remaining costs are generated EE game/graphics work, VU geometry/flags/spills, GS triangle/binning work,
GPU raster/transfer/page-copy work and host/background scheduling. Moving geometry to the GPU would
require preserving CPU-visible VU memory, flags, stalls and XGKICK order; it was not attempted as an
approximation. The build does not guarantee 60 genuinely new gameplay images/s.

For behavior rollback, set the four preparation switches to `0`, `SOTC_DISABLE_MOTION_BLUR=0`, and
remove `SOTC_CAMERA_TEST` / `SOTC_CAMERA_TRACE`; restart the game. Set `PS2X_FRAME_HASH_DEVICE=0`
to reverse the diagnostic destination experiment, or leave `PS2X_FRAME_HASH=0` for normal play.
Each change can be disabled separately. Full binary rollback, with the game closed:

```powershell
Copy-Item .\build\canyon-20261001\baseline-bin\sotc.exe .\build\port\bin\sotc.exe
Copy-Item .\build\canyon-20261001\baseline-bin\sotc.pdb .\build\port\bin\sotc.pdb
```

No card/state restoration is required: their originals were never changed. Private test folders are
independent of the original installation. Aggregate numbers and individual reports/settings/frames/
timelines/resources are retained in `build/canyon-20261001/results.json` and its named capture folders.

## VU1 FMAC checks and normalization, 2026-10-20

Goal: bring the 75 Hz canyon fixture (`build/perf_75hz/fixture.state`, `--camera-test 16205:240:10:5`,
fields 16265–17465) closer to 60 real game updates/s by reducing VU1 emulation cost, with exact
semantics only. Baseline is main `8d7e0ef` (submodule `243e0fb`), same hardware as above. The user's
`build/port/bin/states/quick.state` was not used or written; every launch loads a private fixture copy.

### Where the time goes

Without EE host pacing the baseline runs this scene at about 36–40 fields/s. The game thread spends about
a third of its time in `asyncvif::sync` waiting for the VU worker, which is about 94% busy. On a recorded
four-field trace (`build/perf_75hz/vu1perf/trace-1`, 4.73 M VU cycles per field) the VU thread spends about
79% in compiled VU1 code, about 10% in VIF decode and about 5.5% copying XGKICK data. Inside compiled code,
FMAC instructions are about half of the samples, and most of each FMAC is the fast-path range check that
decides whether the single-precision result is already the PS2 result or must be redone by the exact path.
Two segments of image `d18c8dfa` (a 47-pair vertex body and a 12-pair self loop) take about 65%.

### Changes

Both changes are exact: results, MAC/status/sticky flags and the normalized register copies are identical
to the previous code for every input, and lanes that are not provably exact still take the unchanged exact path.

- Lean FMAC checks. The range checks use the integer bit patterns instead of float compares. MUL, ADD and
  SUB accept results in [FLT_MIN, FLT_MAX) instead of [4·FLT_MIN, FLT_MAX/2): under round-toward-zero such
  a float result already equals the PS2 result with the same flags. MADD, MSUB and OPMSUB keep the previous
  bounds, expressed as integer comparisons. In safe lanes the product's zero flag equals "an operand is zero".
- Lean normalization. Converting a register to its PS2-normalized form (denormals to signed zero, exponent
  255 clamped to ±max) takes 6 integer SIMD operations instead of 11.

`vu1_recomp` chooses the paths when it generates `Port/generated/vu1`; default generation is byte-identical to
before, because the lean paths are the template defaults of the runtime helpers it calls. Generating with
`PS2X_VU1_LEAN_FMAC=0` and/or `PS2X_VU1_LEAN_NORM=0` emits the previous code (`fmacV<FK::Madd, false>`,
`vnorm<false>(…)`), then rebuild:

```powershell
$env:PS2X_VU1_LEAN_FMAC='0'; $env:PS2X_VU1_LEAN_NORM='0'
python Tools/generate.py --vu1-only
Remove-Item Env:PS2X_VU1_LEAN_FMAC, Env:PS2X_VU1_LEAN_NORM
.\build.bat
```

These are generation-time switches, not `sotc.ini` settings. A runtime switch was built and measured first:
a per-instruction branch in the hot path, with both paths inlined or with the reference out of line, made the
compiled VU code 15–30% slower on MSVC, more than the change saves.

Tried and rejected: keeping registers in locals across iterations of a self-looping segment. It was exact
(zero mismatches) but slower on the trace (84.5 versus 81 M thread cycles per field) and was removed.

### Results

Trace bench (`sotc_vu1_bench <trace> --repeat 20 --cpu-cycles`), medians of six alternating pairs on a quiet machine:

| VU1 trace metric | Baseline | New |
|---|---:|---:|
| Wall ms per field | 19.65 | 17.42 |
| VU thread CPU cycles per field | 87.3 M | 79.1 M |

Seven further pairs on the final build under about 50% unrelated CPU load give 25.42 / 22.48 ms and
108.7 / 98.6 M cycles per field: the same ~9–11% reduction.

In-game captures alternate baseline and new, each 33 s from the private fixture copy, VSync on, 75 Hz.
Medians per run, then the median across runs:

| Canyon metric | Baseline | New |
|---|---:|---:|
| Fields/s without EE host pacing (6 pairs) | 37.19 | 41.53 |
| Range | 35.76–39.62 | 36.16–42.91 |
| Other processes' busy CPU cores | 2.30 | 1.82 |
| Game updates/s with pacing (3 pairs) | 33.36 | 34.61 |
| Range | 31.88–33.42 | 33.91–35.71 |
| Update interval median / p95 / p99 with pacing, ms | 26.67 / 50.21 / 59.75 | 24.27 / 49.07 / 58.78 |
| Other processes' busy CPU cores with pacing | 1.37 | 1.69 |
| Emulated VBlanks/s and game clock with pacing | 59.95 / 1.000 | 59.93 / 1.000 |

The new build won five of six unpaced pairs; the one loss ran with 3.9 other busy cores. Comparing only
unpaced runs with 1.3–1.5 other cores gives 39.62 fields/s for the baseline and 42.40–42.91 for the new
build, about +7–8%. Every paced new run exceeded every paced baseline run despite slightly more background
load. Background applications (Discord, Edge, editors, other assistants) were left running.

This is a real but modest gain. The scene remains far from 60 updates/s: without pacing it emulates about
0.69 game seconds per wall second, and with pacing actual updates stay near 35/s with a p95 interval near
50 ms. Reaching 60 needs roughly 30–35% less VU thread time per field beyond this. Candidates that keep exact
semantics are segment-level deferred FMAC validation with rollback, and moving VIF decode and XGKICK copying
off the VU thread.

### Correctness

- `sotc_vu1_bench --verify` on the canyon trace: 49,152 executions, 0 mismatches (final build).
- Live `PS2X_VU1_VERIFY=1` on the fixture (`build/perf_75hz/lean-verify-vu`): 229,376 VU1 runs, 0 mismatches.
- New runtime test `lean FMAC checks and normalization match the reference paths`: 200,000 normalization
  samples and 60,000 cancellation-prone operand sets for each of ADD, SUB, MUL, MADD, MSUB, OPMSUB and OPMULA
  (both FMAC flag modes), lean versus reference results, normalized values and flags compared bit for bit.
- `ps2x_tests`: 470 of 476 pass, including all VU/VU1 tests. The six failures are unrelated to this change:
  five `PS2FloatSemantics` tests expect upstream PS2-hardware EE results that the port's restored EE float
  semantics (`243e0fb`) intentionally do not use, and `golden GS recordings are present` fails because no
  `.gsr` goldens exist in this checkout.
- Reference generation (`PS2X_VU1_LEAN_FMAC=0`, `PS2X_VU1_LEAN_NORM=0`) compiles into `sotc_vu1_bench_alt`
  (`-DSOTC_VU1_ALT_DIR=<generated dir>`) and verifies with 0 mismatches.

The in-game A/B used the new build before two final cleanups that do not touch generated code (an unused
include and restoring the previous normalization in the once-per-entry register resync); the trace and live
verification above use the final build. Captures are `build/perf_75hz/lean-{u,p}N-{base,new}` in the main checkout.
