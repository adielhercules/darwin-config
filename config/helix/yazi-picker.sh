#!/usr/bin/env bash
set -euo pipefail

chooser_file="$(mktemp)"
trap 'rm -f "${chooser_file}"' EXIT

yazi "$2" --chooser-file="${chooser_file}"

if [[ -s "${chooser_file}" ]]; then
  paths=()
  while IFS= read -r line || [[ -n "${line}" ]]; do
    paths+=("${line}")
  done < "${chooser_file}"

  args=""
  for path in "${paths[@]}"; do
    escaped="${path//\'/\'\\\'\'}"
    args="${args} '${escaped}'"
  done

  zellij action toggle-floating-panes
  zellij action write 27 # send <Escape> key
  sleep 0.1
  zellij action write-chars ":$1${args}"
  zellij action write 13 # send <Enter> key
else
  zellij action toggle-floating-panes
fi
