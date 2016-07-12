#!/bin/sh

LC_ALL=C
export LC_ALL

for f do
  test x"$f" = x"${f%.d}" && continue
  f=${f%.d}
  #test -e "$f" && mv -nv "$f" "$f".bak
  rm -f "$f".r
  find "$f".d/. -name '*.r' -print0 | xargs -0 cat > "$f".r
  touch -chr "$f".d "$f".r
  Rez -o "$f" "$f".r
  SetFile -c 0x4E9A768A -t 0x4E709566 "$f"
  touch -chr "$f".r "$f"
done
