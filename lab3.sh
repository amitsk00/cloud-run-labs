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

gcloud run deploy product-service \
   --image gcr.io/qwiklabs-resources/product-status:0.0.1 \
   --tag test1 \
   --region $LOCATION \
   --allow-unauthenticated

TEST1_PRODUCT_SERVICE_URL=$(gcloud run services describe product-service --platform managed --region us-central1 --format="value(status.address.url)")
curl $TEST1_PRODUCT_SERVICE_URL/help -w "\n"

curl $TEST1_PRODUCT_SERVICE_URL/v1/revision -w "\n"


# deploying a new revision here
read -n 1 -p "Proceed with new revision?" q1 

gcloud run deploy product-service \
  --image gcr.io/qwiklabs-resources/product-status:0.0.2 \
  --no-traffic \
  --tag test2 \
  --region=$LOCATION \
  --allow-unauthenticated

TEST2_PRODUCT_STATUS_URL=$(gcloud run services describe product-service --platform managed --region=us-central1 --format="value(status.traffic[2].url)")

curl $TEST2_PRODUCT_STATUS_URL/help -w "\n"




# check with traffic divided to 50%

gcloud run services update-traffic product-service \
  --to-tags test2=50 \
  --region=$LOCATION

for i in {1..10}; do curl $TEST1_PRODUCT_SERVICE_URL/help -w "\n"; done

# Roll back revision

gcloud run services update-traffic product-service \
  --to-tags test2=0 \
  --region=$LOCATION

for i in {1..10}; do curl $TEST1_PRODUCT_SERVICE_URL/help -w "\n"; done



# Deploy more revisions

gcloud run deploy product-service \
  --image gcr.io/qwiklabs-resources/product-status:0.0.3 \
  --no-traffic \
  --tag test3 \
  --region=$LOCATION \
  --allow-unauthenticated

gcloud run deploy product-service \
  --image gcr.io/qwiklabs-resources/product-status:0.0.4 \
  --no-traffic \
  --tag test4 \
  --region=$LOCATION \
  --allow-unauthenticated

gcloud run services describe product-service \
  --region=$LOCATION \
  --format='value(status.traffic.revisionName)'

LIST=$(gcloud run services describe product-service --platform=managed --region=$LOCATION --format='value[delimiter="=25,"](status.traffic.revisionName)')"=25"

gcloud run services update-traffic product-service \
  --to-revisions $LIST --region=$LOCATION

for i in {1..10}; do curl $TEST1_PRODUCT_SERVICE_URL/help -w "\n"; done






gcloud run services update-traffic product-service --to-latest --platform=managed --region=$LOCATION
LATEST_PRODUCT_STATUS_URL=$(gcloud run services describe product-service --platform managed --region=$LOCATION --format="value(status.address.url)")
curl $LATEST_PRODUCT_STATUS_URL/help -w "\n"




