#!/bin/sh
# Install hotspot into ~/.local/bin (or $PREFIX).
set -e
PREFIX="${PREFIX:-$HOME/.local/bin}"
mkdir -p "$PREFIX"
install -m 0755 "$(dirname "$0")/hotspot" "$PREFIX/hotspot"
echo "installed -> $PREFIX/hotspot"
case ":$PATH:" in
  *":$PREFIX:"*) echo "run: hotspot doctor" ;;
  *) echo "note: $PREFIX is not on your PATH; add it to your shell profile." ;;
esac
