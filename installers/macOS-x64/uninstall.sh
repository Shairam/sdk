#!/bin/bash
# ----------------------------------------------------------------------------------
# Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
# ----------------------------------------------------------------------------------
#
#Generate WSO2 Cellery Uninstallers for macOS.

#Parameters
DATE=`date +%Y-%m-%d`
TIME=`date +%H:%M:%S`
LOG_PREFIX="[$DATE $TIME]"

#Functions
log_info() {
    echo "${LOG_PREFIX}[INFO]" $1
}

log_warn() {
    echo "${LOG_PREFIX}[WARN]" $1
}

log_error() {
    echo "${LOG_PREFIX}[ERROR]" $1
}

getBallerinaHome() {
    if [ -z "${HOME_BALLERINA}" ]; then
        BALLERINA_VERSION=$(ballerina version | awk '{print $2}')
        BALLERINA_DEFAULT_HOME_PREFIX="/Library/Ballerina/"
        HOME_BALLERINA=${BALLERINA_DEFAULT_HOME_PREFIX}/ballerina-${BALLERINA_VERSION}
        if [ ! -d $HOME_BALLERINA ]; then
            log_error "BALLERINA_HOME cannot be found."
            exit 1
        fi
    fi
}

#Check running user
if (( $EUID != 0 )); then
    echo "Please run as root."
    exit
fi

echo "Welcome to Cellery Uninstaller"
echo "The following packages will be REMOVED:"
echo "  cellery"
while true; do
    read -p "Do you wish to continue [Y/n]?" answer
    [[ $answer == "y" || $answer == "Y" || $answer == "" ]] && break
    [[ $answer == "n" || $answer == "N" ]] && exit 0
    echo "Please answer with 'y' or 'n'"
done


#Need to replace these with install preparation script
VERSION=__VERSION__
PRODUCT=__PRODUCT__

echo "Cellery uninstalling process started"
# remove link to shorcut file
find "/usr/local/bin/" -name "cellery" | xargs rm
if [ $? -eq 0 ]
then
  echo "[1/5] [DONE] Successfully deleted shortcut links"
else
  echo "[1/5] [ERROR] Could not delete shortcut links" >&2
fi

#forget from pkgutil
pkgutil --forget "org.$PRODUCT.$VERSION" > /dev/null 2>&1
if [ $? -eq 0 ]
then
  echo "[2/5] [DONE] Successfully deleted cellery informations"
else
  echo "[2/5] [ERROR] Could not delete cellery informations" >&2
fi
#remove cellery depended ballerina libraries
getBallerinaHome
[ -e ${HOME_BALLERINA}/bre/lib/cellery-*.jar ] && rm -f ${HOME_BALLERINA}/bre/lib/cellery-*.jar
if [ $? -eq 0 ]
then
  echo "[3/5] [DONE] Successfully deleted cellery ballerina dependencies"
else
  echo "[3/5] [ERROR] Could not delete cellery ballerina dependencies" >&2
fi

#remove cellery depended ballerina repo
[ -e "${HOME_BALLERINA}/lib/repo/celleryio" ] && rm -rf "${HOME_BALLERINA}/lib/repo/celleryio"
if [ $? -eq 0 ]
then
  echo "[4/5] [DONE] Successfully deleted cellery ballerina libraries"
else
  echo "[4/5] [ERROR] Could not delete cellery ballerina libraries" >&2
fi

#remove cellery source distribution
[ -e "/Library/Cellery" ] && rm -rf "/Library/Cellery"
if [ $? -eq 0 ]
then
  echo "[5/5] [DONE] Successfully deleted cellery"
else
  echo "[5/5] [ERROR] Could not delete cellery" >&2
fi

echo "Cellery uninstall process finished"
exit 0
