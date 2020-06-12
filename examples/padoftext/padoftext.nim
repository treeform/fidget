import fidget

loadFont("IBM Plex Sans Regular", "IBMPlexSans-Regular.ttf")

setTitle("Pad of Text")

var
  textValue = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut volutpat mi tortor, quis congue elit bibendum vitae. Pellentesque risus velit, tempor vel arcu pellentesque, lacinia ultrices felis. Aliquam erat volutpat. Nulla sodales odio ac turpis fermentum, quis pulvinar erat efficitur. Ut molestie consectetur odio vitae interdum. Etiam dui odio, porta in volutpat in, facilisis at erat. Etiam sed augue eget risus tincidunt sagittis sit amet nec justo. Donec ac auctor massa. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.

Aenean rhoncus odio eu neque viverra auctor. Nullam commodo, elit nec efficitur finibus, orci tellus pharetra risus, at ultrices urna purus sed odio. Donec volutpat semper arcu, et rutrum mauris malesuada eu. Quisque dignissim, diam sed efficitur facilisis, lorem velit sagittis mauris, ut hendrerit diam ex a lorem. Duis iaculis nunc sem, sed vehicula urna consectetur ut. Morbi bibendum eros at dictum laoreet. Curabitur lacus diam, iaculis bibendum venenatis tempus, laoreet id velit. Sed laoreet dapibus efficitur. Integer sollicitudin mauris sed lacinia finibus.

Duis eget tellus lacus. Sed eu sapien sed dolor placerat volutpat eget lacinia augue. Nulla arcu mauris, sodales eu nisl id, hendrerit imperdiet leo. Nulla varius metus dignissim sollicitudin fermentum. Phasellus non augue sollicitudin orci dignissim ullamcorper ac sed urna. In finibus metus sit amet erat volutpat, laoreet pellentesque lorem pulvinar. Vivamus non magna a enim ultricies cursus. Integer vitae nibh gravida, lacinia libero non, tristique nisi. Nullam vitae ultricies urna. Etiam vel mauris lectus. Quisque mattis luctus velit, eu mattis dolor mattis ut. Donec dapibus turpis sem, vitae tempus diam porta eget.

Vivamus mattis congue faucibus. Nullam venenatis ipsum sed lacus pharetra pharetra. In urna dui, mollis sit amet consectetur quis, pellentesque non ante. Phasellus congue dui ac arcu interdum imperdiet. Praesent id egestas magna, quis tincidunt odio. Nunc ac diam a ipsum tempus posuere. Praesent egestas lobortis est, sed lacinia elit ullamcorper vel.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris mi magna, blandit non pharetra id, convallis in ex. Curabitur ut odio arcu. Praesent nec maximus lectus, eu varius massa. Quisque nec libero a turpis laoreet placerat a a felis. Vivamus dignissim augue vitae accumsan facilisis. Nunc at imperdiet risus. Aliquam elementum, purus id rhoncus eleifend, mauris nisl scelerisque nisl, vitae aliquam nulla enim ac metus.
"""

proc drawMain() =

  group "pad":
    box 100, 100, parent.box.w - 200, parent.box.h - 200
    font "IBM Plex Sans Regular", 20.0, 400.0, 25, hLeft, vTop
    fill "#F7F7F9"
    clipContent true

    text "input":
      box 0, 0, parent.box.w, parent.box.h
      fill "#000000"
      multiline true
      binding textValue

startFidget(drawMain)
