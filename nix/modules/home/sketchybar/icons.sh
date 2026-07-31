#!/usr/bin/env bash
# Icon glyphs (Nerd Font / Font Awesome subset codepoints, rendered via
# icon.font="Hack Nerd Font:...". IMPORTANT: these are literal, directly
# embedded UTF-8 characters in this file — NOT bash $'\U........'
# escape sequences. Those escapes are locale-dependent: under an empty/
# minimal environment (no LANG/LC_ALL/LC_CTYPE set — exactly what
# sketchybar's launchd job gets by default, confirmed via launchctl print
# showing no locale vars), bash silently fails to interpret $'\U0000f179'
# as Unicode and instead passes through the literal 10-character string
# \U0000f179 verbatim — confirmed live via
# `env -i /bin/bash -c 'echo -n $'"'"'\U0000f179'"'"''` producing that
# exact garbled literal text instead of a real glyph, which is why every icon
# rendered as nothing (or garbage) despite every other check (font name,
# cmap glyph presence, --load-font, Homebrew binary swap) passing clean.
# Embedding the real UTF-8 bytes directly removes any shell/locale
# interpretation step entirely. Codepoints unchanged from before, verified
# against the official Nerd Fonts v3.4.0 generated CSS.
export ICON_APPLE=""
export ICON_PREFERENCES=""
export ICON_LOCK=""
export ICON_POWER=""
export ICON_RESTART=""
export ICON_INFO=""
export ICON_LOGOUT=""
export ICON_WIFI_CONNECTED=""
export ICON_ETHERNET_CONNECTED=""
