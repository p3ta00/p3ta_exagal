#!/bin/bash
pwd | sed 's|^/root|~|' | awk -F/ '{if(length($0)>32){if(NF>4)print $1"/"$2"/…/"$(NF-1)"/"$NF;else print $0}else print $0}'
