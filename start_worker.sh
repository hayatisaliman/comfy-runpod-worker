#!/bin/bash
if [ -d /runpod-volume/models ]; then
  for d in /runpod-volume/models/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    if [ ! -e "/comfyui/models/$name" ]; then
      ln -s "${d%/}" "/comfyui/models/$name"
    fi
  done
fi
exec /start.sh
