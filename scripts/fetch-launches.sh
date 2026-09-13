#!/usr/bin/env bash
set -euo pipefail

readonly API_URL='https://ll.thespacedevs.com/2.3.0/launches/upcoming/?lsp__id=121&status__ids=1,2,5,6,8&ordering=net&limit=4&mode=detailed'
readonly CACHE_TTL_SECONDS=900
readonly EXPIRES_AFTER_SECONDS=2400
readonly RETRY_DELAY_SECONDS=120

source_file=""
cache_path="${XDG_CACHE_HOME:-$HOME/.cache}/oma-space-launch/launches.json"
force_refresh=false

usage() {
    echo "Usage: $0 [--from FILE] [--cache PATH] [--force]" >&2
}

while (($#)); do
    case "$1" in
        --from)
            source_file="${2:?--from requires a file}"
            shift 2
            ;;
        --cache)
            cache_path="${2:?--cache requires a path}"
            shift 2
            ;;
        --force)
            force_refresh=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

cache_dir="$(dirname "$cache_path")"
mkdir -p "$cache_dir"
exec 9>"${cache_path}.lock"
flock -n 9 || exit 0

now_seconds="$(date -u +%s)"
if ! "$force_refresh" && [[ -f "$cache_path" ]]; then
    cache_mtime="$(stat -c %Y "$cache_path")"
    if ((now_seconds - cache_mtime < CACHE_TTL_SECONDS)) \
        && jq -e '.schemaVersion == 2' "$cache_path" >/dev/null 2>&1; then
        exit 0
    fi
fi

if [[ -n "$source_file" ]]; then
    [[ -f "$source_file" ]] || { echo "fixture not found: $source_file" >&2; exit 2; }
    payload="$(<"$source_file")"
elif ! payload="$(curl --fail --silent --show-error --max-time 20 "$API_URL")"; then
    sleep "$RETRY_DELAY_SECONDS"
    payload="$(curl --fail --silent --show-error --max-time 20 "$API_URL")"
fi

fetched_at="$(date -u -d "@${now_seconds}" +%Y-%m-%dT%H:%M:%SZ)"
expires_at="$(date -u -d "@$((now_seconds + EXPIRES_AFTER_SECONDS))" +%Y-%m-%dT%H:%M:%SZ)"
temporary_cache="$(mktemp "${cache_dir}/.launches.XXXXXX")"
trap 'rm -f "$temporary_cache"' EXIT

printf '%s' "$payload" | jq --arg fetchedAt "$fetched_at" --arg expiresAt "$expires_at" '
    def timePrecision:
        (.net_precision.id // 99) as $precision
        | if $precision <= 2 then "exact"
          elif $precision <= 6 then "net"
          else "tbd"
          end;
    def launch:
        {
            id: .id,
            name: (.name // "SpaceX launch"),
            net: .net,
            timePrecision: timePrecision,
            statusId: (.status.id // null),
            statusName: (.status.name // ""),
            site: ([.pad.name, .pad.location.name] | map(select(. != null and . != "")) | join(", ")),
            rocket: (.rocket.configuration.full_name // ""),
            rocketFamily: (.rocket.configuration.name // ""),
            mission: (.mission.name // ""),
            referenceUrl: (([.info_urls[]? | select(.source == "spacex.com" and (.url | type == "string") and (.url | startswith("https://"))) | .url][0]) // "https://www.spacex.com/launches/"),
            outcomeConfirmed: false
        };
    [ .results[]?
      | select(.status.id == 1 or .status.id == 2 or .status.id == 5 or .status.id == 6 or .status.id == 8)
      | launch ] as $launches
    | {
        schemaVersion: 2,
        fetchedAt: $fetchedAt,
        expiresAt: $expiresAt,
        launches: $launches[:4]
      }
' > "$temporary_cache"

mv "$temporary_cache" "$cache_path"
trap - EXIT
