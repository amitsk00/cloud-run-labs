#!/usr/bin/sh

# run below

LOCATION="us-central1"

# gcloud auth list
# gcloud config list project

echo "Project is ${GOOGLE_CLOUD_PROJECT} "
echo "Location - ${LOCATION} "

echo -e "\tDeleting images"
gcloud container images delete gcr.io/$GOOGLE_CLOUD_PROJECT/helloworld --quiet
echo -e "\tDeleting Run Services"
gcloud run services delete helloworld --region=$LOCATION --quiet

