#!/usr/bin/env -S just --justfile
# set positional-arguments

# ****************************************************************
# * This file is intended to be used on linux                    *
# *                                                              *
# * Test recipes will require to have godot binary in project    *
# * directory named as `godotbin`                                *
# ****************************************************************

ASTEROIDS_PATH := "examples/asteroids"
TEST_PATH      := "examples/test"

@default:
    just --list

# ****************************************************************
# * Building                                                     *
# ****************************************************************

build:
    dub build

# ****************************************************************
# * Testing                                                      *
# ****************************************************************

create_project custom_path:
    dub run :init --path {{custom_path}}

# Asteroids
asteroids_build: (exbuild ASTEROIDS_PATH)
asteroids_run: (instance ASTEROIDS_PATH)
asteroids_editor: (editor ASTEROIDS_PATH)

# Test
test_build: (exbuild TEST_PATH)
test_run: (instance TEST_PATH)
test_editor: (editor TEST_PATH)

# Private utils
[private]
editor project:
    ./godotbin "{{project}}/project/project.godot"

[private]
instance project:
    ./godotbin --path "{{project}}/project/"

[private]
exbuild project:
    cd {{project}} && dub build

# ****************************************************************
# * Generating api                                               *
# ****************************************************************

generate_full: dump_api generator

generator:
    dub run :generator -- -j extension_api.json -o

dump_api:
    ./godotbin --dump-extension-api --quiet



# Cheatsheet:
# Set a variable (variable case is arbitrary)
# SINGLE := "--single"
#
# Export variable
# export MYHOME := "/new/home"
#
# Join paths:
# PATHS := "path/to" / "file" + ".txt"
#
# Conditions
# foo := if "2" == "2" { "Good!" } else { "1984" }
#
# String literals
# escaped_string := "\"\\" # will eval to "\
# raw_string := '\"\\' # will eval to \"\\
# exec_string := `ls` # will be set to result of inner command
#
# Hide configuration from just --list, prepend _ or add [private]
# [private]
# _test: build_d
#
# Alias to a recipe (just noecho)
# alias noecho := _echo
#
# Silence commands or recipes by prepending @ (i.e hide "dub build"):
# @build_d_custom:
#     @dub build
#
# Continue even on fail  by adding "-"
# test:
#    -cat notexists.txt
#    echo "Still executes"
#
# Configuration using variable from above (and positional argument $1)
# buildFile FILENAME:
#     dub build {{SINGLE}} $1
#
# Set env ([linux] makes recipe be usable only in linux)
# [linux]
# @test_d:
#     #!/bin/bash
#
# A command's arguments can be passed to dependency (also default arguments)
# push target="debug": (build target)
#
# Use + (1 ore more) or * (0 or more) to make argument variadic. Must be last
# ntest +FILES="justfile1 justfile2":
#
# Run set configurations (recipe requirements)
# all: build_d build_d_custom _echo
#
# This example will run in order "a", "b", "c", "d"
# b: a && c d
#
# Each recipe line is executed by a new shell (use shebang to prevent)
# foo:
#     pwd    # This `pwd` will print the same directory…
#     cd bar
#     pwd    # …as this `pwd`!
