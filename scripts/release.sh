#!/usr/bin/env bash
set -euo pipefail

usage() {
  >&2 cat <<EOF
Usage: $0 [OPTIONS]

Version bump type (defaults to patch):
  -p, --patch              Increment patch version
  -m, --minor              Increment minor version
  -M, --major              Increment major version

Options:
  -n, --dry-run            Run all checks and generate artifacts but do not
                           commit, tag, or push.
  -s, --skip-clean-check   Allow release even if the current checkout
                           contains uncommitted changes.
  -h, --help               Show this help
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

declare -a SCHEMA_BUILDS=(
  "galaxy.downloads.openapi.json:galaxy.schema.json"
  "merged.downloads.openapi.json:galaxy.schema.json"
  "systems.downloads.openapi.json:systems.schema.json"
  "factions.downloads.openapi.json:factions.schema.json"
)

#
# Ensure source checkout is clean unless explicitly overridden.
#
if [[ "${skip_clean_check}" != true ]]; then
  if [[ -n "$(git status --porcelain)" ]]; then
    >&2 echo "Repository contains uncommitted changes"
    >&2 echo "Use --skip-clean-check to override"
    exit 1
  fi
fi

git fetch --tags --prune

LAST_TAG=$(
  git describe --tags --abbrev=0 2>/dev/null
)

if [[ -z "${LAST_TAG}" ]]; then
  >&2 echo "Unable to determine last tag"
  exit 1
fi

#
# README must have changed since the previous release.
#
if git diff --quiet "${LAST_TAG}..HEAD" -- README.md; then
  >&2 echo "README.md has not changed since ${LAST_TAG}"
  exit 1
fi

WORKTREE_DIR=$(mktemp -d)

cleanup() {
  popd >/dev/null 2>&1 || true
  git worktree remove --force "${WORKTREE_DIR}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "Creating temporary worktree..."
git worktree add --quiet "${WORKTREE_DIR}" HEAD

pushd "${WORKTREE_DIR}" >/dev/null

echo "Installing dependencies..."
pnpm install --frozen-lockfile

CURRENT_VERSION=$(
  pnpm dlx node-jq -r '.version' package.json
)

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

if git rev-parse --verify --quiet "refs/tags/${NEW_TAG}" >/dev/null; then
  >&2 echo "Tag ${NEW_TAG} already exists"
  exit 1
fi

echo "Current version : ${CURRENT_VERSION}"
echo "Release version : ${NEW_VERSION}"
echo

#
# Regenerate all schemas.
#
for build in "${SCHEMA_BUILDS[@]}"
do
  IFS=':' read -r openapi_file schema_file <<< "${build}"

  echo "Generating ${schema_file} from ${openapi_file}..."

  node scripts/convert_openapi_to_json.js \
    --schema "${openapi_file}" \
    --base_json_schema "${schema_file}" \
    > "${schema_file}.new"

  pnpm dlx node-jq empty "${schema_file}.new" >/dev/null

  mv "${schema_file}.new" "${schema_file}"
done

#
# Update package.json version.
#
tmp=$(mktemp)

pnpm dlx node-jq \
  --arg version "${NEW_VERSION}" \
  '.version = $version' \
  package.json \
  > "${tmp}"

mv "${tmp}" package.json

#
# Stage release artifacts.
#
git add package.json

for build in "${SCHEMA_BUILDS[@]}"
do
  IFS=':' read -r _ schema_file <<< "${build}"
  git add "${schema_file}"
done

if git diff --cached --quiet; then
  >&2 echo "Release produced no changes"
  exit 1
fi

if [[ "${dry_run}" == true ]]; then
  echo
  echo "Dry run succeeded."
  echo
  echo "Staged changes:"
  git diff --cached --stat
  echo
  echo "No commit, tag, or push performed."
  exit 0
fi

git commit -m "Release ${NEW_TAG}"

git tag "${NEW_TAG}"

git push origin main
git push origin "${NEW_TAG}"

echo
echo "Released ${NEW_TAG}"
