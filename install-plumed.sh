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

#TODO: make plumed_options an array
plumed_options="$EXTRA_OPTIONS"
program_name=plumed
if [[ -n "$SUFFIX" ]]; then
    plumed_options="$plumed_options --program-suffix=\"$SUFFIX\""
    program_name=$program_name$SUFFIX
fi

#just to be sure
prefix=${PREFIX-~/opt}
mkdir -p "$prefix"
prefix=$(realpath "$prefix")
if [[ -n "$PREFIX" ]]; then
    plumed_options="$plumed_options --prefix=\"$prefix\""
fi

if [[ -n "$MODULES" ]]; then
    plumed_options="$plumed_options --enable-modules=$MODULES"
fi

#cheking out to $version before compiling the dependency json for this $version
git checkout --quiet $version

if [[ -n $DEPPATH ]]; then
    mkdir -pv "$DEPPATH"
    dependencies_file="${DEPPATH}/extradeps${version}.json"
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

if [[ -f ${prefix}/lib/$program_name/$hash ]]; then
    echo "ALREADY AVAILABLE, NO NEED TO REINSTALL"
else
    #remove the conflicting old installation
    rm -fr "${prefix:?}/lib/$program_name"
    rm -fr "${prefix:?}/bin/$program_name"
    rm -fr "${prefix:?}/include/$program_name"
    rm -fr "${prefix:?}"/lib/lib$program_name.so*
    #{var:?} makes the shell fail to avoid unwanted "explosive" deletions in /lib and /bin

    #${LD_LIBRARY_PATH+,${LD_LIBRARY_PATH}} wil print "," then the content of LD_LIBRARY_PATH, if it is not empty
    set -x
    ./configure $plumed_options ${LD_LIBRARY_PATH+LDFLAGS=-Wl,-rpath,\"${LD_LIBRARY_PATH}\"}
    set +x
    make -j 5
    make install

    touch "${prefix}/lib/$program_name/$hash"

fi

echo "plumed_path=${prefix}" >>$GITHUB_OUTPUT
