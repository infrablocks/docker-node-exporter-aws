FROM infrablocks/alpine-aws-s3-config:0.22.0

ENV NODE_EXPORTER_VERSION="1.0.1"

RUN apk \
    --verbose \
    --no-cache \
    add \
        su-exec

RUN cd /tmp \
    && curl \
        -L "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
        -o "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    && tar -xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    && mkdir -p /opt/node-exporter \
    && cp -R "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"/* /opt/node-exporter \
    && mkdir -p /opt/node-exporter/bin \
    && mv /opt/node-exporter/node_exporter /opt/node-exporter/bin/ \
    && rm "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" \
    && rm -rf "node_exporter-${PROMETHEUS_VERSION}.linux-amd64" \
    && cd /

COPY start.sh /opt/node-exporter/bin/start.sh

RUN chmod +x /opt/node-exporter/bin/start.sh

ENV STARTUP_SCRIPT_PATH=/opt/node-exporter/bin/start.sh
