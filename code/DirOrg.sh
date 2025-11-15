#!/bin/bash

PROJECT_DIR=/projects/psych_oajilore_chi/mattonim/rembrandt
SITES=(UIC VUMC UPMC)

for SITE in "${SITES[@]}"; do

  FS_DIR=$PROJECT_DIR/Baseline-FS-$SITE
  REST1_DIR=$PROJECT_DIR/Baseline-fMRI_REST1-$SITE
  REST2_DIR=$PROJECT_DIR/Baseline-fMRI_REST2-$SITE

  # Remove SUBJ subdir in FS
  cd "$FS_DIR"
  for dir in REMBRANDT-x-*; do
    rmdir "$dir/SUBJ" 2>/dev/null
  done

  # Clean Sub IDs in FS
  for dir in REMBRANDT-x-*; do
    if [ "$SITE" = "UIC" ]; then
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-3REM([0-9]+)-.*/\1/')
    else
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
    fi
    mv "$dir" "$cleandir"
  done

  # Clean Sub IDs in REST1
  cd "$REST1_DIR"
  for dir in REMBRANDT-x-*; do
    if [ "$SITE" = "UIC" ]; then
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-3REM([0-9]+)-.*/\1/')
    else
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
    fi
    mv "$dir" "$cleandir"
  done

  # Clean Sub IDs in REST2
  cd "$REST2_DIR"
  for dir in REMBRANDT-x-*; do
    if [ "$SITE" = "UIC" ]; then
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-3REM([0-9]+)-.*/\1/')
    else
      cleandir=$(echo "$dir" | sed -E 's/^REMBRANDT-x-([0-9]+)-.*/\1/')
    fi
    mv "$dir" "$cleandir"
  done

done