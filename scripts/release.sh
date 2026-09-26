set -euo pipefail

usage() {
  >&2 cat <<EOF
Usage: $0 [OPTIONS]

Version bump type (defaults to patch):
  -p, --patch                 Increment patch version
  -m, --minor                 Increment minor version
  -M, --major                 Increment major version

Options:
  -n, --dry-run               Run all checks and generate artifacts, but do
                              not commit, tag, or push.
  -s, --skip-clean-check      Include uncommitted and untracked changes in
                              the temporary release worktree.
  -h, --help                  Show this help.
EOF

  exit "${1:-1}"
}

args=$(
  getopt -a \
    -o pmMnsh \
    --long patch,minor,major,dry-run,skip-clean-check,help \
    -- "$@"
) || usage

release_type=patch
dry_run=false
skip_clean_check=false

eval set -- "${args}"

while :
do
  case "$1" in
    -p | --patch)
      release_type=patch
      shift
      ;;
    -m | --minor)
      release_type=minor
      shift
      ;;
    -M | --major)
      release_type=major
      shift
      ;;
    -n | --dry-run)
      dry_run=true
      shift
      ;;
    -s | --skip-clean-check)
      skip_clean_check=true
      shift
      ;;
    -h | --help)
      usage 0
      ;;
    --)
      shift
      break
      ;;
    *)
      >&2 echo "Unsupported option: $1"
      usage
      ;;
  esac
done

if (( $# > 0 )); then
  >&2 echo "Unexpected argument: $1"
  usage
fi

#
# Format:
#   OpenAPI input/output file | base JSON Schema file
#
# The first file is passed as --schema and is replaced by the generated output.
#
declare -a SCHEMA_BUILDS=(
  "galaxy.downloads.openapi.json|galaxy.schema.json"
  "systems.downloads.openapi.json|systems.schema.json"
  "factions.downloads.openapi.json|factions.schema.json"
)

REPO_ROOT=$(git rev-parse --show-toplevel)

SOURCE_BRANCH=$(git symbolic-ref --quiet --short HEAD) || {
  >&2 echo "Releases must be run from a branch, not a detached HEAD."
  exit 1
}

cd "${REPO_ROOT}"

repo_is_dirty=false

if [[ -n "$(git status --porcelain)" ]]; then
  repo_is_dirty=true
fi

if [[ "${repo_is_dirty}" == true ]] &&
   [[ "${skip_clean_check}" != true ]]
then
  >&2 echo "Repository contains uncommitted changes."
  >&2 echo "Use --skip-clean-check to include them in the release."
  exit 1
fi

echo "Fetching remote tags..."
git fetch --tags --prune

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null) || {
  >&2 echo "Unable to determine the previous release tag."
  exit 1
}

WORKTREE_DIR=$(mktemp -d)
STASH_COMMIT=""
STASH_CREATED=false
WORKTREE_CREATED=false
IN_WORKTREE=false
RELEASE_TAG_CREATED=false
RELEASE_COMMIT=""
RELEASE_COMPLETE=false

find_stash_ref() {
  local stash_commit=$1

  git -C "${REPO_ROOT}" stash list \
    --format='%gd %H' |
    awk -v commit="${stash_commit}" \
      '$2 == commit { print $1; exit }'
}

restore_original_changes() {
  if [[ "${STASH_CREATED}" != true ]]; then
    return 0
  fi

  echo "Restoring original uncommitted changes..."

  if git -C "${REPO_ROOT}" stash apply \
    --index \
    "${STASH_COMMIT}"
  then
    local stash_ref

    stash_ref=$(find_stash_ref "${STASH_COMMIT}")

    if [[ -n "${stash_ref}" ]]; then
      git -C "${REPO_ROOT}" stash drop \
        "${stash_ref}" >/dev/null
    fi

    STASH_CREATED=false
    echo "Original uncommitted changes restored."
  else
    >&2 echo "Unable to restore the original changes automatically."
    >&2 echo "The release stash has been retained."
    >&2 echo "Stash commit: ${STASH_COMMIT}"
    return 1
  fi
}

cleanup() {
  local exit_code=$?

  trap - EXIT

  if [[ "${IN_WORKTREE}" == true ]]; then
    cd "${REPO_ROOT}" || true
    IN_WORKTREE=false
  fi

  if [[ "${WORKTREE_CREATED}" == true ]]; then
    git -C "${REPO_ROOT}" worktree remove \
      --force \
      "${WORKTREE_DIR}" >/dev/null 2>&1 || true

    WORKTREE_CREATED=false
  else
    rm -rf "${WORKTREE_DIR}"
  fi

  #
  # After a successful release, advance the branch in the original checkout
  # before restoring its uncommitted changes.
  #
  if [[ "${RELEASE_COMPLETE}" == true ]] &&
     [[ -n "${RELEASE_COMMIT}" ]]
  then
    echo "Updating local ${SOURCE_BRANCH} branch..."

    if ! git -C "${REPO_ROOT}" merge \
      --ff-only \
      "${RELEASE_COMMIT}"
    then
      >&2 echo "Unable to fast-forward the local branch."
      >&2 echo "The remote release may already have been pushed."
      exit_code=1
    fi
  fi

  #
  # Delete a local tag created by an unsuccessful release. This cannot undo
  # a tag that was already pushed remotely.
  #
  if [[ "${RELEASE_COMPLETE}" != true ]] &&
     [[ "${RELEASE_TAG_CREATED}" == true ]]
  then
    git -C "${REPO_ROOT}" tag --delete \
      "${NEW_TAG}" >/dev/null 2>&1 || true
  fi

  if ! restore_original_changes; then
    exit 1
  fi

  exit "${exit_code}"
}

trap cleanup EXIT

if [[ "${repo_is_dirty}" == true ]]; then
  STASH_NAME="release-worktree-$(date +%s)-$$"

  echo "Temporarily stashing uncommitted changes..."

  git stash push \
    --include-untracked \
    --message "${STASH_NAME}" >/dev/null

  STASH_COMMIT=$(git rev-parse refs/stash)
  STASH_CREATED=true
fi

echo "Creating temporary Git worktree at ${WORKTREE_DIR}..."

git worktree add \
  --quiet \
  --detach \
  "${WORKTREE_DIR}" \
  HEAD

WORKTREE_CREATED=true

#
# All commands below this point run inside the temporary worktree.
#
cd "${WORKTREE_DIR}"
IN_WORKTREE=true

echo "Working directory: $(pwd)"

if [[ "${STASH_CREATED}" == true ]]; then
  echo "Applying uncommitted changes to the temporary worktree..."

  git stash apply \
    --index \
    "${STASH_COMMIT}"

  #
  # Preserve the changes in the worktree, but clear their staged state.
  # Only explicit release artifacts will be staged later.
  #
  git reset
fi

#
# This check runs after the stash is applied, so an uncommitted README change
# is included when --skip-clean-check is supplied.
#
if git diff --quiet "${LAST_TAG}" -- README.md; then
  >&2 echo "README.md has not changed since ${LAST_TAG}."
  exit 1
fi

echo "Installing dependencies..."
pnpm install --frozen-lockfile

CURRENT_VERSION=$(
  pnpm dlx node-jq -r '.version' package.json
)

if [[ ! "${CURRENT_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  >&2 echo "Unsupported package version: ${CURRENT_VERSION}"
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "${CURRENT_VERSION}"

case "${release_type}" in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
NEW_TAG="${NEW_VERSION}"

if git rev-parse \
  --verify \
  --quiet \
  "refs/tags/${NEW_TAG}" >/dev/null
then
  >&2 echo "Tag ${NEW_TAG} already exists."
  exit 1
fi

echo
echo "Current version : ${CURRENT_VERSION}"
echo "Release version : ${NEW_VERSION}"
echo "Release branch  : ${SOURCE_BRANCH}"
echo "Worktree        : ${WORKTREE_DIR}"
echo

#
# Regenerate all schema files.
#
for build in "${SCHEMA_BUILDS[@]}"
do
  IFS='|' read -r \
    openapi_file \
    base_schema_file \
    <<< "${build}"

  if [[ ! -f "${openapi_file}" ]]; then
    >&2 echo "OpenAPI input does not exist: ${openapi_file}"
    exit 1
  fi

  if [[ ! -f "${base_schema_file}" ]]; then
    >&2 echo "Base JSON Schema does not exist: ${base_schema_file}"
    exit 1
  fi

  generated_file="${openapi_file}.new"

  echo "Generating ${openapi_file}"
  echo "  Input/output: ${openapi_file}"
  echo "  Base schema : ${base_schema_file}"

  node scripts/convert_openapi_to_json.js \
    --schema "${openapi_file}" \
    --base_json_schema "${base_schema_file}" \
    > "${generated_file}"

  pnpm dlx node-jq empty "${generated_file}" >/dev/null

  mv "${generated_file}" "${base_schema_file}"
done

#
# Update package.json.
#
package_tmp=$(mktemp)

pnpm dlx node-jq \
  --arg version "${NEW_VERSION}" \
  '.version = $version' \
  package.json \
  > "${package_tmp}"

mv "${package_tmp}" package.json

#
# Clear the worktree index before staging release artifacts. This prevents
# files that were staged in the original checkout from leaking into the
# release commit.
#
git reset

git add package.json

for build in "${SCHEMA_BUILDS[@]}"
do
  IFS='|' read -r \
    openapi_file \
    _ \
    <<< "${build}"

  git add "${openapi_file}"
done

if git diff --cached --quiet; then
  >&2 echo "Release produced no staged changes."
  exit 1
fi

if [[ "${dry_run}" == true ]]; then
  echo
  echo "Dry run succeeded."
  echo
  echo "Proposed release changes:"
  git diff --cached --stat
  echo
  echo "No commit, tag, or push was performed."
  exit 0
fi

git commit -m "Release ${NEW_TAG}"
RELEASE_COMMIT=$(git rev-parse HEAD)

git tag "${NEW_TAG}"
RELEASE_TAG_CREATED=true

git push origin "HEAD:refs/heads/${SOURCE_BRANCH}"
git push origin "refs/tags/${NEW_TAG}"

RELEASE_COMPLETE=true

echo
echo "Released ${NEW_TAG}"
