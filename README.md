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

Iximiel/install-plumed@main installs plumed in your workflow in a standardize fashion.

This action synergise with using [ccache](https://ccache.dev/) and [actions/gh-actions-cache](https://github.com/actions/gh-actions-cache).

An example of calling this action in your workflow is:

```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  id: plumed
  with:
    modules: "reset"
    dependency_path: "${{ github.workspace }}/_data"
    CC: "ccache mpicc"
    CXX: "ccache mpic++"
```
Here plumed will be installed as if it is configured with:
```bash
 CC="ccache mpicc" CXX="ccache mpic++" ./configure --enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings --prefix=/home/runner/opt --enable-modules=reset 'LDFLAGS=-Wl,-rpath,"/home/runner/opt/lib:/home/runner/opt/libtorch/lib:"'
```
And it is creating a json file in `${{ github.workspace }}/_data` that hosts a list of plumed internal module dependencies.

## Output

This action outputs two parameters:
 - **plumed_prefx** the path where plumed has installed into
 - **dependency_file** the full path of the dependency file created if `dependency_path` is specified (see below).
 
 In the previous example you can access to them within the job with: `${{ steps.plumed.outputs.plumed_prefx }}` and  `${{ steps.plumed.outputs.dependency_file }}`
## Options

You are not required to use any option, with everithing set to default plumed will be configured with:

```bash
CC="gcc" CXX="g++" ./configure --enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings --prefix=~/opt --enable-modules=all LDFLAGS=-Wl,-rpath,${LD_LIBRARY_PATH}
```

Plumed will be cloned from `https://github.com/plumed/plumed2.git` and the script will automatically install the latest stable version.

- Options

#### repository:
By specifying the `repository` option you will install plumed from another repository
    ```yaml
- name: Install plumed
  uses: Iximiel/install-plumed@v1
  with:
    modules: "reset"
    dependency_path: "${{ github.workspace }}/_data"
    CC: "ccache mpicc"
    CXX: "ccache mpic++"
```
    default: 'https://github.com/plumed/plumed2.git'
  #### version:
    description: 'The version of plumed to install (default to master)'
    required: false
    default: ''
  suffix:
    description: 'Suffix for the program name'
    required: false
    default: ''
  prefix:
    description: 'The installation prefix'
    required: false
    default: '~/opt'
  extra_options:
    description: 'Extra options for installing plumed'
    required: false
    default: '--enable-boost_serialization --enable-fftw --enable-libtorch --disable-basic-warnings'
  modules:
    description: 'List of modules to install, or "all"'
    required: false
    default: 'all'
  CC:
    description: 'C compiler'
    required: false
    default: 'gcc'
  CXX:
    description: 'C++ compiler'
    required: false
    default: 'g++'
  dependency_path:
    description: 'Path where to store "extradeps$version.json"'
    required: false
    default: ''