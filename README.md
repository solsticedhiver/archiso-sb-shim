# archiso-sb-shim
This repo attempts to provide an easy way to create an *archiso* with **Secure Boot** enabled using the *shim* method with your **own keys**.

This will help you generate an *archiso* image that can boot on a PC/laptop with Secure Boot enabled.

But for this to work, you will need to already have installed your own keys in the **MOK** list with `mokutil`.

If you put your *DER certificate* in the current directory (named `DB.cer`), then it will be included in the *ESP* of the *archiso*, and you will be able to enroll it during the boot of the ISO.

## Scripted method
A script to automate this will hopefully come soon.

## Manual method
### Prerequisite
Install the `sbsigntools` from *[extra]*.

As described in the [arch wiki](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot#shim), you need to install `shim-signed` package from the *AUR*.

And while you are at it, also install `mokutil` package from *AUR* too.

**Keep** the *generated packages* around, as we will need them later on.

Copy your keys (`DB.key` and `DB.crt`) to the current directory. Look at the [wiki](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot#Set_up_shim) on how to do that if you don't have ones.

### Patch mkarchiso

Install `archiso` package, if it is not already done.

Make a copy of `mkarchiso`, and apply the *patch*:

    cp /usr/bin/mkarchiso .
    patch -p0 -i mkarchiso.patch

### Copy and configure a profile

Copy an *archiso* profile; we will use here *releng*.

    cp -a /usr/share/archiso/configs/releng myarchiso

We need to add the 2 packages previously mentionned (aka `shim-signed` and `mokutil`) to the *iso*. To do so:

1. Add the 2 following lines at the end of `packages.x86_64`:

    ```
    shim-signed
    mokutil
    ```

2. Modify `pacman.conf` inside the *archiso profile* you just copied

  Define a custom repo at the end of the file. You just need to uncomment the last 3 lines, and choose a directory where you will put that repo alongside the 2 packages mentionned earlier.

  ```
  [custom]
  SigLevel = Optional TrustAll
  Server = file:///tmp/custom.d
  ```

### Create a custom repo
To make the previous bit work, we need to create a *custom repo* for the 2 packages from *AUR* we need: `shim-signed` and `mokutil`.

    mkdir /tmp/custom.d
    cd /tmp/custom.d
    cp <somewhere>/shim-signed-*.pkg.* .
    cp <somewhere>/mokutil-*.pkg.* .
    repo-add custom.db.tar.gz shim-signed-*.pkg.* mokutil-*.pkg.*

### Voilà !
That's it. We just have to [build the ISO](https://wiki.archlinux.org/index.php/Archiso#Build_the_ISO) by running our `mkarchiso` now:

    ./mkarchiso -v -w /tmp/archisotmp -o ~ ./myarchiso
