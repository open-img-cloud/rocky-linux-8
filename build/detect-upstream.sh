#!/usr/bin/env bash
# Prints the latest upstream Rocky Linux 8 GenericCloud image version on stdout.
#
# Parses the directory listing at
#   https://dl.rockylinux.org/pub/rocky/8/images/x86_64/
# for versioned image names and prints the highest version
# (e.g. 8.10-20240528.0). Runs in the upstream-watch reusable workflow
# (no KVM needed): keep it portable bash + curl + grep + sort only.

set -euo pipefail

URL='https://dl.rockylinux.org/pub/rocky/8/images/x86_64/'

listing=$(curl -fsL "$URL")
if [[ -z "$listing" ]]; then
  echo "::error::could not fetch $URL" >&2
  exit 1
fi

latest=$(printf '%s\n' "$listing" \
  | grep -oE 'Rocky-8-GenericCloud-Base-(8\.[0-9]+-[0-9]{8}\.[0-9]+)\.x86_64\.qcow2' \
  | sed -E 's#Rocky-8-GenericCloud-Base-(8\.[0-9]+-[0-9]{8}\.[0-9]+)\.x86_64\.qcow2#\1#' \
  | sort -uV \
  | tail -n1)

if [[ -z "$latest" ]]; then
  echo "::error::no versioned Rocky Linux 8 GenericCloud image found in $URL" >&2
  exit 1
fi

printf '%s\n' "$latest"
