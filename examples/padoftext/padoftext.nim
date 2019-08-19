import ../../src/fidget

import print
import random
import math

when not defined(js):
  import fidget/backendopengl, typography, tables
  fonts["Ubuntu"] = readFontSVG("libs/fidget/examples/Ubuntu.svg")


var
  textValue = """Once upon a midnight dreary, while I pondered, weak and weary,
Over many a quaint and curious volume of forgotten lore—
    While I nodded, nearly napping, suddenly there came a tapping,
As of some one gently rapping, rapping at my chamber door.
“’Tis some visitor,” I muttered, “tapping at my chamber door—
            Only this and nothing more.”

    Ah, distinctly I remember it was in the bleak December;
And each separate dying ember wrought its ghost upon the floor.
    Eagerly I wished the morrow;—vainly I had sought to borrow
    From my books surcease of sorrow—sorrow for the lost Lenore—
For the rare and radiant maiden whom the angels name Lenore—
            Nameless here for evermore.

    And the silken, sad, uncertain rustling of each purple curtain
Thrilled me—filled me with fantastic terrors never felt before;
    So that now, to still the beating of my heart, I stood repeating
    “’Tis some visitor entreating entrance at my chamber door—
Some late visitor entreating entrance at my chamber door;—
            This it is and nothing more.”"""

drawMain = proc() =

  window.title = "Pad of Text"

  frame "main":
    box 100, 100, parent.box.w - 200, parent.box.h
    font "Ubuntu", 20.0, 400.0, 25, -1, -1
    rectangle "#F7F7F9"

    text "input":
      box 0, 0, parent.box.w, parent.box.h
      fill "#000000"
      multiline true
      binding textValue

startFidget()
