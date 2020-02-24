## Finds system fonts

proc getSystemFontPath*(): string =
  when defined(macOS):
    "/System/Library/Fonts/SFNSText.ttf"
  elif defined(windows):
    r"C:\Windows\Fonts\arial.ttf"
  # else defined(linux):
  #   TODO: go through these direcotires
  #   "~/.fonts/"
  #   "/usr/share/fonts/truetype/"
  #   "/usr/X11R6/lib/X11/fonts/ttfonts/"
  #   "/usr/X11R6/lib/X11/fonts/"
  #   "/usr/share/fonts/truetype/"
  else:
    return ""
