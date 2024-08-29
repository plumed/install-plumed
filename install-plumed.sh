#!/bin/bash
#! /bin/bash

set -e
set -x

cat <<EOF
SUFFIX="$SUFFIX"
VERSION="$VERSION"
REPO="$REPO"
PROGRAM_NAME="$PROGRAM_NAME"
EOF

# for opt; do
#     case "$opt" in
#     version=*) version="${opt#version=}" ;;
#     suffix=*)
#         suffix="--program-suffix=${opt#suffix=}"
#         program_name="plumed${opt#suffix=}"
#         ;;
#     REPO=*) REPO="${opt#REPO=}" ;;
#     *)
#         echo "unknown option $opt"
#         exit 1
#         ;;
#     esac
# done

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

    rm -fr "$HOME/opt/lib/$PROGRAM_NAME"
    rm -fr "$HOME/opt/bin/$PROGRAM_NAME"
    rm -fr "$HOME/opt/include/$PROGRAM_NAME"
    rm -fr "$HOME"/opt/lib/lib$PROGRAM_NAME.so*
    cat <<EOF
    ./configure --prefix="$HOME/opt" \
        --enable-modules=all \
        --enable-boost_serialization \
        --enable-fftw $SUFFIX \
        --enable-libtorch LDFLAGS=-Wl,-rpath,$LD_LIBRARY_PATH


    make -j 5
    make install

    touch "$HOME/opt/lib/$PROGRAM_NAME/$hash"
EOF
fi
