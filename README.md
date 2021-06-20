# xtelesktop

A PixelSpace Shader Wallpaper for X System

## WARNING

**Parts of what you will read (and some of it are huge) on this repository is not written by my own. Even if there are no licence on this repository, this code is not completly mine.**</br></br>
I copy paste parts of scripts written by others, merged it and rearranged it to make an app for my personnal use. Some of those scripts are under licence.</br></br>
You can not use this code for a non-personal usage without to be aware of its authors' wishes and how I used their scripts on this repository (if you want to rewrite under licence parts):
- [Khronos - Tutorial: OpenGL 3.0 Context Creation (GLX)][1] - Used to create OpenGL 3 context with X.
- [Github - mmhobi7's xwinwrap][2] - Used to create X desktop window.
- [Github - lord-123's xshader][3] - Used for almost everything else not in shaders..
- [Shadertoy - CBS' Simplicity Galaxy shader][4] - Used for camera movement and stars.
- [Shadertoy - chalky's Red Circles shader][5] - Used for random generated shapes.
- [Shadertoy - nimitz's Noise animation - Electric shader][6] - Used for nebulae and dust animation.
- [Github - Deep-Fold's PixelSpace][7] and [Github - Deep-Fold's PixelPlanets][8] - Used for everything else in shaders.

[1]:https://www.khronos.org/opengl/wiki/Tutorial:_OpenGL_3.0_Context_Creation_(GLX)
[2]:https://github.com/mmhobi7/xwinwrap
[3]:https://github.com/lord-123/xshader
[4]:https://www.shadertoy.com/view/MslGWN
[5]:https://www.shadertoy.com/view/Xds3Ws
[6]:https://www.shadertoy.com/view/ldlXRS
[7]:https://github.com/Deep-Fold/PixelSpace
[8]:https://github.com/Deep-Fold/PixelPlanets

## Usage

```
Usage: xtelesktop [-a] [-m] [-p] [-x PIXELS] [-d MICROS]
Options:
            -a      - Enable shader animations
                      default: disabled
            -m      - Enable camera motion
                      default: disabled
            -p      - Enable multiple colorschemes
                      default: disabled
            -x      - Pixels value between 100 to 600 (ex: -x 300)
                      default: 500
            -d      - Delay value between each frame in microseconds
                      (ex: -d 30000)
                      default: 0
```

## Installing

1. Clone the repository.
2. `cd` into the directory.
3. Run `sudo make clean install`.
4. Test the program by using flags described in "Usage" to fit your needs.
5. Add `xtelesktop [-a] [-m] [-p] [-x PIXELS] [-d MICROS] &` to your `.xinitrc`.
6. Logout and log back in to update the background.

## Supported environments

- UNIX:
  - Ubuntu 20.04:
    - GNOME         :heavy_check_mark:
- Windows OSs       :x:

If you ran **xtelesktop** on a non-listed environment, contact me, I will add it here.

## Known issues

- Running app hides desktop icons &rarr; During execution, the app creates a window above the root window (or desktop window) and behind every other windows to render the shader. This is why desktop icons disappears. The only way to fix this issue is to use root window for shader rendering. Unfortunely on some environments it can lead to unexpected behaviours and I do not want to manage those situations.
