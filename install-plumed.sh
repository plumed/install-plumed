#! /bin/bash

cat <<EOF
REPO="$REPO"
VERSION="$VERSION"
PROGRAM_NAME="$PROGRAM_NAME"
SUFFIX="$SUFFIX"
PREFIX="$PREFIX"
EOF

cd "$(mktemp -dt plumed.XXXXXX)" || {
    echo "Failed to create tempdir"
    exit 1
}

git clone $REPO
cd plumed2

if [[ -n "$VERSION" ]]; then
    echo "installing plumed $VERSION"
else
    VERSION=$(git tag --sort=version:refname |
        grep '^v2\.[0-9][0-9]*\.[0-9][0-9]*' |
        tail -n 1)
    echo "installing latest stable plumed $VERSION"
fi

plumed_options="$EXTRA_OPTIONS"
if [[ -n "$SUFFIX" ]]; then
    plumed_options="$plumed_options --program-suffix=\"$SUFFIX\""
fi

if [[ -n "$PREFIX" ]]; then
    plumed_options="$plumed_options --prefix=\"$PREFIX\""
fi
if [[ -n "$MODULES" ]]; then
    plumed_options="$plumed_options --enable-modules=$MODULES"
fi

#cheking out to $VERSION before compiling the dependency json for this $VERSION
git checkout $VERSION

if [[ $SETDEPENDENCIES ]]; then
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
    } >"$GITHUB_WORKSPACE/_data/extradeps$VERSION.json"
fi
hash=$(git rev-parse HEAD)

if [[ -f $HOME/opt/lib/$PROGRAM_NAME/$hash ]]; then
    echo "ALREADY AVAILABLE, NO NEED TO REINSTALL"
else
    #remove the conflicting old installation
    rm -fr "$PREFIX/lib/$PROGRAM_NAME"
    rm -fr "$PREFIX/opt/bin/$PROGRAM_NAME"
    rm -fr "$PREFIX/opt/include/$PROGRAM_NAME"
    rm -fr "$PREFIX"/opt/lib/lib$PROGRAM_NAME.so*

    cat <<EOF
    ./configure --prefix="$HOME/opt" \
        --enable-modules=all \
        --enable-boost_serialization \
        --enable-fftw --program-suffix=$SUFFIX \
        --enable-libtorch LDFLAGS=-Wl,-rpath,$LD_LIBRARY_PATH

./configure $plumed_options LDFLAGS=-Wl,-rpath,$LD_LIBRARY_PATH
    make -j 5
    make install

    touch "$HOME/opt/lib/$PROGRAM_NAME/$hash"
EOF
fi

echo "plumed_path=${PREFIX}/bin" >>$GITHUB_OUTPUT
