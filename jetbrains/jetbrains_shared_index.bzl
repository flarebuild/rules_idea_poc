
BUILD_FILE_CONTENT="""
# generated, do not edit
# hello@flare.build

sh_binary(
    name = "generate",
    srcs = ["generate_index.sh"],
    deps = [":ide",],
    data = glob(["bin/**", "lib/**"]),
    args = [
        "idea",
        "{name}",
    ],
)

sh_library(
    name = "ide",
    srcs = ["ide.sh"],
    data = [
        ":ide.properties",
    ],
)
"""

GENERATE_INDEX_CONTENT="""
#!/usr/bin/env bash

# note: expects to be invoked with $1 == idea (or some jetbrains IDE path)

set -e

### Assemble symlinks
# link in the workspace dir
mkdir -p ./workspace
ln -nsf $BUILD_WORKSPACE_DIRECTORY/* ./workspace/

# ls -l ./workspace/

STABLE_GIT_COMMIT=$(git --git-dir "$BUILD_WORKSPACE_DIRECTORY/.git" rev-parse HEAD)
PROJECT_ID=${{2:-default_project}}
PROJECT_KIND=project
OUTPUT_ROOT=$(pwd)/bazel-jetbrains-out/idea
TMP_PATH=$OUTPUT_ROOT/temp
INDEX_OUTPUT_PATH=$OUTPUT_ROOT/indexes/$PROJECT_ID/$STABLE_GIT_COMMIT

mkdir -p $TMP_PATH
mkdir -p $INDEX_OUTPUT_PATH

CMD="./external/{name}/ide.sh $1 dump-shared-index $PROJECT_KIND --output=$INDEX_OUTPUT_PATH --tmp=$TMP_PATH --project-dir=./workspace --project-id=$PROJECT_ID --commit=$STABLE_GIT_COMMIT"
# echo "$CMD"
$CMD

ln -nsf $(pwd)/bazel-jetbrains-out $BUILD_WORKSPACE_DIRECTORY/

# only prepares metadata; still need to upload ourselves, apparently.
./external/{name}/bin/upload-local --indexes-dir="$OUTPUT_ROOT/indexes" --url={upload_url}

for file in $(find $OUTPUT_ROOT/indexes -type f); do
    stripped=${{file#"$OUTPUT_ROOT"/}}
#    echo "curl -T $file {upload_url}/$stripped"
    curl -T $file {upload_url}/$stripped
done

"""

IDE_CONTENT="""
#!/usr/bin/env bash

IDE_PROPERTIES=./external/{name}/ide.properties
export PYCHARM_PROPERTIES=$IDE_PROPERTIES
export WEBIDE_PROPERTIES=$IDE_PROPERTIES
export IDEA_PROPERTIES=$IDE_PROPERTIES

# linux or macos via toolbox:
# maybe linked at /usr/local/bin/idea; todo

# open app (macos) WORKING
# shift; # shift cuz our gen script passes ide as arg
# open -na "IntelliJ IDEA.app" --args "$@"

# use the idea launcher, assuming the user has followed the guide and linked
# the start script to /usr/local/bin or added to PATH.
# works with IDEA2020.2+, not sure about 2020.1

# exec idea "$@"
IDE_BIN="${{1:-idea}}"
shift;
exec $IDE_BIN "$@"
"""

IDE_PROPERTIES_CONTENT="""
idea.system.path=./bazel-jetbrains-out/idea/ide-system
idea.config.path=./bazel-jetbrains-out/idea/ide-config
idea.plugins.path=./bazel-jetbrains-out/idea/ide-config/plugins
idea.log.path=./bazel-jetbrains-out/idea/ide-log
"""

def _impl(repository_ctx):
    repository_ctx.download_and_extract(
        url = "https://storage.googleapis.com/flare-public/upload-local-{}.zip".format(
            repository_ctx.attr.uploader_version,
        ),
        sha256 = repository_ctx.attr.uploader_sha,
        output = ".",
        stripPrefix = "upload-local-1.0.7",
    )

    repository_ctx.file(
        "BUILD",
        content = BUILD_FILE_CONTENT.format(name=repository_ctx.attr.name),
    )
    repository_ctx.file(
        "generate_index.sh",
        content = GENERATE_INDEX_CONTENT.format(name=repository_ctx.attr.name, upload_url=repository_ctx.attr.upload_url),
    )
    repository_ctx.file(
        "ide.sh",
        content = IDE_CONTENT.format(name=repository_ctx.attr.name),
    )
    repository_ctx.file(
        "ide.properties",
        content = IDE_PROPERTIES_CONTENT,
    )

jetbrains_shared_index = repository_rule(
    implementation= _impl,
    local = True,
    attrs = {
        "uploader_version": attr.string(default = "1.0.7"),
        "uploader_sha": attr.string(),
        "upload_url": attr.string(),
    }
)
