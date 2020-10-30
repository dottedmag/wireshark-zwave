# Z-Wave dissector for Wireshark

Installation: `cd ~/.local/lib/wireshark/plugins; for i in $dissector; do ln -s $i .; done`

## Status

Work in progress. Some packets are handled, some are not.

Treat information with caution: packets structure is gleaned from various Z-Wave
implementations, so it might be completely wrong.

## Legal

(c) 2020 Misha Gusarov <dottedmag@dottedmag.net>

All code in this repository is licensed under GNU GPL v3. See `COPYING` file.
