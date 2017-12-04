#!/bin/bash
# ----------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Saegereistrasse 29, 8152 Glattbrugg, Switzerland
# ----------------------------------------------------------------------
# Name.......: setup_oud.sh 
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2017.12.04
# Revision...: 
# Purpose....: Setup script for docker base image 
# Notes......: Requires MOS credentials in .netrc
# Reference..: --
# License....: CDDL 1.0 + GPL 2.0
# ----------------------------------------------------------------------
# Modified...: 
# see git revision history for more information on changes/updates
# TODO.......: 
# TODO parametize OUD DATA
# ----------------------------------------------------------------------

# get the MOS Credentials
MOS_USER="${1#*=}"
MOS_PASSWORD="${2#*=}"

# Download and Package Variables
# Oracle Unified Directory 12.2.1.3
export FMW_OUD_URL="https://updates.oracle.com/Orion/Services/download/p26270957_122130_Generic.zip?aru=21504981&patch_file=p26270957_122130_Generic.zip"
export FMW_OUD_PKG=${FMW_OUD_URL#*patch_file=}
export FMW_OUD_JAR=fmw_12.2.1.3.0_oud.jar

# Oracle Fusion Middleware Infrastructure
export FMW_URL="https://updates.oracle.com/Orion/Services/download/p26269885_122130_Generic.zip?aru=21502041&patch_file=p26269885_122130_Generic.zip"
export FMW_PKG=${FMW_URL#*patch_file=}
export FMW_JAR=fmw_12.2.1.3.0_infrastructure.jar

# create a .netrc if it does not exists
if [[ ! -z "${MOS_USER}" ]]; then
    if [[ ! -z "${MOS_PASSWORD}" ]]; then
        echo "machine login.oracle.com login ${MOS_USER} password ${MOS_PASSWORD}" >${DOCKER_SCRIPTS}/.netrc
    else
        echo "MOS_PASSWORD is empty"
    fi
elif [ ! -e ${DOCKER_SCRIPTS}/.netrc ]; then
    >&2 echo "================================================================================="
    >&2 echo "MOS_USER nor .netrc definend. Download from MOS will fail. "
    >&2 echo "Make sure to copy ${FMW_PKG} and "
    >&2 echo "${FMW_OUD_PKG} to software."
    >&2 echo "================================================================================="
fi

# set the response_file and inventory loc file
export RESPONSE_FILE="${ORACLE_BASE}/local/etc/install.rsp"
export INS_LOC_FILE="${ORACLE_BASE}/local/etc/oraInst.loc"

# Download Fusion Middleware Infrastructure 12.2.1.3.0 if it doesn't exist /tmp/download
if [ ! -e ${DOWNLOAD}/${FMW_PKG} ]
then
    echo "--- Download Fusion Middleware Infrastructure 12.2.1.3.0 from MOS --------------"
    curl --netrc-file ${DOCKER_SCRIPTS}/.netrc --cookie-jar ${DOWNLOAD}/cookie-jar.txt \
    --location-trusted $FMW_URL -o ${DOWNLOAD}/${FMW_PKG}
else
    echo "--- Use local copy of ${DOWNLOAD}/${FMW_PKG} ----------------"
fi

echo "--- Install Fusion Middleware Infrastructure 12.2.1.3.0 ------------------------"
cd ${DOWNLOAD}
jar xf ${DOWNLOAD}/${FMW_PKG}
cd -

# Install FMW in silent mode
java -jar ${DOWNLOAD}/$FMW_JAR -silent \
    -responseFile "${RESPONSE_FILE}" \
    -invPtrLoc "${INS_LOC_FILE}" \
    -ignoreSysPrereqs -force \
    -novalidation ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME} \
    INSTALL_TYPE="WebLogic Server"

# Download Oracle Unified Directory 12.2.1.3.0 if it doesn't exist /tmp/download
if [ ! -e ${DOWNLOAD}/${FMW_OUD_PKG} ]
then
    echo "--- Download Oracle Unified Directory 12.2.1.3.0 from OTN ----------------------"
    curl --netrc-file ${DOCKER_SCRIPTS}/.netrc --cookie-jar ${DOWNLOAD}/cookie-jar.txt \
    --location-trusted ${FMW_OUD_URL} -o ${DOWNLOAD}/${FMW_OUD_PKG}
else
    echo "--- Use local copy of ${DOWNLOAD}/${FMW_OUD_PKG} ----------------"
fi  

echo "--- Install Oracle Unified Directory 12.2.1.3.0 --------------------------------"
cd ${DOWNLOAD}
jar xf ${DOWNLOAD}/${FMW_OUD_PKG}
cd -

# Install OUD in silent mode
java -jar ${DOWNLOAD}/$FMW_OUD_JAR -silent \
    -responseFile "${RESPONSE_FILE}" \
    -invPtrLoc "${INS_LOC_FILE}" \
    -ignoreSysPrereqs -force \
    -novalidation ORACLE_HOME=${ORACLE_BASE}/product/${ORACLE_HOME_NAME} \
    INSTALL_TYPE="Collocated Oracle Unified Directory Server (Managed through WebLogic server)"

# clean up
echo "--- Clean up yum cache and temporary download files ----------------------------"
rm -rf ${DOWNLOAD}/*
echo "=== Done runing $0 ==================================="