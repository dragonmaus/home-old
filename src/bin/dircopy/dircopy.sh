#!/bin/sh -e

. $HOME/lib/sh/stdlib.sh

usage() (die 100 usage 'dircopy [-vx] source target')

v= x=
while getopts vx opt; do
  case $opt in
  v|x) eval $opt=$opt;;
  *) usage;;
  esac
done
shift `expr $OPTIND - 1`

s=$1
t=`basename "$s"`
t=$2/$t

mkdir -p$v "$t"

(cd "$s"; exec find -s$x . -print0) \
| (cd "$s"; exec tar -cn$v -f - -T - --null) \
| (cd "$t"; exec tar -xp$v -f -)
