<h1 align="center">
GitHub Install Plumed Action
</h1>

<div align="center">
An action to install plumed in your workflow.

[![license](https://img.shields.io/github/license/Iximiel/install-plumed.svg)](https://github.com/Iximiel/install-plumed/blob/main/LICENSE)
[![release](https://img.shields.io/github/release/Iximiel/install-plumed.svg)](https://github.com/Iximiel/install-plumed/releases/latest)
[![GitHub release date](https://img.shields.io/github/release-date/Iximiel/install-plumed.svg)](https://github.com/Iximiel/install-plumed/releases)
![Test](https://github.com/Iximiel/install-plumed/actions/workflows/test.yaml/badge.svg?branch=main&event=push)
</div>

*Iximiel/install-plumed* installs plumed in your workflow in a standardize fashion.

This action synergise with using [ccache](https://ccache.dev/) and [actions/cache](https://github.com/actions/cache).

An example of calling this action in your workflow is:

```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  id: plumed
  with:
    modules: 'reset'
    dependency_path: '${{ github.workspace }}/_data'
    CC: 'ccache mpicc'
    CXX: 'ccache mpic++'
```
Here plumed will be installed as if it is configured with:
```bash
 CC="ccache mpicc" CXX="ccache mpic++" ./configure --enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings --prefix=/home/runner/opt --enable-modules=reset 'LDFLAGS=-Wl,-rpath,"/home/runner/opt/lib:/home/runner/opt/libtorch/lib:"'
```
And it is creating a json file in `${{ github.workspace }}/_data` that hosts a list of plumed internal module dependencies.

This action provides ONLY the installation of plumed. If you need a certain functionality that need certain libraries installed you will need to add an extra step in the workflow to install those libraries.

## Output

This action outputs two parameters:
 - **plumed_prefix** the path where plumed has installed into
 - **dependency_file** the full path of the dependency file created if `dependency_path` is specified (see [below](#dependency_path)).
 
 In the previous example you can access to them within the job with: `${{ steps.plumed.outputs.plumed_prefix }}` and  `${{ steps.plumed.outputs.dependency_file }}`
## Options

You are not required to use any option, with everithing set to default plumed will be configured with:

```bash
CC="gcc" CXX="g++" ./configure --enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings --prefix=~/opt --enable-modules=all LDFLAGS=-Wl,-rpath,${LD_LIBRARY_PATH}
```

Plumed will be cloned from `https://github.com/plumed/plumed2.git` and the script will automatically install the latest stable version.

And by default the intenral module dependencies will not be compiled.

- Options
  - [repository](#repository)
  - [version](#version)
  - [suffix](#suffix)
  - [prefix](#prefix)
  - [extra_options](#extra_options)
  - [modules](#modules)
  - [CC](#CC)
  - [CXX](#CXX)
  - [dependency_path](#dependency_path)
    

#### repository
*default*: `'https://github.com/plumed/plumed2.git'`

By specifying the `repository` option you will install plumed from another repository
```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  with:
    repository: 'https://github.com/Iximiel/plumed2.git'
```
Will clone plumed from `https://github.com/Iximiel/plumed2.git`
    
#### version
*default*: `''`

This option will specify which plumed branch or tag the installation procedure will check out into. If not specified the latest stable version will be installed.
    
```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  with:
    version: 'master'
```
will checkout the master branch

#### suffix
*default*: `''`

This options will change the `--suffix=""` option in the configuration phase. Useful if you want to share the same installation folder with multiple plumed versions.
```yaml
- name: Install plumed master
  uses: Iximiel/install-plumed@v1
  with:
    version: 'master'
    suffix: '_master'
- name: Install plumed stable
  uses: Iximiel/install-plumed@v1
```

#### prefix
  *default*: `'~/opt'`

This option will set up the installation prefixThe installation prefix
    
#### extra_options
*default*: `'--enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings'`

Extra options for installing plumed.
The options will override the default ones, so if you want to add a extra option you will need to specify the whole string 
```yaml
- name: Install plumed master
  uses: Iximiel/install-plumed@v1
  with:
    version: 'master'
    extra_options: '--enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings --disable-mpi --disable-openmp'
```

Fora a complete installation with no parallelism.

#### modules
*default*: `'all'`

A `:` separated list of modules to install, or , will change the `--enable-modules=""` in the configure phase.
Or alternatively you can use the special keyworks `all`, `none` and `reset`.
    
```yaml
- name: Install plumed master
  uses: Iximiel/install-plumed@v1
  with:
    version: 'master'
    modules: 'reset'
```
Since the action is set up to default install everithing, using `reset` will make possible  installing only the default modules

#### CC
*default*: `'gcc'`

Specifies the C compiler or the command to use as a C compiler, see [below](#cxx)

```bash
CC=compiler_chosen CXX=compiler_chosen++ ./configure **options**
```
#### CXX
*default*: `'g++'`

Specifies the c++ compiler or the command to use as a C++ compiler

```bash
CC=compiler_chosen CXX=compiler_chosen++ ./configure **options**
```

```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  id: plumed
  with:
    modules: 'reset'
    CC: 'ccache mpicc'
    CXX: 'ccache mpic++'
```
Here plumed will be be installed using mpi and by prepending ccache you will use ccache to store some compilation artifact and speed up [new workflows](#caching-stratiegies)

#### dependency_path
*default*: `''`

If specified a file `extradeps$version.json` will be create in the specified path with the internal module dependencies.

If the variable is present, the step will also produce an output with the full path of that file.

```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  id: plumed
  with:
    modules: 'reset'
    dependency_path: '${{ github.workspace }}/_data'
    
```
In this case the module will be in your GH workspace

## Caching stratiegies
There are two caching strategies avaiable with this action

- **[ccache](https://ccache.dev/) and [actions/cache](https://github.com/actions/cache)** by storing the `~/.ccache` directory
- **[actions/cache](https://github.com/actions/cache)** by storing the installation directory

### ccache and actions/cache

Using ccache will store the compilation artifacs and speed up new runs

```yaml
name: Test

on: [push]

jobs:
  test_main:
    runs-on: ubuntu-latest

    steps:
      - name: calculate cache key for the compilation
        id: get-key
        run: |
          git clone --bare https://github.com/plumed/plumed2.git
          stable=$(cd plumed2.git ; git branch --list 'v2.*' --sort='version:refname'| sed "s/^ *//" | grep '^v2\.[0-9]*$' | tail -n 1)
          echo "key=$(cd plumed2.git ; git rev-parse "$stable")" >> $GITHUB_OUTPUT
      - uses: actions/cache@v4
        with:
          path: |
            ~/.ccache
            ~/opt
          key: ccache-${{ runner.os }}-stable-${{ steps.get-key.outputs.key }}
          restore-keys: ccache-${{ runner.os }}-stable
      - name: Set paths
        run: |
            echo "$HOME/opt/bin" >> $GITHUB_PATH
            echo "CPATH=$HOME/opt/include:$HOME/opt/libtorch/include/torch/csrc/api/include/:$HOME/opt/libtorch/include/:$HOME/opt/libtorch/include/torch:$CPATH" >> $GITHUB_ENV
            echo "INCLUDE=$HOME/opt/include:$HOME/opt/libtorch/include/torch/csrc/api/include/:$HOME/opt/libtorch/include/:$HOME/opt/libtorch/include/torch:$INCLUDE" >> $GITHUB_ENV
            echo "LIBRARY_PATH=$HOME/opt/lib:$HOME/opt/libtorch/lib:$LIBRARY_PATH" >> $GITHUB_ENV
            echo "LD_LIBRARY_PATH=$HOME/opt/lib:$HOME/opt/libtorch/lib:$LD_LIBRARY_PATH" >> $GITHUB_ENV
            echo "PYTHONPATH=$HOME/opt/lib/plumed/python:$PYTHONPATH" >> $GITHUB_ENV
            # needed to avoid MPI warning
            echo "OMPI_MCA_btl=^openib" >> $GITHUB_ENV
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install mpi-default-bin mpi-default-dev
          sudo apt install libfftw3-dev gsl-bin libgsl0-dev libboost-serialization-dev
          sudo apt install ccache
          ccache -p
          ccache -s
          mkdir -p ~/.ccache/ccache
      - name: Install plumed
        uses: Iximiel/install-plumed@v1
        with:
          modules: "reset"
          dependency_path: "${{ github.workspace }}/_data"
          CC: "ccache mpicc"
          CXX: "ccache mpic++"
        id: plumed
      - name: run plumed
        run: |
          echo "plumed path:${{ steps.plumed.outputs.plumed_prefix }}"
          ls ${{ steps.plumed.outputs.plumed_prefix }}/bin
          head ${{ steps.plumed.outputs.dependency_file }}
          plumed info --version
```
In this case, after installing ccache we also force the creation of the ccache cache with `mkdir -p ~/.ccache/ccache`.
This combined with
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.ccache
    key: ccache-${{ runner.os }}-stable-${{ steps.get-key.outputs.key }}
    restore-keys: ccache-${{ runner.os }}-stable
```
will ensure the storage of the compiler cache for subsequent runs.

### only actions/cache

```yaml
name: Test

on: [push]

jobs:
  test_main:
    runs-on: ubuntu-latest

    steps:
      - name: calculate cache key for the compilation
        id: get-key
        run: |
          git clone --bare https://github.com/plumed/plumed2.git
          stable=$(cd plumed2.git ; git branch --list 'v2.*' --sort='version:refname'| sed "s/^ *//" | grep '^v2\.[0-9]*$' | tail -n 1)
          echo "key=$(cd plumed2.git ; git rev-parse "$stable")" >> $GITHUB_OUTPUT
      - uses: actions/cache@v4
        with:
          path: ~/opt
          key: ${{ runner.os }}-stable-${{ steps.get-key.outputs.key }}
          restore-keys: ${{ runner.os }}-stable
      - name: Set paths
        run: |
            echo "$HOME/opt/bin" >> $GITHUB_PATH
            echo "CPATH=$HOME/opt/include:$HOME/opt/libtorch/include/torch/csrc/api/include/:$HOME/opt/libtorch/include/:$HOME/opt/libtorch/include/torch:$CPATH" >> $GITHUB_ENV
            echo "INCLUDE=$HOME/opt/include:$HOME/opt/libtorch/include/torch/csrc/api/include/:$HOME/opt/libtorch/include/:$HOME/opt/libtorch/include/torch:$INCLUDE" >> $GITHUB_ENV
            echo "LIBRARY_PATH=$HOME/opt/lib:$HOME/opt/libtorch/lib:$LIBRARY_PATH" >> $GITHUB_ENV
            echo "LD_LIBRARY_PATH=$HOME/opt/lib:$HOME/opt/libtorch/lib:$LD_LIBRARY_PATH" >> $GITHUB_ENV
            echo "PYTHONPATH=$HOME/opt/lib/plumed/python:$PYTHONPATH" >> $GITHUB_ENV
            # needed to avoid MPI warning
            echo "OMPI_MCA_btl=^openib" >> $GITHUB_ENV
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install mpi-default-bin mpi-default-dev
          sudo apt install libfftw3-dev gsl-bin libgsl0-dev libboost-serialization-dev
      - name: Install plumed
        uses: Iximiel/install-plumed@v1
        with:
          modules: "reset"
          dependency_path: "${{ github.workspace }}/_data"
          CC: "mpicc"
          CXX: "mpic++"
        id: plumed
      - name: run plumed
        run: |
          echo "plumed path:${{ steps.plumed.outputs.plumed_prefix }}"
          ls ${{ steps.plumed.outputs.plumed_prefix }}/bin
          head ${{ steps.plumed.outputs.dependency_file }}
          plumed info --version
```

*Iximiel/install-plumed* after compiling plumed will store an extra file that will contain the hash of the commit used to compile plumed in the installation directory (`${prefix}/plumed${suffix}/${hash}`), if *Iximiel/install-plumed* finds that file during the set up, it will assume that that version of plumed is already present and will completely skip the compilation.

The default installation path is `~/opt`, so

```yaml
- uses: actions/cache@v4
  with:
    path: ~/opt
    key: ${{ runner.os }}-stable-${{ steps.get-key.outputs.key }}
    restore-keys: ${{ runner.os }}-stable
```
will do the trick for you.

You can also combine the two approaches, expecially if you use the [`version`](#version) keyword to checkout to a branch instead of a tag.
```yaml
- uses: actions/cache@v4
  with:
    path: |
     ~/opt
     ~/.ccache
    key: ${{ runner.os }}-stable-${{ steps.get-key.outputs.key }}
    restore-keys: ${{ runner.os }}-stable
```
