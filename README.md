![BeamRacer](img/beamracer-logo.png)

 Video and Display List coprocessor board for the Commodore 64
 
 https://beamracer.net

# Examples

 Available examples of BeamRacer routines and display lists:

 * [demo_fli.s](asm/demo_fli.s) - How to FLI with a display list.
 * [demo_fld.s](asm/demo_fld.s) - A bit more involved FLD routine.
 * [demo_irq.s](asm/demo_irq.s) - Demonstrates how to simultaneously handle VIC and VASYL interrupts.
 * [demo_irq2.s](asm/demo_irq2.s) - Demonstrates how to quickly synchronize CPU with the display using VASYL assistance.
 * [demo_hirestext.s](asm/demo_hirestext.s) - Text output and scrolling on HiRes screen - with and without hardware copy.
 * [demo_logo.s](asm/demo_logo.s) - Loads and activates a display list that changes background color at the right moments.
 * [demo_rasterbars_cpu.s](asm/demo_rasterbars_cpu.s) - Simple rasterbars.
 * [demo_rasterbars.s](asm/demo_rasterbars.s) - Fast rasterbars using VASYL code.
 * [demo_rastersplit.s](asm/demo_rastersplit.s) - Raster splitting using VASYL code.
 * [demo_selfmod.s](asm/demo_selfmod.s) - Self-modifying display list, the CPU is slacking.
 * [demo_seq.s](asm/demo_seq.s) - A demonstration of bitmap sequencer's basics.

 Example binaries can be found in [asm/bin/](asm/bin) directory.

 Compatible with ca65 assembler (part of https://github.com/cc65).

# Support

 Got questions or just need support? Visit our forum: https://forum.beamracer.net/

# Bug reports

 Please report any issues using [GitHub's project tracker](https://github.com/madhackerslab/beamracer-examples/issues) or the forum.
 If you'd like to contribute to the this project, please send regular pull request. But we recommend to open new
 [ticket](https://github.com/madhackerslab/beamracer-examples/issues) before doing any work.

# Cloning the repository

 **NOTE:** this project uses [git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules),
 it's required to either use `--recurse-submodules` to get all the dependencies during cloning:

    git clone --recurse-submodules https://github.com/madhackerslab/beamracer-examples

 or to pull them manually by doing:

```
git submodule init
git submodule update
```

 after cloning the repository.

# License

 * Copyright &copy;2019-2020 by Mad Hackers Lab
 * This is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)

