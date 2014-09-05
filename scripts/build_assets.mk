# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This makefile builds all assets under src/rawassets/ for the project, writing
# the results to assets/.

# Path of this project.
TOP:=$(realpath $(dir $(lastword $(MAKEFILE_LIST)))/..)

# Directory that contains the FlatBuffers compiler.
FLATBUFFERS_PATH?=$(TOP)/flatbuffers

# Name of the flatbuffers executable.
flatc_executable_name=flatc$(if $(findstring Windows,$(OS)),.exe,)

# Location of FlatBuffers compiler.
FLATC?=$(firstword \
            $(wildcard $(FLATBUFFERS_PATH)/$(flatc_executable_name)) \
            $(wildcard $(FLATBUFFERS_PATH)/Release/$(flatc_executable_name)) \
            $(wildcard $(FLATBUFFERS_PATH)/Debug/$(flatc_executable_name)))

# If the FlatBuffers compiler is not specified, just assume it's in the PATH.
ifeq ($(FLATC),)
FLATC:=$(flatc_executable_name)
endif


# Function which converts path $(1) to paths understood by the host OS'
# executables.
define host-realpath
  $(realpath $(call host-native-path-separator,$(1)))
endef
ifneq ($(findstring Windows,$(OS)),)
ifneq ($(findstring cygwin,$(MAKE_HOST)),)
define host-realpath
$(shell cygpath -m $(realpath $(1)))
endef
else
define host-realpath
$(call host-native-path-separator,$(1))
endef
endif
endif

# Convert path separators to a form understood by applications on the host OS.
define host-native-path-separator
$(1)
endef
ifneq ($(findstring Windows,$(OS)),)
ifeq ($(findstring cygwin,$(MAKE_HOST)),)
define host-native-path-separator
$(subst /,\,$(1))
endef
endif
endif

# Implements the command "rm -f" across different platforms.
define host-rm-f
rm -f $(1)
endef
ifneq ($(findstring Windows,$(OS)),)
ifeq ($(findstring cygwin,$(MAKE_HOST)),)
define host-rm-f
del /q $(1) 2>NUL
endef
endif
endif

# Convert specified json paths to FlatBuffers binary data output paths.
# For example: src/rawassets/materials/splatter1.json will be converted to
# assets/materials/splatter1.bin.
define flatbuffers_json_to_binary
$(subst $(TOP)/src/rawassets,assets,$(patsubst %.json,%.bin,$(1)))
endef

# Convert specified json path to the associated FlatBuffers schema path.
# For example: src/rawassets/config.json will be converted to
# src/flatbufferschemas/config.fbs.
define flatbuffers_json_to_fbs
$(subst rawassets/,flatbufferschemas/,$(patsubst %.json,%.fbs,$(1)))
endef

# Generate a build rule that will convert a json FlatBuffer $(1) to a binary
# FlatBuffer using the schema file specified by $(2).
define flatbuffers_build_rule
$(eval \
  $(call flatbuffers_json_to_binary,$(1)): $(1)
	$(FLATC) -o $$(dir $$@) -b $$(call host-realpath,$(2)) \
		$$(call host-realpath,$$<))
endef

# Generate a build rule that will convert a json FlatBuffer to a binary
# FlatBuffer using a schema derived from the source json filename.
define flatbuffers_single_schema_build_rule
$(call flatbuffers_build_rule,$(1),$$(call flatbuffers_json_to_fbs,$$<))
endef

# Generate a build rule that will convert a json FlatBuffer to a binary
# FlatBuffer using the materials schema.
define flatbuffers_material_build_rule
$(call flatbuffers_build_rule,$(1),$(TOP)/src/flatbufferschemas/materials.fbs)
endef

# Generate a build rule that will convert a json FlatBuffer to a binary
# FlatBuffer using the sounds schema.
define flatbuffers_sound_build_rule
$(call flatbuffers_build_rule,$(1),$(TOP)/src/flatbufferschemas/sound.fbs)
endef

# json describing FlatBuffers data that will be converted to FlatBuffers binary
# files.
flatbuffers_single_schema_json:=\
	$(TOP)/src/rawassets/config.json \
	$(TOP)/src/rawassets/buses.json \
	$(TOP)/src/rawassets/character_state_machine_def.json \
	$(TOP)/src/rawassets/rendering_assets.json \
	$(TOP)/src/rawassets/sound_assets.json

# json describing FlatBuffers material data (using the material.fbs schema)
# that will be converted to FlatBuffers binary files.
flatbuffers_material_json:=\
	$(wildcard $(TOP)/src/rawassets/materials/*.json)

# json describing FlatBuffers sound data (using the sound.fbs schema)
# that will be converted to FlatBuffers binary files.
flatbuffers_sound_json:=\
	$(wildcard $(TOP)/src/rawassets/sounds/*.json)

# All binary FlatBuffers that should be built.
flatbuffers_binaries=\
	$(call flatbuffers_json_to_binary,\
		$(flatbuffers_single_schema_json) \
		$(flatbuffers_material_json) \
		$(flatbuffers_sound_json))

# Top level build rule for all assets.
all: $(flatbuffers_binaries)

# Generate clean rule.
clean:
	$(call host-rm-f,$(call host-native-path-separator,\
		$(flatbuffers_binaries)))

$(foreach binary,$(call host-native-path-separator,$(flatbuffers_binaries)),\
    $(call clean_rule,$(binary)))

# Create a build rule for each FlatBuffer binary file that will be built from
# a .json files using a schema that is derived form the source json filename.
$(foreach flatbuffers_json_file,$(flatbuffers_single_schema_json),\
    $(call flatbuffers_single_schema_build_rule,$(flatbuffers_json_file)))

# Create build rules for each FlatBuffer binary file that will be
# built from a .json material file.
$(foreach flatbuffers_json_file,$(flatbuffers_material_json),\
    $(call flatbuffers_material_build_rule,$(flatbuffers_json_file)))

# Create build rules for each FlatBuffer binary file that will be
# built from a .json sound file.
$(foreach flatbuffers_json_file,$(flatbuffers_sound_json),\
    $(call flatbuffers_sound_build_rule,$(flatbuffers_json_file)))