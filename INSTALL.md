# BitKeeper Build Requirements

## System Dependencies

BitKeeper now requires the following system-installed development packages:

### Cryptographic Libraries
- **libtomcrypt-dev** (or equivalent) - Cryptographic functions
- **libtommath-dev** (or equivalent) - Multiple-precision integer arithmetic

### GUI Components
- **tcl-dev** - Tcl development files
- **tk-dev** - Tk development files

### Utility Libraries
- **libpcre3-dev** - Perl-compatible regular expressions
- **liblz4-dev** - LZ4 compression library
- **zlib1g-dev** - Zlib compression library

## Installation Instructions

### Debian/Ubuntu
```bash
sudo apt-get update
sudo apt-get install libtomcrypt-dev libtommath-dev tcl-dev tk-dev libpcre3-dev liblz4-dev zlib1g-dev
```

### RHEL/CentOS
```bash
sudo yum install tomcrypt-devel tommath-devel tcl-devel tk-devel pcre-devel lz4-devel zlib-devel
```

### Fedora
```bash
sudo dnf install tomcrypt-devel tommath-devel tcl-devel tk-devel pcre-devel lz4-devel zlib-devel
```

### Arch Linux
```bash
sudo pacman -S tomcrypt libtommath tcl tk pcre lz4 zlib
```

## Building BitKeeper

After installing the required dependencies:

```bash
cd bitkeeper
make
```

If you encounter any missing library errors, please install the corresponding development package as shown above.

## Troubleshooting

### Missing Libraries
If the build fails with missing library errors, check which specific library is missing and install the appropriate development package for your distribution.

### pkg-config Issues
If you get pkg-config errors, ensure you have pkg-config installed:

```bash
# Debian/Ubuntu
sudo apt-get install pkg-config

# RHEL/CentOS
sudo yum install pkgconfig

# Fedora
sudo dnf install pkgconf-pkg-config
```

### Library Detection
The build system uses pkg-config to detect libraries. If you have libraries installed in non-standard locations, you may need to set the PKG_CONFIG_PATH environment variable:

```bash
export PKG_CONFIG_PATH=/path/to/lib/pkgconfig:$PKG_CONFIG_PATH
```

## Important Notes

- BitKeeper will **NOT** use the bundled libraries in `src/tomcrypt`, `src/tommath`, or `src/gui/tcltk`
- All required libraries must be installed as system packages
- The build will fail with clear error messages if any required libraries are missing
- Follow the platform-specific installation instructions above to resolve missing dependencies