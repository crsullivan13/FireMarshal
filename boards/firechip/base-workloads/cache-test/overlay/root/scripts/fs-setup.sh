#!/bin/bash

mount -t debugfs none /sys/kernel/debug
mount -t tmpfs cgroup_root /sys/fs/cgroup