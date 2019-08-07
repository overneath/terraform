#!/bin/sh
set -e
cat << EOF > provider.tf
provider "${1?usage: $0 <name> <version>}" {
    version = "${2?usage: $0 <name> <version>}"
}
EOF
