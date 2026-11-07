#!/usr/bin/env bash
set -euo pipefail

readonly API_URL='https://ll.thespacedevs.com/2.3.0/launches/upcoming/?lsp__id=121&status__ids=1,2,5,6,8&ordering=net&limit=4&mode=detailed'
readonly CACHE_TTL_SECONDS=900
readonly EXPIRES_AFTER_SECONDS=2400
readonly RETRY_DELAY_SECONDS=120
# Four detailed launches fit comfortably within this download budget. Keep all
# raw response bytes out of shell variables and the shared desktop shell.
readonly MAX_RESPONSE_BYTES=1048576
readonly MAX_CACHE_BYTES=65536

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
        && jq -e '.schemaVersion == 3' "$cache_path" >/dev/null 2>&1; then
        exit 0
    fi
fi

temporary_dir="$(mktemp -d "${cache_dir}/.fetch.XXXXXX")"
trap 'rm -rf -- "$temporary_dir"' EXIT
payload_file="${temporary_dir}/response.json"
temporary_cache="${temporary_dir}/launches.json"

download() {
    curl --fail --silent --show-error --max-time 20 \
        --max-filesize "$MAX_RESPONSE_BYTES" --output "$payload_file" "$API_URL"
}

if [[ -n "$source_file" ]]; then
    [[ -f "$source_file" ]] || { echo "fixture not found: $source_file" >&2; exit 2; }
    head -c "$((MAX_RESPONSE_BYTES + 1))" -- "$source_file" > "$payload_file"
elif download; then
    :
else
    download_status=$?
    # A size rejection is permanent for this response; do not retry it.
    if ((download_status == 63)); then exit "$download_status"; fi
    sleep "$RETRY_DELAY_SECONDS"
    download
fi

if (($(wc -c < "$payload_file") > MAX_RESPONSE_BYTES)); then
    echo "launch response exceeds $MAX_RESPONSE_BYTES bytes" >&2
    exit 1
fi

fetched_at="$(date -u -d "@${now_seconds}" +%Y-%m-%dT%H:%M:%SZ)"
expires_at="$(date -u -d "@$((now_seconds + EXPIRES_AFTER_SECONDS))" +%Y-%m-%dT%H:%M:%SZ)"

jq --arg fetchedAt "$fetched_at" --arg expiresAt "$expires_at" '
    # Bound every copied string, including URLs and fields not shown in the UI.
    # Reject invalid input instead of silently shortening a launch or its URL.
    def boundedText($fallback; $limit):
        if . == null then $fallback
        elif type != "string" then error("expected a launch text field")
        elif utf8bytelength > $limit then error("launch text field exceeds \($limit) bytes")
        else . end;
    def timePrecision:
        (.net_precision.id // 99) as $precision
        | if $precision <= 2 then "exact"
          elif $precision <= 6 then "net"
          else "tbd"
          end;
    def launch:
        {
            id: (.id | boundedText(null; 128)),
            name: (.name | boundedText("SpaceX launch"; 256)),
            net: (.net | boundedText(null; 64)),
            timePrecision: timePrecision,
            statusId: (.status.id // null),
            statusName: (.status.name | boundedText(""; 64)),
            site: ([.pad.name, .pad.location.name] | map(boundedText(""; 256)) | map(select(. != "")) | join(", ") | boundedText(""; 512)),
            rocket: (.rocket.configuration.full_name | boundedText(""; 128)),
            rocketFamily: (.rocket.configuration.name | boundedText(""; 64)),
            mission: (.mission.name | boundedText(""; 256)),
            referenceUrl: (([.info_urls[]? | select(.source == "spacex.com" and (.url | type == "string") and (.url | startswith("https://"))) | .url][0]) // "https://www.spacex.com/launches/" | boundedText(null; 2048)),
            webcastUrl: ([.vid_urls[]? | select((.url | type == "string") and (.url | startswith("https://")))] | sort_by(.priority // infinite) | .[0].url // null | boundedText(null; 2048)),
            outcomeConfirmed: false
        };
    [ .results[]?
      | select(.status.id == 1 or .status.id == 2 or .status.id == 5 or .status.id == 6 or .status.id == 8)
      | launch ] as $launches
    | {
        schemaVersion: 3,
        fetchedAt: $fetchedAt,
        expiresAt: $expiresAt,
        launches: $launches[:4]
      }
' "$payload_file" > "$temporary_cache"

if (($(wc -c < "$temporary_cache") > MAX_CACHE_BYTES)); then
    echo "launch cache exceeds $MAX_CACHE_BYTES bytes" >&2
    exit 1
fi

mv "$temporary_cache" "$cache_path"
