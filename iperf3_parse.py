#!/usr/bin/env python3
import sys
import json
from typing import Dict, List, Optional

def parse_iperf3_json(json_data: str) -> Optional[Dict]:
    """Parse iperf3 JSON output from string.
    
    Args:
        json_data (str): Raw JSON string from iperf3
        
    Returns:
        Optional[Dict]: Parsed JSON data or None if parsing fails
    """
    try:
        return json.loads(json_data)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        return None

def check_for_iperf3_error(results: Dict) -> bool:
    """Check if iperf3 results contain an error and print it.
    
    Args:
        results (Dict): Parsed JSON results from iperf3
        
    Returns:
        bool: True if error found, False otherwise
    """
    error_msg = results.get('error')
    if error_msg:
        print("=== iperf3 Error ===", file=sys.stderr)
        print(f"Error: {error_msg}", file=sys.stderr)
        return True
    return False

def print_test_summary(results: Dict) -> None:
    """Print key metrics from iperf3 test results.
    
    Args:
        results (Dict): Parsed JSON results from iperf3
    """
    # Extract basic test info
    start_info = results.get('start', {})
    connected = start_info.get('connected', [{}])[0]
    test_start = start_info.get('test_start', {})
    
    print("=== iperf3 Test Results ===")
    print(f"Server: {connected.get('remote_host', 'Unknown')}:{connected.get('remote_port', 'Unknown')}")
    print(f"Protocol: {start_info.get('test_start', {}).get('protocol', 'Unknown')}")
    print(f"Duration: {test_start.get('duration', 'Unknown')} seconds")
    print(f"Parallel streams: {test_start.get('num_streams', 'Unknown')}")
    
    # Extract end summary
    end_summary = results.get('end', {})
    sum_sent = end_summary.get('sum_sent', {})
    sum_received = end_summary.get('sum_received', {})
    
    print("\n=== Summary ===")

    # Sent data (upload)
    if sum_sent:
        sent_gbps = sum_sent.get('bits_per_second', 0) / 1_000_000_000
        sent_gb = sum_sent.get('bytes', 0) / 1_000_000_000
        retransmits = sum_sent.get('retransmits', 0)
        print(f"Upload:   {sent_gb:8.3f} GBytes  {sent_gbps:8.3f} Gbits/sec  {retransmits} retransmits")
    
    # Received data (download from server perspective)
    if sum_received:
        recv_gbps = sum_received.get('bits_per_second', 0) / 1_000_000_000
        recv_gb = sum_received.get('bytes', 0) / 1_000_000_000
        print(f"Download: {recv_gb:8.3f} GBytes  {recv_gbps:8.3f} Gbits/sec")

def print_cpu_usage(results: Dict) -> None:
    """Print CPU utilization data if available.
    
    Args:
        results (Dict): Parsed JSON results from iperf3
    """
    end_summary = results.get('end', {})
    cpu_util_total = end_summary.get('cpu_utilization_percent', {})
    
    if cpu_util_total:
        host_total = cpu_util_total.get('host_total', 0)
        remote_total = cpu_util_total.get('remote_total', 0)
        
        print(f"\n=== CPU Utilization ===")
        print(f"Local:  {host_total:.1f}%")
        print(f"Remote: {remote_total:.1f}%")

def main() -> None:
    """Main function to read stdin and parse iperf3 JSON output."""
    if sys.stdin.isatty():
        print("Usage: iperf3 -c server --json | python3 iperf3_parser.py", file=sys.stderr)
        print("   or: python3 iperf3_parser.py < iperf3_output.json", file=sys.stderr)
        sys.exit(1)
    
    # Read all input from stdin
    try:
        json_input = sys.stdin.read()
    except KeyboardInterrupt:
        sys.exit(1)
    
    if not json_input.strip():
        print("No input received", file=sys.stderr)
        sys.exit(1)
    
    # Parse the JSON
    results = parse_iperf3_json(json_input)
    if not results:
        sys.exit(1)

    # Check for iperf3 errors first
    if check_for_iperf3_error(results):
        sys.exit(1)
    
    # Print formatted output
    print_test_summary(results)
    print_cpu_usage(results)

if __name__ == "__main__":
    main()