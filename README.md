# rules_idea_poc

A rudimentary proof-of-concept implementation of IDEA's [Shared Indexes](https://www.jetbrains.com/help/idea/shared-indexes.html) under Bazel, circa September 2020.

## Shortcomings

1. Everything here is defined as a simple runnable workspace rule that invokes a script and then cURL's the results up.
   - This basic PoC approach is similar to how tools like `gazelle` run (getting a handle to the workspace source rather than declaring inputs) but thats less than ideal in this case
   - A _build_ rule should be created to generate cacheable outputs
     - Perhaps supported by something like an aspect or _generated_ and correct recursive `"srcs"` `filegroup`s like the bazel source repository has (these don't seem hand written)--be wary of a simplistic recusive filegroup though as subpackages break these.
     - Ideally these actions can also run in parallel and remotely.
2. IDE wrapping script is pretty rudimentary
    - It doesn't support platforms other than macOS
    - It doesn't really encode IDEA version etc correctly either
3. I made no attempt to integrate fetched indexes (indices?) with the Bazel plugin
4. The solution should also generate the `intellij.yaml` config
5. Doesn't correctly get VCS info from `workspace_status` as it probably should
6. This is pretty far out of date at this point.

## Usage

_This has been open-sourced as-is to provide a frame of reference for future work and may or may not work as expected at this point; comments in code specify the versions used to some extent._

### Invoke the POC rule

```bash
bazel run @flare_shared_index//:generate
```

- The cURL upload commands will fail if you don't have write access to the configured GCS bucket
- You can inspect the outputs with the following command:

```bash
(cd bazel-jetbrains-out/idea/indexes/flare_shared_index && tree -l 3)
```

and observe something like the following:

```text
▁
/private/var/tmp/_bazel_username/c1f80fc93ff31c018df54fa0c8648649/execroot/rules_idea_poc/bazel-out/darwin-fastbuild/bin/external/flare_shared_index/generate.runfiles/rules_idea_poc/bazel-jetbrains-out/idea/indexes/flare_shared_index
└── ba84ec5aeb4b67b1391a7d9c28ed47e782c3169b
   ├── shared-index-project-workspace-6a04e54d0e9a1470.ijx.xz
   ├── shared-index-project-workspace-6a04e54d0e9a1470.metadata.json
   ├── shared-index-project-workspace-6a04e54d0e9a1470.sha256
   ├── shared-index-project-workspace-88c8424604efaaa6.ijx.xz
   ├── shared-index-project-workspace-88c8424604efaaa6.metadata.json
   └── shared-index-project-workspace-88c8424604efaaa6.sha256

directory: 1 file: 6
```

### Digging deeper

- The source for the targets invoked above is defined in `//jetbrains/jetbrains_shared_index.bzl`
- All of the output for the tools can be found in `bazel-jetbrains-out/` via the convenience symlink created, including all of the other content created by Jebtrains IDEs, be sure to inspect this output during further development.
