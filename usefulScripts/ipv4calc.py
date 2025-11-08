#!/usr/bin/env python3
"""
ipv4calc.py — tiny IPv4 calculator

Usage:
  ipv4calc.py 192.168.2.179/24
  ipv4calc.py 10.0.0.5 /16
  ipv4calc.py 10.0.0.5 255.255.0.0
"""
from __future__ import annotations
import argparse
import ipaddress
import sys

def parse_args():
    p = argparse.ArgumentParser(description="IPv4 calculator")
    p.add_argument("ip", help="IPv4 address (with or without prefix)")
    p.add_argument("mask", nargs="?", help="Optional: /prefix or dotted mask (e.g. /24 or 255.255.255.0)")
    return p.parse_args()

def to_interface(ip_str: str, mask: str | None) -> ipaddress.IPv4Interface:
    # Accept forms:
    #  - 192.168.1.10/24
    #  - 192.168.1.10 /24
    #  - 192.168.1.10 255.255.255.0
    if "/" in ip_str and mask:
        sys.exit("Give either CIDR in the first arg OR a separate mask—not both.")
    if mask:
        mask = mask.lstrip("/")
        # If mask looks like dotted decimal, convert to prefix
        if "." in mask:
            try:
                prefix = ipaddress.IPv4Network(f"0.0.0.0/{mask}").prefixlen
            except Exception:
                sys.exit(f"Invalid netmask: {mask}")
        else:
            try:
                prefix = int(mask)
            except ValueError:
                sys.exit(f"Invalid prefix: {mask}")
        cidr = f"{ip_str}/{prefix}"
    else:
        cidr = ip_str
    try:
        return ipaddress.IPv4Interface(cidr)
    except Exception as e:
        sys.exit(f"Invalid input: {cidr} ({e})")

def first_last_usable(net: ipaddress.IPv4Network):
    # RFC 3021: /31 has two usable addresses (point-to-point).
    # /32 has exactly one address and no range.
    if net.prefixlen == 32:
        return (None, None, 0)
    if net.prefixlen == 31:
        hosts = list(net.hosts())
        return (hosts[0], hosts[1], 2)
    # normal case
    hosts = list(net.hosts())
    if not hosts:
        return (None, None, 0)
    return (hosts[0], hosts[-1], len(hosts))

def main():
    args = parse_args()
    iface = to_interface(args.ip, args.mask)
    ip = iface.ip
    net = iface.network

    wildcard = ipaddress.IPv4Address(int(net.hostmask))
    first, last, usable = first_last_usable(net)
    gw = first if first else None  # common default

    print("IPv4 calculator")
    print("-" * 60)
    print(f"{'IP address:':18} {ip}")
    print(f"{'Prefix:':18} /{iface.network.prefixlen}")
    print(f"{'Netmask:':18} {net.netmask}")
    print(f"{'Wildcard mask:':18} {wildcard}")
    print(f"{'Network:':18} {net.network_address}")
    print(f"{'Broadcast:':18} {net.broadcast_address}")
    if usable == 0:
        print(f"{'Usable hosts:':18} 0  (no usable range for /32; /31 is point-to-point)")
        print(f"{'Host range:':18} n/a")
    else:
        print(f"{'Usable hosts:':18} {usable}")
        print(f"{'Host range:':18} {first} – {last}")
    if gw:
        print(f"{'Suggested GW:':18} {gw}")
    print(f"{'Reverse PTR:':18} {ip.reverse_pointer}")
    print("-" * 60)

if __name__ == "__main__":
    main()
