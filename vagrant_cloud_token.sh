#!/bin/bash

# imports
. ./lib/functions.sh
require_commands curl jq

if [ -f ./vagrant-cloud-token ]; then
	echo "Using previously stored auth token."
	VAGRANT_CLOUD_TOKEN=`cat ./vagrant-cloud-token`	
else
	echo "No auth token found."
	echo
	echo "We will do the upload via API on the behalf of your Vagrant Cloud"
	echo "account. For this we will use an auth token. Please keep this token"
	echo "in a secure place or delete it after upload."
	echo
	echo "Please enter your Vagrant Cloud credentials to proceed:"
	echo
	echo -n "Username: "
	read auth_username
	echo -n "Password: "
	read -s auth_password
	echo
	echo
	
	# Request auth token
	upload_auth_request=$( \
	curl -sS \
	  --header "Content-Type: application/json" \
	  https://app.vagrantup.com/api/v1/authenticate \
	  --data '{"token": {"description": "Login from cURL"},"user": {"login": "'$auth_username'","password": "'$auth_password'"}}' \
	)
	
	upload_auth_request_success=`echo $upload_auth_request | jq '.success'`
	if [ $upload_auth_request_success == 'false' ]; then
		echo "Request for auth token failed."
		echo "Response from API:"
		echo $upload_auth_request | jq
		echo "Please consult the error above and try again."
		exit 1
	fi
	
	VAGRANT_CLOUD_TOKEN=`echo $upload_auth_request | jq '.token' | tr -d '"'`
	
	echo "OK, we got authorized."
	
	read -p "Do you want to store the auth token for future use (y/N)? " choice
	case "$choice" in 
	  y|Y ) echo "Storing auth token ..."
	  		echo $VAGRANT_CLOUD_TOKEN > ./vagrant-cloud-token
	  		chmod 600 ./vagrant-cloud-token
	        ;;
	  * ) echo "Not storing auth token."
	      ;;
	esac
	
fi

export VAGRANT_CLOUD_TOKEN
