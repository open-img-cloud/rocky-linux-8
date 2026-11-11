#!/usr/bin/env bash
# Customize hook called by the build-libguestfs-image reusable workflow.
# Receives the qcow2 path as $1.
#
# The upstream Rocky Linux 8 GenericCloud image already ships cloud-init,
# openssh-server, qemu-guest-agent, a serial console and the `rocky`
# default user. The org-wide cloud-init policy drop-in (datasource_list,
# disable_root, ssh_pwauth=false, mount_default_fields) is injected by the
# reusable workflow after this script runs. Customisation reduces to a
# package cache cleanup so the published qcow2 stays small.

set -euo pipefail

QCOW2="${1:?usage: customize.sh <path-to-qcow2>}"

if [[ ! -f "$QCOW2" ]]; then
  echo "::error::qcow2 not found: $QCOW2" >&2
  exit 1
fi

echo "[customize] target: $QCOW2"

# RHEL 8's cloud-init 23.4 backport (also in Oracle's OL8 rebuild) calls
# util.load_text_file(), a name that only exists from cloud-init 24.1
# (util.load_file() in 23.4); it crashes init-local while rendering DNS.
# Rename the calls only while util.py lacks load_text_file (no-op on a
# fixed package).
CI_FIX='d=$(ls -d /usr/lib/python3*/site-packages/cloudinit 2>/dev/null | head -n1); \
if [ -n "$d" ] && ! grep -q "def load_text_file" "$d/util.py"; then \
  grep -rl "util\.load_text_file(" "$d" --include=*.py | xargs -r sed -i "s/util\.load_text_file(/util.load_file(/g"; \
  find "$d" -name "*.pyc" -delete; \
  echo "cloud-init: load_text_file calls renamed"; \
fi'

virt-customize -a "$QCOW2" \
  --run-command "$CI_FIX" \
  --run-command 'rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*'

echo "[customize] done"
