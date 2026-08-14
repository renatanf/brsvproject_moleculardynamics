#!/bin/bash
# check_equilibration.sh — thermodynamic equilibration check
#
# Wrapper around process_mdout.perl (AmberTools), which extracts temperature,
# pressure, density, volume and energies from AMBER .out files.
#
# Run from the directory holding one subdirectory per replicate.
# Outputs, per replicate:
#   summary.<PROP>      time series (time in ps, value)
#   summary_avg.<PROP>  mean, one line per input .out
#   summary_rms.<PROP>  standard deviation, one line per input .out
#
# Note on time: with irest=1 the clock continues from the heating stage, so the
# series does not start at zero. Subtract the first value if a zero-based axis
# is wanted.
#
# TSOLUTE and TSOLVENT come out empty — pmemd.cuda does not report separate
# solute/solvent temperatures. Ignore those files.

REPS="SYSTEM_R1 SYSTEM_R2 SYSTEM_R3"
PROPS="TEMP PRES DENSITY VOLUME ETOT EPTOT"

# --- 1. extract, one replicate at a time -------------------------------------
# Output filenames are fixed, so this must run inside each directory or the
# files would overwrite each other.
for d in $REPS; do
  ( cd "$d" && process_mdout.perl *_prod*.out )
done

# --- 2. consolidate the summary ----------------------------------------------
# tail -1 takes the production stage; a directory whose equilibration .out was
# also processed has two lines, production last.
for d in $REPS; do
  echo "=== $d ==="
  for p in $PROPS; do
    printf "%-8s " "$p"
    paste "$d"/summary_avg.$p "$d"/summary_rms.$p | tail -1 \
      | awk '{printf "%14s +- %10s\n", $2, $4}'
  done
done
