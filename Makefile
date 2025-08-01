# Makefile for iperf3 server/client deployment with Envoy load balancer
# Usage: make <target>
# Targets:
#   help      Show this help message
#   server    Run iperf3 in server mode
#   client    Run iperf3 in client mode
#   lb        Deploy Envoy load balancer
#   shutdown  Kill iperf3 server process
#   shutdown-lb Kill Envoy load balancer process

# Configuration variables
SERVER_HET ?= 0
CLIENT_HET ?= 1
LB_HET ?= 2
USE_SRUN ?= true
SERVER_ADDR ?= 
SERVER_ARGS ?= 
CLIENT_ARGS ?= 
ENVOY_IMAGE ?= envoyproxy/envoy:v1.34.0
LB_NODES ?= 
LB_PORT ?= 9191

# Conditional command definitions
ifeq ($(USE_SRUN),true)
	SERVER_CMD = srun --label --het-group=$(SERVER_HET) iperf3 -s $(SERVER_ARGS)
	CLIENT_CMD = srun --het-group=$(CLIENT_HET) --overlap iperf3 -c $(SERVER_ADDR) $(CLIENT_ARGS) --json | python3 iperf3_parse.py
	LB_CMD = srun --het-group=$(LB_HET) --overlap shifter --module=none --image=$(ENVOY_IMAGE) envoy -c 
	SHUTDOWN_PATTERN = "srun.*iperf3.*-s"
	LB_SHUTDOWN_PATTERN = "srun.*envoy"
else
	SERVER_CMD = iperf3 -s $(SERVER_ARGS)
	CLIENT_CMD = iperf3 -c $(SERVER_ADDR) $(CLIENT_ARGS) --json | python3 iperf3_parse.py
	LB_CMD = shifter --module=none --image=$(ENVOY_IMAGE) envoy -c 
	SHUTDOWN_PATTERN = "iperf3.*-s"
	LB_SHUTDOWN_PATTERN = "envoy"
endif

.PHONY: help server client lb shutdown shutdown-lb

# Default target
all: help

help:
	@echo "🚀 iperf3 Deployment Makefile with Envoy Load Balancer"
	@echo "═══════════════════════════════════════════════════════"
	@echo ""
	@echo "📋 USAGE:"
	@echo "   make <target> [VARIABLE=value]"
	@echo ""
	@echo "🎯 TARGETS:"
	@echo "   help        📖 Show this help message"
	@echo "   server      🖥️  Run iperf3 in server mode"
	@echo "   client      📡 Run iperf3 in client mode"
	@echo "   lb          ⚖️  Deploy Envoy load balancer"
	@echo "   shutdown    🛑 Kill iperf3 server process"
	@echo "   shutdown-lb 🛑 Kill Envoy load balancer process"
	@echo ""
	@echo "⚙️  VARIABLES:"
	@echo "   SERVER_HET   🏷️  Server het group (default: $(SERVER_HET))"
	@echo "   CLIENT_HET   🏷️  Client het group (default: $(CLIENT_HET))"
	@echo "   LB_HET       🏷️  Load balancer het group (default: $(LB_HET))"
	@echo "   USE_SRUN     🔧 Use srun command (default: $(USE_SRUN))"
	@echo "   SERVER_ADDR  🌐 Server address (default: $(SERVER_ADDR))"
	@echo "   SERVER_ARGS  📝 iperf3 server arguments (default: $(SERVER_ARGS))"
	@echo "   CLIENT_ARGS  📝 iperf3 client arguments (default: $(CLIENT_ARGS))"
	@echo "   LB_NODES     🎯 Load balancer backend nodes (default: $(LB_NODES))"
#	@echo "   LB_PORT      🔌 Load balancer listen port (default: $(LB_PORT))"
	@echo "   ENVOY_IMAGE  🐳 Envoy Docker image (default: $(ENVOY_IMAGE))"
	@echo ""
	@echo "💡 EXAMPLES:"
	@echo "   make server SERVER_ARGS='-p 5202 -D'"
	@echo "   make client SERVER_ADDR=node01 CLIENT_ARGS='-t 30 -P 4'"
	@echo "   make lb LB_NODES='node01:5201,node02:5201,node03:5201'"
	@echo "   make client SERVER_ADDR=localhost:8080 CLIENT_ARGS='-t 60'"
	@echo ""

server: 
	@echo "🖥️  Starting iperf3 Server"
	@echo "═══════════════════════════"
	@echo ""
ifeq ($(USE_SRUN),true)
	@echo "🚀 Mode: SLURM (srun)"
	@echo "🏷️  Het Group: $(SERVER_HET)"
else
	@echo "🚀 Mode: Local execution"
endif
	@echo "📝 Command: $(SERVER_CMD)"
	@echo ""
	@echo "⏳ Starting server in background..."
	$(SERVER_CMD) &
	@echo "✅ Server started successfully!"
	@echo "💡 Use 'make shutdown' to stop the server"
	@echo ""

client:
	@echo "📡 Starting iperf3 Client"
	@echo "═════════════════════════"
	@echo ""
ifeq ($(USE_SRUN),true)
	@echo "🚀 Mode: SLURM (srun)"
	@echo "🏷️  Het Group: $(CLIENT_HET)"
else
	@echo "🚀 Mode: Local execution"
endif
	@echo "🌐 Target Server: $(SERVER_ADDR)"
	@echo "📝 Command: $(CLIENT_CMD)"
	@echo ""
	@echo "⏳ Starting performance test..."
	@echo "────────────────────────────────────────────────────────────────────────────────"
	$(CLIENT_CMD)
	@echo "────────────────────────────────────────────────────────────────────────────────"
	@echo "✅ Test completed!"
	@echo ""

lb:
	@echo "⚖️  Deploying Envoy Load Balancer"
	@echo "═════════════════════════════════"
	@echo ""
ifeq ($(USE_SRUN),true)
	@echo "🚀 Mode: SLURM (srun)"
	@echo "🏷️  Het Group: $(LB_HET)"
else
	@echo "🚀 Mode: Local execution"
endif
	@echo "🎯 Backend Nodes: $(LB_NODES)"
	@echo "🔌 Listen Port: $(LB_PORT)"
	@echo "🐳 Envoy Image: $(ENVOY_IMAGE)"
	@echo ""
	@echo "⏳ Generating Envoy configuration..."
	$(eval ENVOY_CONFIG := $(shell ./generate_envoy_config.sh $(LB_NODES)))
	@echo "📄 Config file: $(ENVOY_CONFIG)"
	@echo ""
	@echo "⏳ Starting Envoy load balancer in background..."
	$(LB_CMD) $(ENVOY_CONFIG) &
	@echo "✅ Envoy load balancer started successfully!"
	@echo "🌐 Load balancer available at: localhost:$(LB_PORT)"
	@echo "💡 Use 'make shutdown-lb' to stop the load balancer"
	@echo ""

shutdown:
	@echo "🛑 Shutting Down iperf3 Server"
	@echo "══════════════════════════════"
	@echo ""
	@echo "🔍 Looking for running iperf3 servers..."
	-@pkill -f $(SHUTDOWN_PATTERN)
	@echo ""

shutdown-lb:
	@echo "🛑 Shutting Down Envoy Load Balancer"
	@echo "════════════════════════════════════"
	@echo ""
	@echo "🔍 Looking for running Envoy processes..."
	-@pkill -f $(LB_SHUTDOWN_PATTERN)
	@echo ""
	@echo "🧹 Cleaning up temporary config files..."
	-@rm -f envoy-config.*.yaml 2>/dev/null || true
	@echo "✅ Cleanup completed!"
	@echo ""