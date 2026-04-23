# SimpleOS

A simple operating system project, organized as a meta repository that ties together its component subprojects via git submodules.

## Subprojects

| Path        | Repository                                                                 | Role                                  |
|-------------|-----------------------------------------------------------------------------|---------------------------------------|
| `kernel/`   | [simpleos-kernel](https://github.com/MySimpleOs/simpleos-kernel)           | Kernel                                |
| `libc/`     | [simpleos-libc](https://github.com/MySimpleOs/simpleos-libc)               | C standard library                    |
| `userland/` | [simpleos-userland](https://github.com/MySimpleOs/simpleos-userland)       | Userland utilities and applications   |
| `toolchain/`| [simpleos-toolchain](https://github.com/MySimpleOs/simpleos-toolchain)     | Cross-compilation toolchain           |

## Cloning

```bash
git clone --recurse-submodules https://github.com/MySimpleOs/simpleos.git
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Layout

```
simpleos/
├── kernel/        (submodule)
├── libc/          (submodule)
├── userland/      (submodule)
├── toolchain/     (submodule)
├── boot/          boot artifacts and bootloader configs
├── scripts/       build, run, and tooling scripts
├── docs/          documentation
└── Makefile       top-level orchestration
```

## License

MIT — see [LICENSE](LICENSE).
