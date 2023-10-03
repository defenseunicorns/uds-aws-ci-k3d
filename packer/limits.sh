#!/bin/bash

set -e

# Inspired by https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/assets/scripts/developer/k3d-dev.sh#L356-384

sudo -- bash -c 'sysctl -w vm.max_map_count=524288; \
echo "vm.max_map_count=524288" > /etc/sysctl.d/vm-max_map_count.conf; \
sysctl -w fs.nr_open=13181252; \
echo "fs.nr_open=13181252" > /etc/sysctl.d/fs-nr_open.conf; \
sysctl -w fs.file-max=13181250; \
echo "fs.file-max=13181250" > /etc/sysctl.d/fs-file-max.conf; \
echo "fs.inotify.max_user_instances=1024" > /etc/sysctl.d/fs-inotify-max_user_instances.conf; \
sysctl -w fs.inotify.max_user_instances=1024; \
echo "fs.inotify.max_user_watches=1048576" > /etc/sysctl.d/fs-inotify-max_user_watches.conf; \
sysctl -w fs.inotify.max_user_watches=1048576; \
sysctl -p; \
echo "* soft nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* hard nofile 13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* soft nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
echo "* hard nproc  13181250" >> /etc/security/limits.d/ulimits.conf; \
modprobe br_netfilter; \
modprobe xt_REDIRECT; \
modprobe xt_owner; \
modprobe xt_statistic; \
echo "br_netfilter" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_REDIRECT" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_owner" >> /etc/modules-load.d/istio-iptables.conf; \
echo "xt_statistic" >> /etc/modules-load.d/istio-iptables.conf'
