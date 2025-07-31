#!/usr/bin/env bash

SERVER_NODES="$@"
IFS=',' read -r -a SERVER_NODES_ARRAY <<< "$SERVER_NODES"

# Create temp file
TMPFILE=$(mktemp envoy-config.XXXXXX.yaml)

# Generate the YAML config
cat envoy-config.yaml > ${TMPFILE}

for i in "${!SERVER_NODES_ARRAY[@]}"; do
    IFS=: read -r NODE PORT <<< "${SERVER_NODES_ARRAY[$i]}"

    yq w -i ${TMPFILE} "static_resources.clusters[0].load_assignment.endpoints[0].lb_endpoints[$i].endpoint.address.socket_address.address" "$NODE"
    yq w -i ${TMPFILE} "static_resources.clusters[0].load_assignment.endpoints[0].lb_endpoints[$i].endpoint.address.socket_address.port_value" "$PORT"
done

echo "${TMPFILE}"