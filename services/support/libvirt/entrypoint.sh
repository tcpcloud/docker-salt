#!/bin/bash
chmod 666 /dev/kvm
exec "$@"
