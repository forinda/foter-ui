#!/usr/bin/env bash
# foter-ui pipeline steps. The Release workflow calls these; run them locally the same way.
#
#   scripts/ci.sh test             install, unit tests, clarusjs check
#   scripts/ci.sh image            build linux/amd64 image, push <REGISTRY>/foter-ui:<tag>, print the tag
#   scripts/ci.sh deploy-staging   ask the infra repo to deploy <tag> to staging
#
# Environment:
#   TAG                     image tag; default: short commit of HEAD (refused if the tree is dirty)
#   REGISTRY                image: registry.digitalocean.com/<name>
#   REGISTRY_TOKEN          image: DigitalOcean token with registry read/write; unset = use your
#                           existing `docker login`
#   INFRA_REPO              deploy-staging: owner/repo, default forinda/forinda-tf-playground
#   GH_TOKEN                deploy-staging: GitHub token that may dispatch to INFRA_REPO
#                           (unset = your `gh auth` login)
set -euo pipefail
cd "$(dirname "$0")/.."

APP=foter-ui
die() { echo "error: $*" >&2; exit 1; }

tag() {
  if [[ -n ${TAG:-} ]]; then
    [[ $TAG =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid TAG '$TAG'"
    echo "$TAG"; return
  fi
  [[ -z $(git status --porcelain) ]] || die "uncommitted changes: the image would not match the tag (commit, or set TAG)"
  git rev-parse --short=7 HEAD
}

cmd_test() {
  command -v pnpm >/dev/null || corepack enable
  pnpm install --frozen-lockfile
  pnpm test
  npx clarusjs check
}

cmd_image() {
  local tag ref
  tag=$(tag)
  [[ ${REGISTRY:-} =~ ^registry\.digitalocean\.com/[a-z0-9-]+$ ]] || die "set REGISTRY=registry.digitalocean.com/<name>"
  ref="$REGISTRY/$APP:$tag"
  if [[ -n ${REGISTRY_TOKEN:-} ]]; then
    printf '%s' "$REGISTRY_TOKEN" | docker login registry.digitalocean.com -u token --password-stdin >&2
    trap 'docker logout registry.digitalocean.com >/dev/null 2>&1 || true' EXIT
  fi
  docker build --platform linux/amd64 -t "$ref" . >&2
  docker push "$ref" >&2
  echo "pushed $ref" >&2
  echo "$tag"
}

cmd_deploy_staging() {
  local tag repo=${INFRA_REPO:-forinda/forinda-tf-playground}
  tag=$(tag)
  [[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "invalid INFRA_REPO '$repo'"
  jq -n --arg app "$APP" --arg tag "$tag" \
    '{event_type: "deploy", client_payload: {app: $app, environment: "staging", tag: $tag}}' \
    | gh api "repos/$repo/dispatches" --input -
  echo "requested staging deploy of $APP:$tag in $repo" >&2
}

case ${1:-} in
  test) cmd_test ;;
  image) cmd_image ;;
  deploy-staging) cmd_deploy_staging ;;
  *) die "usage: $0 test | image | deploy-staging" ;;
esac
