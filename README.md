# lfs-vcpkg

This project is an experiment in building a **Linux From Scratch (LFS 12.4)** system using **vcpkg as an orchestration layer**.

## Goal

The ultimate goal is to obtain a **fully reproducible LFS-based Linux distribution**, where **each step of the LFS book is represented as a vcpkg port**, and the entire system can be built via a **single entry-point script**.

In other words:
- LFS chapters → vcpkg ports
- LFS build order → vcpkg dependency graph
- LFS build environment → custom vcpkg triplets
- One command → full toolchain → temporary system → final system

## Core idea

vcpkg is used **not as a traditional package manager**, but as:
- a build orchestrator,
- a dependency resolver,
- a reproducibility and caching layer.

For early LFS stages (Chapter 5–6), ports are implemented as **helper ports**:
- they install directly into `$LFS/tools` or `$LFS`,
- vcpkg does not sandbox the final installation,
- vcpkg tracks only metadata and build state.

This allows us to follow the LFS book *as-is*, while still benefiting from vcpkg’s structure, caching, and automation.

## Current state

- LFS version: **12.4**
- Host system: Linux (tested on Ubuntu)
- Implemented stages:
  - Chapter 5 (pass1 toolchain: binutils-pass1, gcc-pass1)
- Custom stage-specific triplets:
  - `x64-lfs-pass1`
  - `x64-lfs-temp`
- Single entry-point script: `build.sh`

At this stage, the focus is on:
- correctness vs the LFS book,
- clean separation of build stages,
- avoiding host contamination,
- making all steps explicit and reproducible.

## What this project is NOT

- It is not a replacement for the LFS book.
- It is not a general-purpose Linux distribution (yet).
- It does not try to hide or simplify LFS concepts.

Instead, it makes them **scriptable, inspectable, and repeatable**.

## Why

The project exists to explore:
- whether LFS can be expressed as a dependency graph,
- how far vcpkg can be pushed beyond “C/C++ libraries”,
- how to automate a traditionally manual system build without losing transparency.

## Disclaimer

This is a **work in progress** and a learning/engineering experiment.
Expect rough edges, incomplete coverage of the book, and ongoing refactoring.
