#!/usr/bin/env bash

# Upload XMLs to the test service

echo "Username: $1"
echo "Upload source: $2"
echo "Upload dest: $3"


# FTP with curl
echo
echo curl --ftp-create-dirs --ftp-pasv --user ${1}:$(cat password.txt) -T ${2} ftp://webin.ebi.ac.uk/${3}
echo

#curl --ftp-create-dirs --ftp-pasv --user ${1}:$(cat password.txt) -T ${2} ftp://webin.ebi.ac.uk/${3}/$(basename ${2})
curl --ftp-create-dirs --ftp-pasv --user ${1}:$(cat password.txt) -T ${2} ftp://webin.ebi.ac.uk/${3}

# Aspera
# ASPERA_SCP_PASS=$(cat password.txt) ascp -q -d -p -QT -l300M -L- $2 $1@webin.ebi.ac.uk:$3
