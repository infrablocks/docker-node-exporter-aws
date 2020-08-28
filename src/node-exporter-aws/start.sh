#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

NODE_EXPORTER_PORT="${NODE_EXPORTER_PORT:-9100}"

NODE_EXPORTER_PATH_ROOTFS="${NODE_EXPORTER_PATH_ROOTFS:-/host}"
NODE_EXPORTER_PATH_PROCFS="${NODE_EXPORTER_PATH_PROCFS:-/proc}"
NODE_EXPORTER_PATH_SYSFS="${NODE_EXPORTER_PATH_SYSFS:-/sys}"

NODE_EXPORTER_LOG_LEVEL="${NODE_EXPORTER_LOG_LEVEL:-info}"
NODE_EXPORTER_LOG_FORMAT="${NODE_EXPORTER_LOG_FORMAT:-json}"

NODE_EXPORTER_COLLECTOR_FILESYSTEM_IGNORED_MOUNT_POINTS=\
"${NODE_EXPORTER_COLLECTOR_FILESYSTEM_IGNORED_MOUNT_POINTS:-^/(dev|proc|run|sys|host|var/lib/docker/.+)($|/)}"

echo "Running node exporter."
exec su-exec nobody:nobody /opt/node-exporter/bin/node_exporter \
  --web.listen-address=":${NODE_EXPORTER_PORT}" \
  \
  --path.rootfs="${NODE_EXPORTER_PATH_ROOTFS}" \
  --path.procfs="${NODE_EXPORTER_PATH_PROCFS}" \
  --path.sysfs="${NODE_EXPORTER_PATH_SYSFS}" \
  \
  --collector.filesystem.ignored-mount-points="${NODE_EXPORTER_COLLECTOR_FILESYSTEM_IGNORED_MOUNT_POINTS}" \
  \
  --log.format="${NODE_EXPORTER_LOG_FORMAT}" \
  --log.level="${NODE_EXPORTER_LOG_LEVEL}"
