#!/bin/sh
PACKAGE_VERSION="0.1.2"
DRUPAL_BOOTSTRAP_VERSION="7.x-3.12"
BASE_STYLE_REPOSITORY="https://github.com/clarin-eric/base_style"
BASE_STYLE_VERSION="0.2.0"

BASE_DIRECTORY=$(cd "$(dirname "$BASH_SOURCE[0]")"; pwd)
OUTPUT_DIRECTORY="${BASE_DIRECTORY}/target"
BUILD_DIRECTORY="${OUTPUT_DIRECTORY}/CLARIN_Horizon/"
BUILD_PACKAGE="${OUTPUT_DIRECTORY}/CLARIN_Horizon-${PACKAGE_VERSION}.tgz"

set -e

#gcp and grm can be installed on MacOS via brew. Run "brew install coreutils" to do so.
RM=`which grm||which rm`  #if grm available (on Mac), use it instead of BSD rm
LOCAL_LESSC=${OUTPUT_DIRECTORY}/'node_modules/less/bin/lessc'

# Cleanup potential previous build output
${RM} -fr -- "${BUILD_DIRECTORY}" "${BUILD_PACKAGE}" "${OUTPUT_DIRECTORY}/basestyle"

# Create transient directories
mkdir -p "${OUTPUT_DIRECTORY}/basestyle"
mkdir -p "${OUTPUT_DIRECTORY}/bootstrap-${DRUPAL_BOOTSTRAP_VERSION}"
mkdir -p "${BUILD_DIRECTORY}/js"


# Install less compiler if not installed yet
if ! [ hash lessc 2>/dev/null ]; then
	if [ ! -f "${LOCAL_LESSC}" ]; then
    	echo 'Installing LESS compiler...'
        npm cache clean
    	npm set progress='false'
    	npm  install --prefix=${OUTPUT_DIRECTORY} --depth '0' 'less' 1>/dev/null
        npm  install --prefix=${OUTPUT_DIRECTORY} --depth '0' 'less-plugin-clean-css' 1>/dev/null
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
        tar -x -z -p --strip-components 1 -C "${OUTPUT_DIRECTORY}/bootstrap-${DRUPAL_BOOTSTRAP_VERSION}/" -f - "bootstrap-${DRUPAL_BOOTSTRAP_VERSION}"

# Retrieve CLARIN base style
curl --fail --location --show-error --silent --tlsv1 \
	"${BASE_STYLE_REPOSITORY}/releases/download/${BASE_STYLE_VERSION}/base-style-${BASE_STYLE_VERSION}-less-with-bootstrap.jar" | \
	bsdtar -x -p -C ${OUTPUT_DIRECTORY}/basestyle -f -

echo 'Customising...'
# Prepare less sources transient directory inside basestyle
## Copy drupal bootstrap less files to basestyle
rsync --ignore-existing -r "${OUTPUT_DIRECTORY}/bootstrap-${DRUPAL_BOOTSTRAP_VERSION}/starterkits/less/less" "${OUTPUT_DIRECTORY}/basestyle/"
## Copy source style.less to basetyle
rsync -r "${BASE_DIRECTORY}/src/less/" "${OUTPUT_DIRECTORY}/basestyle/less/"

# Copy static theme resources into package directory
rsync -r "${BASE_DIRECTORY}/src/theme/" "${BUILD_DIRECTORY}"
## Move fonts into package directory
mv -f -- "${OUTPUT_DIRECTORY}/basestyle/fonts" "${BUILD_DIRECTORY}"
## Move bootstrap.js library into package directory
mv -f -- "${OUTPUT_DIRECTORY}/basestyle/js/" "${BUILD_DIRECTORY}/js/bootstrap"

echo 'Compiling LESS...'
## Compile style from basedstyle less folder
mkdir -p "${BUILD_DIRECTORY}/css"
pwd
cd `dirname ${LESSC}`
pwd
ls -Fla
./lessc "${OUTPUT_DIRECTORY}/basestyle/less/style.less" --clean-css='--s0' > "${BUILD_DIRECTORY}/css/style.css"

echo 'Packaging...'
## Make distribution
tar -c -p -z -f "${BUILD_PACKAGE}" -C "${OUTPUT_DIRECTORY}" "CLARIN_Horizon" "bootstrap-${DRUPAL_BOOTSTRAP_VERSION}"

echo 'Done!

Result written to' ${BUILD_PACKAGE}
