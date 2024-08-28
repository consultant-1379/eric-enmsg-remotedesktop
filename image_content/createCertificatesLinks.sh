#!/bin/bash

echo "init $SERVICE_NAME service"

# from deployment.yaml
TLS_DIR=$TLS_MOUNT_PATH
TLS_LOCATION=tlsStoreLocation
TLS_DATA=tlsStoreData
TLS_NONE=none
SLEEP_TIME=5

echo "STARTUP $SERVICE_NAME service: looking for secrets"

scan_tlslocation () {

  # counters for directory and ready state
  tlsSecretCounter=0
  tlsLocationCounter=0

  # loop in TLS_MOUNT_PATH directory to find all mounted secrets
  # to create links where requested
  echo "loop in ${TLS_DIR}"
  for _secret_mount_ in ${TLS_DIR}/*
  do
    echo "${_secret_mount_} found"
    if [ -d ${_secret_mount_} ]; then

      echo "${_secret_mount_} is a mount point directory"
      tlsSecretCounter=$((tlsSecretCounter+1))

      # loop inside the folder
      for _tls_store_ in ${_secret_mount_}/*
        do
          echo "${_tls_store_} found"
          if [[ ${_tls_store_} == *"${TLS_LOCATION}"* ]]; then
            # check contents
            echo "content of ${_tls_store_} is $(< ${_tls_store_})"
	    if [[ $(< ${_tls_store_}) != "${TLS_NONE}" ]]; then
              echo "valid LOCATION found"
	      # increment ready state counter
	      tlsLocationCounter=$((tlsLocationCounter+1))
            fi
          fi
        done
    fi	
  done

  # check result
  echo "tlsSecretCounter = $tlsSecretCounter"
  echo "tlsLocationCounter = $tlsLocationCounter"
  
  if [ $tlsLocationCounter > 0 ]; then
    if [ $tlsSecretCounter == $tlsLocationCounter ]; then
      return 0
    fi
  fi
  return -1
}

while true
do
  echo "----"
  scan_tlslocation
  res=$?
  echo "res = $res"
  if [  $res == 0 ]; then
    echo "all locations found for $SERVICE_NAME service: OK"
    break
  fi
  sleep $SLEEP_TIME
done

# make links to keystores
for  _secret_mount_ in ${TLS_DIR}/*
do
  if [ -d ${_secret_mount_} ]
  then
    tlsFilename=$(cat ${_secret_mount_}/${TLS_LOCATION})
    echo "MAKE LINKS"
    echo ${tlsFilename}
    ln -s ${_secret_mount_}/${TLS_DATA} ${tlsFilename}
  fi
done

# random delay to extend over time the startup of the replicas of the service 
echo "wait to terminate"
sleep $[ ( $RANDOM % 10 )  + 1 ]s
echo "------------ end of createCertificatesLinks"
