[![Build Status](https://travis-ci.com/pabtomas/xteleskop.svg?branch=master)](https://travis-ci.com/pabtomas/xteleskop)

# xteleskop

A PixelSpace Shader Wallpaper for X System

## WARNING

**Parts of what you will read on this repository (and some of it are huge) is not written by my own. Even if there are no licence on this repository, this code is not completly mine.**</br></br>
I copy paste parts of scripts written by others, merged it and rearranged it to make an app for my personnal use. Some of those scripts are under licence.</br></br>
You can not use this code for a non-personal usage without to be aware of its authors' wishes and how I used their scripts on this repository (if you want to rewrite under licence parts):
- [Github - mmhobi7's xwinwrap][1] - Used to create X desktop window.
- [Github - lord-123's xshader][2] - Used for almost everything else not in shaders..
- [Shadertoy - CBS' Simplicity Galaxy shader][3] - Used for camera movement and stars.
- [Shadertoy - chalky's Red Circles shader][4] - Used for random generated shapes.
- [Shadertoy - nimitz's Noise animation - Electric shader][5] - Used for nebulae and dust animation.
- [Github - Deep-Fold's PixelSpace][6], [Github - Deep-Fold's PixelPlanets][7] and [Github - EnthusiastGuy's MonoGame-Pixel-Planets][8]- Used for everything else in shaders.

[1]:https://github.com/mmhobi7/xwinwrap
[2]:https://github.com/lord-123/xshader
[3]:https://www.shadertoy.com/view/MslGWN
[4]:https://www.shadertoy.com/view/Xds3Ws
[5]:https://www.shadertoy.com/view/ldlXRS
[6]:https://github.com/Deep-Fold/PixelSpace
[7]:https://github.com/Deep-Fold/PixelPlanets
[8]:https://github.com/EnthusiastGuy/MonoGame-Pixel-Planets

## Usage

```
xteleskop v0.1

Usage: xteleskop [-a] [-m] [-p] [-x PIXELS] [-d MICROS] [-V] [-R ROADMAP]

User options:

    -a  Enable shader animations

    -m  Enable camera motion

    -p  Enable multiple colorschemes

    -x  Pixels value between 100 to 600 (ex: -x 300) [default: 500]

    -d  Delay value between each frame in microseconds (ex: -d 0)
        [default: 30000]

Dev options:

    -V  Verbose mode

    -R  Run the corresponding predefined execution roadmap (ex: -R 0)
        [default: 0]
```

## Installing (not finished section)

1. Clone the repository.
2. `cd` into the directory.
3. Run `chmod 700 ./bash/configure.sh`
4. Run `./bash/configure.sh` and install requested dependencies. Repeat this step until `bin/conf/config.status` is generated.
5. Run `make`.
6. Test the program by using **User options** described in **Usage** section until you find a command which fits your needs.
   This command will be called `YOUR_XTELESKOP_CLI` for following steps of this tutorial.
7. Run `sudo make install`.

---
8. Add this following line to your `.xinitrc`:
   `YOUR_XTELESKOP_CLI -V > ~/.xteleskop.log 2>&1`
9. Logout and log back in to update the background.
---

## Supported environments

- UNIX:
  - Ubuntu 20.04    :heavy_check_mark:
- Windows OSs       :x:

If you ran **xteleskop** on a non-listed environment, contact me, I will add it here.

## Known issues

- Running app hides desktop icons &rarr; During execution, the app creates a window above the root window (or desktop window) and behind every other windows to render the shader. This is why desktop icons disappear during execution. The only way to fix this issue is to use root window and/or File-System/Window Manager window which draw icons and desktop above root window. Unfortunely I did not find a way to do this properly. However I will if I can.

## Reporting bugs

If the application crashed, you can send me your OS config (OS and Window Manager) **and** the content of the file located at: `~/.xteleskop.log` if you followed the **Installing** tutorial (if not it will be really hard to understand what happened on your device).

## Additional links

Placed here for my own needs:

- [Khronos - Tutorial: OpenGL 3.0 Context Creation (GLX)][9]
- [Shadertoy - vegardno's Pixel planet shader][10]
- [Shadertoy - viclw17's Jupiter shader][11]
- [Daniel Linssen's planetarium][12]

[9]:https://www.khronos.org/opengl/wiki/Tutorial:_OpenGL_3.0_Context_Creation_(GLX)
[10]:https://www.shadertoy.com/view/WdSSWD
[11]:https://www.shadertoy.com/view/MdyfWw
[12]:https://managore.itch.io/planetarium
