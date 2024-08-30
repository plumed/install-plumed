#! /bin/bash

# To me: the enviromental variable I am using as input are in CAPS,
# if I modify a variable is in lower case

cat <<EOF
REPO="$REPO"
VERSION="$VERSION"
SUFFIX="$SUFFIX"
PREFIX="$PREFIX"
EOF
cd "$(mktemp -dt plumed.XXXXXX)" || {
    echo "Failed to create tempdir"
    exit 1
}

if git clone --quiet "$REPO"; then
    cd plumed2 || {
        echo "Failed to cd into plumed2"
        echo "Is the repository \"${REPO}\" a plumed repository?"
        exit 1
    }
else
    echo "Failed to clone plumed2"
    exit 1
fi

version=$VERSION

if [[ -n "$version" ]]; then
    echo "installing plumed $version"
else
    version=$(git tag --sort=version:refname |
        grep '^v2\.[0-9][0-9]*\.[0-9][0-9]*' |
        tail -n 1)
    echo "installing latest stable plumed $version"
fi

plumed_options="$EXTRA_OPTIONS"
program_name=plumed
if [[ -n "$SUFFIX" ]]; then
    plumed_options="$plumed_options --program-suffix=\"$SUFFIX\""
    program_name=$program_name$SUFFIX
fi

if [[ -n "$PREFIX" ]]; then
    plumed_options="$plumed_options --prefix=\"$PREFIX\""
fi
if [[ -n "$MODULES" ]]; then
    plumed_options="$plumed_options --enable-modules=$MODULES"
fi

#cheking out to $version before compiling the dependency json for this $version
git checkout --quiet $version

if [[ -n $DEPPATH ]]; then
    mkdir -pv "$DEPPATH"
    dependencies_file="${DEPPATH}/_data/extradeps${version}.json"
    echo "Creating a dependencies file at $dependencies_file"
    # This gets all the dependency information in plumed
    {
        firstline=""
        echo '{'
        for mod in src/*/Makefile; do
            dir=${mod%/*}
            modname=${dir##*/}
            typename=$dir/module.type

            if [[ ! -f $typename ]]; then
                modtype="always"
            else
                modtype=$(head "$typename")
            fi
            dep=$(grep USE "$mod" | sed -e 's/USE=//')

            IFS=" " read -r -a deparr <<<"$dep"
            echo -e "${firstline}\"$modname\" : {"
            echo "\"type\": \"$modtype\","
            echo -n '"depends" : ['
            pre=""
            for d in "${deparr[@]}"; do
                echo -n "${pre}\"$d\""
                pre=", "
            done
            echo ']'
            echo -n '}'
            firstline=",\n"
        done
        echo -e '\n}'
    } >"$dependencies_file"
    echo "dependencies=$dependencies_file" >>$GITHUB_OUTPUT
fi
hash=$(git rev-parse HEAD)

if [[ -f ${PREFIX}/lib/$program_name/$hash ]]; then
    echo "ALREADY AVAILABLE, NO NEED TO REINSTALL"
else
    #remove the conflicting old installation
    rm -fr "$PREFIX/lib/$program_name"
    rm -fr "$PREFIX/bin/$program_name"
    rm -fr "$PREFIX/include/$program_name"
    rm -fr "$PREFIX"/lib/lib$program_name.so*

    cat <<EOF
    ./configure --prefix="$HOME/opt" --enable-modules=all --enable-boost_serialization --enable-fftw --program-suffix=$SUFFIX --enable-libtorch LDFLAGS=-Wl,-rpath,$LD_LIBRARY_PATH

./configure $plumed_options LDFLAGS=-Wl,-rpath,$LD_LIBRARY_PATH
    make -j 5
    make install

    touch "${PREFIX}/lib/$program_name/$hash"
EOF
fi

echo "plumed_path=${PREFIX}" >>$GITHUB_OUTPUT
