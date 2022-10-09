#!/usr/bin/sh

# run below

gcloud auth list
gcloud config list project

echo "Project is ${GOOGLE_CLOUD_PROJECT} "

gcloud services enable run.googleapis.com
if [[ $? -eq "0" ]]; then
    echo "Run service enabled"
else
    echo "Run service could not be started"
fi

gcloud config set compute/region us-central1
LOCATION="us-central1"

git clone https://github.com/GoogleCloudPlatform/buildpack-samples.git

cd buildpack-samples/sample-python
pack build --builder=gcr.io/buildpacks/builder sample-python

docker run -it -e PORT=8080 -p 8080:8080 sample-python

# now check the web preview 
# echo "if web preview checked , enter y"
read  -n 1 -p "if web preview checked , enter y:" mainmenuinput


# Cloud Run here
ls -latrh 
gcloud beta run deploy --source .
