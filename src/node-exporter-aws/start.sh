#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running node exporter."
exec /opt/node-exporter/bin/node_exporter
