// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef GUI_MENU_H
#define GUI_MENU_H

#include <queue>
#include "common.h"
#include "config_generated.h"
#include "controller.h"
#include "input.h"
#include "material_manager.h"
#include "renderer.h"
#include "touchscreen_button.h"

namespace fpl {
namespace splat {

// Simple struct for transporting a menu selection, and the controller that
// triggered it.
struct MenuSelection {
  MenuSelection(ButtonId buttonId, ControllerId controllerId)
      : button_id(buttonId),
        controller_id(controllerId) {}

  ButtonId button_id;
  ControllerId controller_id;
};

class GuiMenu {
 public:
  GuiMenu();

  void AdvanceFrame(WorldTime delta_time, InputSystem* input);
  void Setup(const UiGroup* menudef, MaterialManager* matman);
  void Render(Renderer* renderer);
  void AdvanceFrame(WorldTime delta_time);
  MenuSelection GetRecentSelection();
  void HandleControllerInput(uint32_t logical_input,
                             ControllerId controller_id);

 private:
  void ClearRecentSelections();
  TouchscreenButton* FindButtonById(ButtonId id);
  void MoveSelection(const flatbuffers::Vector<uint16_t>* destination_list);

  const UiGroup* menu_def_;
  InputSystem* input_;
  ButtonId current_focus_;
  std::queue<MenuSelection> unhandled_selections_;
  std::vector<TouchscreenButton> button_list_;

  // Total Worldtime since the menu was initialized.
  // Used for animating selections and such.
  WorldTime time_elapsed_;
  mathfu::vec2 window_size_;
};


}  // splat
}  // fpl
#endif // GUI_MENU_H