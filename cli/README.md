# spaceporn-cli

**spaceporn-cli** is in early stage development. So it is not in a stable
state and therefore it is not ready to be used. The maintainers are working on
it.
**spaceporn-cli** is a command line which could:
- display procedural pixelized space animated/static wallpaper,
- generate procedural pixelized space pictures.

## Usage

The maintainers will update this section later

## Dependencies

Before installing and building **spaceporn-cli**, you have to install these
dependencies:
- a C compiler (GCC or clang),
- bash,
- automake tools (**make**, **autoconf** and **automake** Ubuntu packages)
- pkg-config (**pkg-config** Ubuntu package),
- png development library (**libpng-dev** Ubuntu package),
- Systemd development library (**libsystemd-dev** Ubuntu package),
- GLEW development library (**libglew-dev** Ubuntu package) --> will be replaced by GLAD,
- OpenGL API (**mesa-common-dev** and **libgl1-mesa-dev** Ubuntu packages),
- X11 development libraries (**xorg-dev** and **libx11-dev** Ubuntu packages),
- GLX environment execution for OpenGL API (**libgl1-mesa-glx** Ubuntu package),

## Installing

The maintainers will update this section later. **Do not follow steps
described here**.

1. Clone the repository.
2. `cd` into the directory.
3. Run `chmod 700 ./scripts/configure.sh`
4. Run `./scripts/configure.sh` and install requested dependencies. Repeat this step until `bin/conf/config.status` is generated.
5. Run `make`.
6. Test the program by using **User options** described in **Usage** section until you find a command which fits your needs.
   This command will be called `YOUR_SPACEPORN_CLI` for following steps of this tutorial.
7. Run `sudo make install`.

## Supported environments

The maintainers are actually working on Ubuntu OS. For the long term the
maintainers will try to provide support for other OS but can not say which and
when. Here are a list of supported OS:
- Ubuntu 20.04    :heavy_check_mark:

If you run **spaceporn-cli** successfully on an unlisted environment, you can
open an issue to update this list.

## Known issues

- [SOLVED] Running **spaceporn-cli** hides desktop icons &rarr; This is an Ubuntu issue. For this OS, the desktop icons are part of root window. This is the same entity. During execution, **spaceporn-cli** creates a window above the root window and behind every other windows to render the shader. This is why desktop icons disappear during execution. Unfortunely using root window is not as easy as using your own window and can potentially causes unexpected side effects. 
- [SOLVED] Running **spaceporn-cli** shows an expensive white and/or black screen &rarr; If you are using Linux OS, it is possible that you are using a deprecated version of i965 driver. What you can do is updating your mesa driver. For Ubuntu: `sudo add-apt-repository ppa:kisak/kisak-mesa && sudo apt update && sudo apt upgrade`. Then, you can run **spaceporn-cli** again. If you are falling on the same weird result, you have to use another mesa driver. For this example, We picked Crocus driver but you can choose another one. You have to add `MESA_LOADER_DRIVER_OVERRIDE=crocus` to /etc/environment file and reboot your computer.

## Contributing

Here are the [instructions](CONTRIBUTING.md).
