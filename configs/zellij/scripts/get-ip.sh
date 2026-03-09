#!/bin/bash
ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[\d.]+' || ip -4 addr show eth0 2>/dev/null | grep -oP 'inet \K[\d.]+' || echo 'no ip'
