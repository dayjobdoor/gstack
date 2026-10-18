#!/bin/sh
# Vendor upstream cursor/plugins/pstack skills, agents, guide, README, license into plugin/.
# VERSION is "<upstream>.<rev>" (4 parts = non-semver, so omp treats any change as an update;
# a pre-release suffix like -1 would sort BELOW the upstream release and never upgrade).
# rev resets to 1 when upstream's version changes and increments when vendored content
# changes under the same upstream version (tracked by .upstream-hash). Bump rev by hand
# for local-only changes (adapter, rule).
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/cursor/plugins.git "$tmp/cp"
git -C "$tmp/cp" sparse-checkout set pstack
src="$tmp/cp/pstack"
# Refuse to wipe plugin/ if upstream restructured or the clone came back empty.
[ "$(find "$src/skills" -name SKILL.md 2>/dev/null | wc -l)" -ge 10 ] && [ -f "$src/plugin.json" ] && [ -d "$src/agents" ] && [ -d "$src/docs/guide" ] \
  || { echo "sync: upstream layout unexpected, aborting" >&2; exit 1; }
rm -rf plugin/agents plugin/docs
# omp-adapter is ours; everything else under skills/ is upstream.
for d in plugin/skills/*/; do [ "$(basename "$d")" = omp-adapter ] || rm -rf "$d"; done
cp -R "$src/skills/." plugin/skills/
cp -R "$src/agents" plugin/agents
# skills link ../../docs/guide and ../../README.md relative to plugin/skills/<name>/
mkdir -p plugin/docs && cp -R "$src/docs/guide" plugin/docs/guide
cp "$src/README.md" plugin/README.md
cp "$src/LICENSE" LICENSE

up=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$src/plugin.json" | head -1)
[ -n "$up" ] || { echo "sync: no upstream version found" >&2; exit 1; }
# Fingerprint of the vendored files only (not our adapter, rule, or manifests).
h=$({ find plugin/skills plugin/agents plugin/docs -type f -not -path 'plugin/skills/omp-adapter/*'
      echo plugin/README.md; echo LICENSE; } | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | cut -d' ' -f1)
old=$(cat UPSTREAM_VERSION 2>/dev/null || true)
old_h=$(cat .upstream-hash 2>/dev/null || true)
if [ "$up" != "$old" ] || [ ! -f VERSION ]; then v="$up.1"
elif [ -n "$old_h" ] && [ "$h" != "$old_h" ]; then v="$up.$(( $(cut -d. -f4 VERSION) + 1 ))"
else v=$(cat VERSION); fi
echo "$up" > UPSTREAM_VERSION
echo "$h" > .upstream-hash
echo "$v" > VERSION
for f in plugin/.claude-plugin/plugin.json .omp-plugin/marketplace.json; do
  sed "s/\"version\": \"[^\"]*\"/\"version\": \"$v\"/" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
echo "synced upstream pstack $up as $v"
