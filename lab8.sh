#!/usr/bin/sh

# run below

gcloud auth list
gcloud config list project

echo "Project is ${GOOGLE_CLOUD_PROJECT} "


gcloud services disable pubsub.googleapis.com
gcloud services enable pubsub.googleapis.com

gcloud services enable run.googleapis.com
if [[ $? -eq "0" ]]; then
    echo "Run service enabled"
else
    echo "Run service could not be started"
fi

gcloud config set compute/region us-central1
LOCATION="us-central1"

gcloud run deploy store-service \
 --image gcr.io/qwiklabs-resources/gsp724-store-service \
 --region $LOCATION \
 --allow-unauthenticated


read -n 1 -p "Checked your progress on lab?" q1

gcloud run deploy order-service \
 --image gcr.io/qwiklabs-resources/gsp724-order-service \
 --region $LOCATION \
 --no-allow-unauthenticated


read -n 1 -p "Checked your progress on lab?" q2



# Create TOPIC

gcloud pubsub topics create ORDER_PLACED
read -n 1 -p "Checked your progress on lab?" q2

gcloud iam service-accounts create pubsub-cloud-run-invoker \
   --display-name "Order Initiator"
read -n 1 -p "Checked your progress on lab?" q2
gcloud iam service-accounts list --filter="Order Initiator"

gcloud run services add-iam-policy-binding order-service \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker --platform managed

PROJECT_NUMBER=$(gcloud projects list \
  --filter="qwiklabs-gcp" \
  --format='value(PROJECT_NUMBER)')

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
   --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
   --role=roles/iam.serviceAccountTokenCreator


# Subscription

ORDER_SERVICE_URL=$(gcloud run services describe order-service \
   --region $LOCATION \
   --format="value(status.address.url)")

gcloud pubsub subscriptions create order-service-sub \
   --topic ORDER_PLACED \
   --push-endpoint=$ORDER_SERVICE_URL \
   --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

read -n 1 -p "Checked your progress on lab?" q2




cat > ./test.json <<EOF
{
  "billing_address": {
    "name": "Kylie Scull",
    "address": "6471 Front Street",
    "city": "Mountain View",
    "state_province": "CA",
    "postal_code": "94043",
    "country": "US"
  },
  "shipping_address": {
    "name": "Kylie Scull",
    "address": "9902 Cambridge Grove",
    "city": "Martinville",
    "state_province": "BC",
    "postal_code": "V1A",
    "country": "Canada"
  },
  "items": [
    {
      "id": "RW134",
      "quantity": 1,
      "sub-total": 12.95
    },
    {
      "id": "IB541",
      "quantity": 2,
      "sub-total": 24.5
    }
 ]
}
EOF


STORE_SERVICE_URL=$(gcloud run services describe store-service \
   --region $LOCATION \
   --format="value(status.address.url)")

curl -X POST -H "Content-Type: application/json" -d @test.json $STORE_SERVICE_URL

read -n 1 -p "check order details in Console" q3

 

