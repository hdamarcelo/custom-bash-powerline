# Custom Bash powerline theme (for Windows via git-bash and Linux)

Simple powerline theme for bash.

![ScreenShot-Complete](screenshot-complete.png)

![ScreenShot-Compact](screenshot-compact.png)


## Install:

You can just download the **theme.bash** file and source it in your **.bashrc** file.

To make it easier clone the repository to a **.folder** in your **HOME** directory:

```bash
cd $HOME
mkdir -p .bash/themes/custom_bash_powerline
git clone https://github.com/hdamarcelo/custom-bash-powerline.git .bash/themes/custom-bash-powerline
```

then add the following to your .bashrc:

```bash
# Custom bash theme
THEME=$HOME/.bash/themes/custom-bash-powerline/theme.bash
if [ -f $THEME ]; then
   source $THEME
fi
unset THEME
```

## Dependencies

Currently it is not possible to disable the custom segments with developer oriented information (feel free to change this :) ). So you will also need to have these executables in your PATH:

1. * java
   * docker
   * kubectl

2. You will also need a
[Powerline-patched font](https://github.com/powerline/fonts). Or else the custom characters won't show properly.

## License

MIT