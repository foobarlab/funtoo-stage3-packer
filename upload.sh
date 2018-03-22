#!/bin/bash -e
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

. config.sh

command -v curl >/dev/null 2>&1 || { echo "Command 'curl' required but it's not installed.  Aborting." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Command 'jq' required but it's not installed.  Aborting." >&2; exit 1; }

echo "This script will upload the current build box to Vagrant Cloud."
echo
echo "User:     $BUILD_BOX_USERNAME"
echo "Box:      $BUILD_BOX_NAME"
echo "Provider: $BUILD_BOX_PROVIDER"
echo "Version:  $BUILD_BOX_VERSION"
echo
echo "Please verify if above information is correct."
echo "We will do the upload via API on the behalf of your Vagrant Cloud login."
echo

read -p "Continue (Y/n)? " choice
case "$choice" in 
  n|N ) echo "User cancelled."
  		exit 0
        ;;
  * ) echo
  		;;
esac

if [ -f ./vagrant-cloud-credentials ]; then
	echo "Using Vagrant Cloud credentials from 'vagrant-cloud-credentials' file ..."
	AUTH_USERNAME=`awk -F ":" '{ print $1 }' ./vagrant-cloud-credentials` 
	AUTH_PASSWORD=`awk -F ":" '{ print $2 }' ./vagrant-cloud-credentials`
else
	echo "Please enter your Vagrant Cloud credentials to proceed ..."
	echo
	echo -n "Username: "
	read AUTH_USERNAME
	echo -n "Password: "
	read -s AUTH_PASSWORD
	echo
	echo
	read -p "Do you want to store your credentials for future use (y/N)? " choice
	case "$choice" in 
	  y|Y ) echo "Storing Vagrant Cloud credentials in 'vagrant-cloud-credentials' file ..."
	  		echo $AUTH_USERNAME:$AUTH_PASSWORD > ./vagrant-cloud-credentials
	  		chmod 600 ./vagrant-cloud-credentials
	        ;;
	  * ) echo "Not storing credentials."
	      ;;
	esac
fi

# Request auth token
UPLOAD_AUTH_REQUEST=$( \
curl -sS \
  --header "Content-Type: application/json" \
  https://app.vagrantup.com/api/v1/authenticate \
  --data '{"token": {"description": "Login from cURL"},"user": {"login": "'$AUTH_USERNAME'","password": "'$AUTH_PASSWORD'"}}' \
)

UPLOAD_AUTH_REQUEST_SUCCESS=`echo $UPLOAD_AUTH_REQUEST | jq '.success'`
if [ $UPLOAD_AUTH_REQUEST_SUCCESS == 'false' ]; then echo "Authentication failed. Please try again."; exit 1; fi

VAGRANT_CLOUD_TOKEN=`echo $UPLOAD_AUTH_REQUEST | jq '.token' | tr -d '"'`

echo "OK, we got authorized."

# Create a new box
echo "Trying to create a new box '$BUILD_BOX_NAME' ..."
UPLOAD_CREATE_BOX=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/boxes \
  --data '{ "box": { "username": "'$BUILD_BOX_USERNAME'", "name": "'$BUILD_BOX_NAME'" } }' \
)

UPLOAD_CREATE_BOX_SUCCESS=`echo $UPLOAD_CREATE_BOX | jq '.success'`
if [ $UPLOAD_CREATE_BOX_SUCCESS == 'false' ]; then
	# we get an error if the box name already exists so we can most likely ignore that error silently
	UPLOAD_BOX_NAME_ALREADY_TAKEN=`echo $UPLOAD_CREATE_BOX | jq '.errors' | jq 'contains(["Type has already been taken"])'`
	if [ $UPLOAD_BOX_NAME_ALREADY_TAKEN == 'true' ]; then
		echo "OK, the box name '$BUILD_BOX_NAME' seems already taken. No need to create a new box name."
	else
		echo "Error response from API:"
		echo $UPLOAD_CREATE_BOX | jq '.errors'
		exit 1
	fi
else
	echo "OK, we created a new box named '$BUILD_BOX_NAME'."
fi

# Create a new version
echo "Trying to create a new version '$BUILD_BOX_VERSION' ..."
UPLOAD_NEW_VERSION=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/versions \
  --data '{ "version": { "version": "'$BUILD_BOX_VERSION'", "description": "'$BUILD_BOX_DESCRIPTION'" } }' \
)

UPLOAD_NEW_VERSION_SUCCESS=`echo $UPLOAD_NEW_VERSION | jq '.success'`
if [ $UPLOAD_NEW_VERSION_SUCCESS == 'false' ]; then
	# we get an error if the box version already exists so we can most likely ignore that error silently
	UPLOAD_BOX_VERSION_ALREADY_TAKEN=`echo $UPLOAD_NEW_VERSION | jq '.errors' | jq 'contains(["Version has already been taken"])'`
	if [ $UPLOAD_BOX_VERSION_ALREADY_TAKEN == 'true' ]; then
		echo "OK, the box version '$BUILD_BOX_VERSION' seems already taken. No need to create a new version."
	else
		echo "Error response from API:"
		echo $UPLOAD_NEW_VERSION | jq '.errors'
		exit 1
	fi
else
	echo "OK, we created a new version '$BUILD_BOX_VERSION'."
fi

# Create a new provider
echo "Trying to create a new provider '$BUILD_BOX_PROVIDER' ..."
UPLOAD_NEW_PROVIDER=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/providers \
  --data '{ "provider": { "name": "'$BUILD_BOX_PROVIDER'" } }' \
)

UPLOAD_NEW_PROVIDER_SUCCESS=`echo $UPLOAD_NEW_PROVIDER | jq '.success'`
if [ $UPLOAD_NEW_PROVIDER_SUCCESS == 'false' ]; then
	# we get an error if the provider already exists so we can most likely ignore that error silently
	UPLOAD_PROVIDER_ALREADY_EXISTS=`echo $UPLOAD_NEW_PROVIDER | jq '.errors' | jq 'contains(["Metadata provider must be unique for version"])'`
	if [ $UPLOAD_PROVIDER_ALREADY_EXISTS == 'true' ]; then
		echo "OK, the provider '$BUILD_BOX_PROVIDER' seems already taken. No need to create a new provider."
	else
		echo "Error response from API:"
		echo $UPLOAD_NEW_PROVIDER | jq '.errors'
		exit 1
	fi
else
	echo "OK, we created a new provider '$BUILD_BOX_PROVIDER'."
fi

# Prepare the provider for upload/get an upload URL
echo "Requesting upload url ..."
UPLOAD_PREPARE_UPLOADURL=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/provider/$BUILD_BOX_PROVIDER/upload \
)

UPLOAD_PREPARE_UPLOADURL_SUCCESS=`echo $UPLOAD_PREPARE_UPLOADURL | jq '.success'`
if [ $UPLOAD_PREPARE_UPLOADURL_SUCCESS == 'false' ]; then
	echo "Error response from API:"
	echo $UPLOAD_PREPARE_UPLOADURL | jq '.errors'
else
	echo "OK, we have received an upload url."
fi

# Extract the upload URL from the response (requires the jq command)
UPLOAD_URL=$(echo "$UPLOAD_PREPARE_UPLOADURL" | jq '.upload_path' | tr -d '"')

# Perform the upload
echo "Trying to upload ... This may take a while ..."
curl --progress-bar \
     $UPLOAD_URL \
     --request PUT \
     --upload-file $BUILD_OUTPUT_FILE

# TODO: validate successful upload
echo "Upload finished."

# Release the version
echo "Releasing box ..."
UPLOAD_RELEASE_BOX=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/release \
  --request PUT \
)

echo "Final response from API:"
echo $UPLOAD_RELEASE_BOX | jq

echo "All done."
