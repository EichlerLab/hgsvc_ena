#!/usr/bin/env bash

# Upload XMLs to the test service

#curl -u username:$(cat password.txt) -F "SUBMISSION=@submission.xml" -F "EXPERIMENT=@experiment.xml" -F "RUN=@run.xml" "https://www.ebi.ac.uk/ena/submit/drop-box/submit/"

USER=$1
HOST=$2
OUT_FILE=$3

shift
shift
shift

echo curl -u ${USER}:PASS -o ${OUT_FILE} $@ "https://${HOST}/ena/submit/drop-box/submit/"

curl -u ${USER}:$(cat password.txt) -o ${OUT_FILE} $@ "https://${HOST}/ena/submit/drop-box/submit/"
