#!/bin/sh -e

tr / '\013' \
| sort ${1+"$@"} \
| tr '\013' /
