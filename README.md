# iperf3 Load Balancer Testing Suite for NERSC

A toolkit for testing network bandwidth using iperf3 through an Envoy load balancer on NERSC supercomputing systems.

## 🎯 Overview

Test network performance across NERSC compute nodes by deploying iperf3 servers, an Envoy load balancer, and running bandwidth tests.

> [!NOTE]  
> The installed iperf3 version on NERSC is 3.5. iperf3 was made multi-threaded in version 3.16 (released December 2023), which helps achieve better throughput when you are core limited (often the case for 40G or 100G hosts) by allowing parallel streams (`-P`) to use multiple cores. You can download a newer version from iperf [github](https://github.com/esnet/iperf).

## 🚀 Quick Start

### 1. Setup Environment
```bash
git clone git@github.com:asnaylor/nersc_iperf3_tests.git
cd nersc_iperf3_tests
```

### 2. Allocate SLURM Heterogeneous Job
```bash
# Request 3 nodes (server, client, load balancer)
salloc -q interactive -t 60 -A <account> -N 1 -C cpu : -A <account> -N 1 -C cpu : -A <account> -N 1 -C cpu
```

### 3. Run Tests
```bash
# Start iperf3 server (het group 0)
make server

# Run client test (het group 1)
make client SERVER_ADDR=nid001234 

# Deploy load balancer (het group 2)
make lb LB_NODES='nid001234:5201'

# Test through load balancer
make client SERVER_ADDR=nid001235 CLIENT_ARGS="-p 9191 -P 2"
```

> [!NOTE]  
> Users can specify `USE_SRUN=false` to disable slurm mode for local testing

## 📖 Makefile Targets

| Target | Description |
|--------|-------------|
| `make help` | Show all available options and examples |
| `make server` | Start iperf3 server |
| `make client` | Run iperf3 client test |
| `make lb` | Deploy Envoy load balancer |
| `make shutdown` | Stop iperf3 server |
| `make shutdown-lb` | Stop load balancer |

Run `make help` for detailed usage information and more examples.

## 📊 Performance Results

**Test Environment:**
- **System**: NERSC Perlmutter
- **Date**: August 2025
- **iperf3 Version**: 3.19.1
- **Test Parameters**: 10 second duration (-t 10), 1 second intervals (-i 1)

### Direct Connections
| Connection | Single Stream | Multi-Stream (16×) |
|------------|---------------|-------------------|
| **Node A → Node B** | 20.6 Gbps | **87.6 Gbps** |
| **DTN → Node B** | **29.1 Gbps** | - |

### Through Load Balancer
| Connection | Single Stream | Multi-Stream (16×) |
|------------|---------------|-------------------|
| **Node A → Node B** | 14.9 Gbps | **84.0 Gbps** |
| **DTN → Node B** | **15.1 Gbps** | - |

> [!NOTE]  
> These are simple baseline tests. Performance may vary. DTN nodes are expected to benefit significantly from multi-streaming similar to compute nodes.

## 📊 Optional: Metrics Monitoring

For users who want to monitor system and network metrics during testing, see the [NERSC metrics scripts](https://github.com/asnaylor/nersc-metrics-scripts) that deploy Prometheus, Grafana, and collectors:

```bash
# Download and install
git clone git@github.com:asnaylor/nersc-metrics-scripts.git
cd nersc-metrics-scripts && make all

# Deploy monitoring stack (from JupyterHub)
./start_grafana_prometheus.sh

# Start collectors on compute nodes
./start_node_exporter_collector.sh http://hostname:8080 &
./start_envoy_collector.sh http://hostname:8080 &
```

This provides real-time dashboards for CPU, memory, network, and GPU utilization during bandwidth tests. See the included metrics documentation for full setup details.