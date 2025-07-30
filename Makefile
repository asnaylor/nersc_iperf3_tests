# Makefile for iperf3 server/client deployment
# Usage: make <target>
# Targets:
#   help      Show this help message
#   server    Run iperf3 in server mode
#   client    Run iperf3 in client mode
#   shutdown  Kill iperf3 server process

# Configuration variables
SERVER_HET ?= 0
CLIENT_HET ?= 1
USE_SRUN ?= true
SERVER_ADDR ?= localhost
SERVER_ARGS ?= -p 5201
CLIENT_ARGS ?= -t 10

# Conditional command definitions
ifeq ($(USE_SRUN),true)
	SERVER_CMD = srun --het-group=$(SERVER_HET) iperf3 -s $(SERVER_ARGS)
	CLIENT_CMD = srun --het-group=$(CLIENT_HET) --overlap iperf3 -c $(SERVER_ADDR) $(CLIENT_ARGS) --json | python3 iperf3_parse.py
	SHUTDOWN_PATTERN = "srun.*iperf3.*-s"
else
	SERVER_CMD = iperf3 -s $(SERVER_ARGS)
	CLIENT_CMD = iperf3 -c $(SERVER_ADDR) $(CLIENT_ARGS) --json | python3 iperf3_parse.py
	SHUTDOWN_PATTERN = "iperf3.*-s"
endif

.PHONY: help server client shutdown

# Default target
all: help

help:
	@echo "🚀 iperf3 Deployment Makefile"
	@echo "════════════════════════════════"
	@echo ""
	@echo "📋 USAGE:"
	@echo "   make <target> [VARIABLE=value]"
	@echo ""
	@echo "🎯 TARGETS:"
	@echo "   help      📖 Show this help message"
	@echo "   server    🖥️  Run iperf3 in server mode"
	@echo "   client    📡 Run iperf3 in client mode"
	@echo "   shutdown  🛑 Kill iperf3 server process"
	@echo ""
	@echo "⚙️  VARIABLES:"
	@echo "   SERVER_HET   🏷️  Server het group (default: $(SERVER_HET))"
	@echo "   CLIENT_HET   🏷️  Client het group (default: $(CLIENT_HET))"
	@echo "   USE_SRUN     🔧 Use srun command (default: $(USE_SRUN))"
	@echo "   SERVER_ADDR  🌐 Server address (default: $(SERVER_ADDR))"
	@echo "   SERVER_ARGS  📝 iperf3 server arguments (default: $(SERVER_ARGS))"
	@echo "   CLIENT_ARGS  📝 iperf3 client arguments (default: $(CLIENT_ARGS))"
	@echo ""
	@echo "💡 EXAMPLES:"
	@echo "   make server SERVER_ARGS='-p 5202 -D'"
	@echo "   make client SERVER_ADDR=node01 CLIENT_ARGS='-t 30 -P 4'"
	@echo "   make client SERVER_ADDR=192.168.1.100 CLIENT_ARGS='-t 60 -u -b 100M'"
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

shutdown:
	@echo "🛑 Shutting Down iperf3 Server"
	@echo "══════════════════════════════"
	@echo ""
	@echo "🔍 Looking for running iperf3 servers..."
ifeq ($(USE_SRUN),true)
	@echo "🎯 Target: SLURM iperf3 processes"
	-@if pkill -f $(SHUTDOWN_PATTERN) 2>/dev/null; then \
		echo "✅ SLURM iperf3 server stopped successfully"; \
	else \
		echo "ℹ️  No SLURM iperf3 server found running"; \
	fi
else
	@echo "🎯 Target: Local iperf3 processes"
	-@if pkill -f $(SHUTDOWN_PATTERN) 2>/dev/null; then \
		echo "✅ Local iperf3 server stopped successfully"; \
	else \
		echo "ℹ️  No local iperf3 server found running"; \
	fi
endif
	@echo ""