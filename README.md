![BeamRacer](img/beamracer-logo.png)

 Video and Display List coprocessor board for the Commodore 64
 
 https://beamracer.net

# Examples

 Available examples of BeamRacer routines and display lists:

 * [demo_irq.s](asm/demo_irq.s) - Demonstrates how to simultaneously handle VIC and VASYL interrupts.
 * [demo_logo.s](asm/demo_logo.s) - Loads and activates a display list that changes background color at the right moments.
 * [demo_rasterbars_cpu.s](asm/demo_rasterbars_cpu.s) - Simple rasterbars

 Example binaries can be found in [asm/bin/](asm/bin) directory.

 Compatible with ca65 assembler (part of https://github.com/cc65).

# Support

 Got questions or just need support? Visit our forum: https://forum.beamracer.net/

# Bug reports

 Please report any issue using [GitHub's project tracker](https://github.com/madhackerslab/beamracer-examples/issues).
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

 * Copyright &copy;2020 by Mad Hackers Lab and colaborators
 * This is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)

