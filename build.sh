#!/bin/sh
DRUPAL_BOOTSTRAP_VERSION="7.x-3.12"
BASE_STYLE_REPOSITORY="https://github.com/twagoo/base_style"
BASE_STYLE_VERSION="0.2.0-dev1"

BASE_DIRECTORY=$(cd "$(dirname "$BASH_SOURCE[0]")"; pwd)
OUTPUT_DIRECTORY="${BASE_DIRECTORY}/target"
BUILD_DIRECTORY="${OUTPUT_DIRECTORY}/CLARIN_Horizon/"
BUILD_PACKAGE="${OUTPUT_DIRECTORY}/CLARIN_Horizon.tgz"

set -e

#gcp and grm can be installed on MacOS via brew. Run "brew install coreutils" to do so.
RM=`which grm||which rm`  #if grm available (on Mac), use it instead of BSD rm
LOCAL_LESSC=${OUTPUT_DIRECTORY}/'node_modules/less/bin/lessc'

# Cleanup potential previous build output
${RM} -fr -- "${BUILD_DIRECTORY}" "${BUILD_PACKAGE}" "${OUTPUT_DIRECTORY}/basestyle"

# Create transient directories
mkdir -p "${OUTPUT_DIRECTORY}/basestyle"


# Install less compiler if not installed yet
if ! [ hash lessc 2>/dev/null ]; then
	if [ ! -f "${LOCAL_LESSC}" ]; then
    	echo 'Installing LESS compiler...'
    	npm set progress='false'
    	npm --silent install --prefix=${OUTPUT_DIRECTORY} --depth '0' 'less' 'less-plugin-clean-css' 1>/dev/null
    fi
    LESSC=${LOCAL_LESSC}
else
	LESSC=`which lessc`
fi
echo 'Using lessc: ' ${LESSC}

echo 'Retrieving dependencies...'
# Retrieve bootstrap drupal theme
curl --fail --location --show-error --silent --tlsv1 \
    "https://github.com/drupalprojects/bootstrap/archive/${DRUPAL_BOOTSTRAP_VERSION}.tar.gz" | \
        tar -x -z -p -C "${OUTPUT_DIRECTORY}/" -f -

# Retrieve CLARIN base style
curl --fail --location --show-error --silent --tlsv1 \
	"${BASE_STYLE_REPOSITORY}/releases/download/${BASE_STYLE_VERSION}/base-style-${BASE_STYLE_VERSION}-less-with-bootstrap.jar" | \
	tar -x -p -C ${OUTPUT_DIRECTORY}/basestyle -f -

echo 'Customising...'
# Prepare less sources transient directory inside basestyle
## Copy drupal bootstrap less files to basestyle
rsync --ignore-existing -r "${OUTPUT_DIRECTORY}/bootstrap-${DRUPAL_BOOTSTRAP_VERSION}/starterkits/less/less" "${OUTPUT_DIRECTORY}/basestyle/"
## Copy source style.less to basetyle
rsync -r "${BASE_DIRECTORY}/src/less/" "${OUTPUT_DIRECTORY}/basestyle/less/"

# Copy static theme resources into build directory
rsync -r "${BASE_DIRECTORY}/src/theme/" "${BUILD_DIRECTORY}"
## Move fonts into build directory
mv -f -- "${OUTPUT_DIRECTORY}/basestyle/fonts" "${BUILD_DIRECTORY}"

echo 'Compiling LESS...'
## Compile style from basedstyle less folder
mkdir -p "${BUILD_DIRECTORY}/css"
${LESSC} "${OUTPUT_DIRECTORY}/basestyle/less/style.less" --clean-css='--s0' > "${BUILD_DIRECTORY}/css/style.css"

echo 'Packaging...'
## Make distribution
tar -c -p -z -f "${BUILD_PACKAGE}" -C "${OUTPUT_DIRECTORY}" "CLARIN_Horizon" "bootstrap-${DRUPAL_BOOTSTRAP_VERSION}"

echo 'Done!

Result written to' ${BUILD_PACKAGE}
