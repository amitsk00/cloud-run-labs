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

gcloud beta run deploy quickway-parking-billing-v1 \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $LOCATION \
  --allow-unauthenticated

QUICKWAY_SERVICE=$(gcloud run services list \
  --format='value(URL)' \
  --filter="quickway")

read -n 1 -p "check in Console for the Cloud Run for showing issues, if any " q2


# add IAM to Run

gcloud run services delete quickway-parking-billing-v1
gcloud run deploy quickway-parking-billing-v2 \
  --image gcr.io/qwiklabs-resources/gsp723-parking-service \
  --region $LOCATION \
  --no-allow-unauthenticated


echo "create SA online in Console"
