# archiso-sb-shim
This repo attempts to provide an easy way to create an *Archlinux Live CD/USB ISO* ready to run on a **Secure Boot** enabled system, using the *shim* method with your **own keys**.

But for this to work, before booting the *CD/USB key*, you will need to already have installed **your own keys** in the EFI firmware via the **MOK** list with `mokutil`.

Or, if you put your *DER certificate* in the current directory (named `DB.cer`), then it will be included in the *ESP* of the *archiso*, and you will be able to enroll it during the first boot of the ISO. and then reboot.

IMPORTANT NOTE: This will not install an archlinux ready to boot with Secure Boot though. You will have to complete the needed steps to make it work, by yourself.
This means follow the [arch wiki](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot) to install a method to boot with Secure Boot enabled.

If using the shim method, you will have to do almost the same thing that was done with the ISO ie.
  - install sbsigntools, shim-signed, and mokutil
  - and then your keys into the shim MOK list
  - and sign the kernel, and your bootloader

## Scripted method
The script `archiso-sb-shim.sh` automates the method described below. This is a very basic script; use at your own risk.

It needs `sbsigntools` package to be installed.

## Manual method
### Prerequisite
Install the `sbsigntools` from *[extra]*.

As described in the [arch wiki](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface/Secure_Boot#shim), you need to install `shim-signed` package from the *AUR*.

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

We need to add the package previously mentionned (aka `shim-signed`) to the *iso*. To do so:

1. Add the following line at the end of `packages.x86_64`:

    ```
    mokutil
    shim-signed
    ```

2. Modify `pacman.conf` inside the *archiso profile* you just copied

  Define a custom repo at the end of the file. You just need to uncomment the last 3 lines, and choose a directory where you will put that repo alongside the 2 packages mentionned earlier.

  ```
  [custom]
  SigLevel = Optional TrustAll
  Server = file:///tmp/custom.d
  ```

### Create a custom repo
To make the previous bit work, we need to create a *custom repo* for the package from *AUR* we need: `shim-signed`.

    mkdir /tmp/custom.d
    cd /tmp/custom.d
    cp <somewhere>/shim-signed-*.pkg.* .
    repo-add custom.db.tar.gz shim-signed-*.pkg.*

### Voilà !
That's it. We just have to [build the ISO](https://wiki.archlinux.org/index.php/Archiso#Build_the_ISO) by running our `mkarchiso` now:

    ./mkarchiso -v -w /tmp/archisotmp -o ~ ./myarchiso
