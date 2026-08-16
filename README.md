# setup-shader-toolchain

A GitHub Action that provisions the Slang shader toolchain — `slangc`,
`spirv-cross` and `glslang` — on Ubuntu and Windows runners, puts them on
`PATH`, and verifies they run.

None of the three is pip- or npm-installable, and only one publishes a usable
prebuilt binary for every platform, so every repository that compiles Slang
ends up writing the same handful of steps. This is those steps, with the
version pins as inputs.

## Usage

```yaml
- uses: actions/checkout@v5

- uses: vcollab/setup-shader-toolchain@v1

- run: slangc shader.slang -target spirv -entry fragmentMain -stage fragment -o out.spv
```

For tests that **execute** a shader rather than only compiling it, ask for a
software GL stack as well and run them under `xvfb-run`:

```yaml
- uses: vcollab/setup-shader-toolchain@v1
  with:
    install-gl-stack: "true"

- env:
    LIBGL_ALWAYS_SOFTWARE: "1"
  run: xvfb-run -a pytest tests/
```

Pin to a commit SHA if your fleet pins its other actions that way:

```yaml
- uses: vcollab/setup-shader-toolchain@<sha> # v1.0.0
```

## Inputs

| Input | Default | Description |
|---|---|---|
| `slang-version` | `2026.12.0.1` | slang release tag, without the leading `v` |
| `glslang-version` | `16.5.0` | glslang release tag |
| `spirv-cross-tag` | `vulkan-sdk-1.4.357.0` | SPIRV-Cross tag to build from source |
| `install-gl-stack` | `false` | Also install Mesa's software renderer and Xvfb. Linux only |
| `toolchain-dir` | `$GITHUB_WORKSPACE/.toolchain` | Where to install |

## Outputs

| Output | Description |
|---|---|
| `toolchain-dir` | Directory everything was installed under |
| `slang-dir` | Root of the extracted slang archive (`bin/`, `lib/`) |
| `glslang-dir` | Root of the extracted glslang archive (`bin/`) |
| `spirv-cross-dir` | Root of the spirv-cross install (`bin/`) |

The tools are on `PATH`, so the outputs are only needed by callers that want
the paths explicitly.

## Platform support

| | slangc | glslang | spirv-cross | GL stack |
|---|---|---|---|---|
| **ubuntu-latest** | prebuilt | prebuilt | built + cached | Mesa + Xvfb |
| **windows-latest** | prebuilt | prebuilt | built + cached (MSVC) | not available |
| **macos-latest** | — | — | — | — |

`spirv-cross` is built from source on both platforms because it publishes no
usable prebuilt binaries: its newest release assets date from 2021 and target
Ubuntu trusty and VS2017. The build is cached per runner OS and tag, so only
the first run on a new pin pays for it.

**macOS is refused up front**, because slang publishes no macOS release asset.
The action fails with that explanation rather than part-installing and leaving
a confusing error later. If slang starts shipping macOS binaries, this repo's
own CI notices — it asserts the refusal, so the test fails when the reason
stops being true.

**Windows has no software GL.** `install-gl-stack` is ignored there with a
warning rather than an error, so a matrix job can pass the same value on both
platforms; tests needing a GL context will skip on Windows.

## Why it verifies before returning

The last thing the action does is run `slangc -v` and `glslang --version`, and
check all three tools resolve on `PATH`.

This matters more than it looks. A download that half-worked leaves the tools
missing; the calling repository's tests then **skip** rather than fail, and the
job reports green having verified nothing. Failing here converts that silent
hole into a loud one. The two tools that link against libraries shipped
alongside them are executed rather than merely located, since that is the
failure a presence check misses.

## Versioning

Tags follow semver. `v1` tracks the latest compatible release; pin to a full
version or a SHA if you would rather upgrade deliberately.

Bumping a tool version is an input change in your workflow, not a new release
of this action — the defaults exist for callers with no opinion.

## License

Apache-2.0.
