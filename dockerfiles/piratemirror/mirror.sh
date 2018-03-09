#!/bin/bash
set -xeou pipefail

prod=${1:-/host/repo}
stage=${2:-/host/staging}
ref="fedora/27/x86_64/workstation"

if [[ ! -d "$prod" ]] || [[ ! -d "$stage" ]]; then
    echo "Must have 'staging' and 'repo' directories present"
    exit 1
fi

ostree --repo=$stage remote add --if-not-exists --set gpgkeypath=/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-27-primary onerepo https://kojipkgs.fedoraproject.org/atomic/repo/
ostree --repo=$stage pull --commit-metadata-only --depth=1 onerepo:$ref
rhead=$(ostree --repo=$stage rev-parse onerepo:$ref)
lhead=$(ostree --repo=$prod rev-parse $ref)

if [[ "$rhead" != "$lhead" ]]; then
    ostree --repo=$stage pull --mirror --depth=1 onerepo:$ref
    ostree --repo=$stage prune --keep-younger-than="7 days ago" $ref
    ostree --repo=$stage summary -u
    /root/rsync-repos --src $stage --dest $prod
fi