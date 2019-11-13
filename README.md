<img src="examples/banner.png">

# Fidget - UI library for nim

<p style="color: #e74c3c">WARNING: This library is still in heavy development.</p>

It is an absolute travesty that there is no good and easy way to design cross platform UIs. The HTML5 + Electron + mobile webviews is the only reasonable way to do it, but it sux. HTML/CSS is just so complex and confusing, and JS can be really painful. - but with Fidget compile for web, desktop and mobile!

Programmers still have to code UIs by hand from flat design mockups. Fidget leverages Figma - an app that is taking design world by storm. It does this by taking Figma files and converting them to code. No more counting stupid pixels, no more CSS puzzles. Want to change some spaces? Change it in Figma and reload.

Other UI systems like, HTML5 has a ton of layout primitives, margin, padding, float, absolute, relative, border box, flex and friends. I want to simplify this to just the most basic way to lay something out. Because Fidget leverages Figma, I am adopting their system, because it simple and visual:

* Everything is a Group.
* Groups are positions relative to the parent
* Groups have width and height.
* Resizing with left, top, right, bottom, scale or center.

<p align="center">
  <br>
  <img src="examples/uiExampleIce.png">
</p>
<p align="center" style='font-size:12px'>
  <a href="http://kate.vonhouck.com/">Design done by Kate von Houck. Avalible for hire.</a>
</p>

Figma also has a concept of Symbol, which is basically a function call for UI work. Most of the time you will be calling these symbols to draw UI.

Fidget has several backends that are planned:
* HTML
* Mac
* Linux
* Windows
* iOS (not started yet)
* Android (not started yet)

But currently only HTML is being worked on.

# Why Nim?

Nim is a great languages because it’s easy on the eyes like python, but typed and is perfromant as C. It can also compile to JavaScript, C, C++, ObjC. Nim is the great language for UI design because it has advanced templates and macros can make a really good DSL (domain specific language) - that makes writing UIs straightforward, intuitive and crossplatform.

# Imperative UI Style

I like imperative style of programing. This is a style you probably learned to program at start, but was forced to abandon with more complex and ill fitting object oriented style. Imperative style to me means when you are only using functions, if statements and for loops. I am also not a huge fan of functional programming such currying, foldr, recursion, or immutable everywhere. Imperative style to me means simple data structures of structs, lists and tables. Simple functions that read from top to bottom with as little branches as possible.

Each UI frame is drawn completely from start to finish all in the code you control. Use of callbacks is discouraged. Think liner, think simple. After any event by the user, data or timer, the UI is redrawn. The UI is redrawn in an efficient way as to allow this.

# Fidgetgen

Fidgetgen is a tool to take figma files and turn them into code.

```nim
fidgetgen figmaURL -o:someuifile.nim
```

## maxOS

You need to install `glfw3`

```sh
brew install `glfw3`
```

or just using `dlls/macOS/libglfw.3.3.dylib` thats provided.


## Now to run the examples:

### Native examples for Windows, macOS, and Linux:

First `cd` to each folder then compile and run.

```
nim c -r bars.nim
nim c -r fonts.nim
nim c -r hovers.nim
nim c -r inputs.nim
nim c -r padoftext.nim
nim c -r padofcode.nim
nim c -r basic.nim
```

### Runs the same examples as HTML:

First `cd` to each folder then run `js` compile command then open the `.html` file in a browser.

```
nim js -o:bars.js bars.nim
nim js -o:fonts.js fonts.nim
nim js -o:hovers.js hovers.nim
nim js -o:inputs.js inputs.nim
nim js -o:padoftext.js padoftext.nim
nim js -o:padofcode.js padofcode.nim
nim js -o:basic.js basic.nim
```