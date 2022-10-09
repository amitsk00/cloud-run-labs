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


# create service

git clone https://github.com/GoogleCloudPlatform/buildpack-samples.git
cd buildpack-samples/sample-go
pack build --builder=gcr.io/buildpacks/builder sample-go

docker run -it -e PORT=8080 -p 8080:8080 sample-go

read -n 1 -p "check the web preview and then enter Y"  q2

pack set-default-builder gcr.io/buildpacks/builder:v1
pack build --publish gcr.io/$GOOGLE_CLOUD_PROJECT/sample-go



# Network

gcloud compute networks list

gcloud compute networks subnets create mysubnet \
   --range=192.168.0.0/28 --network=default --region=$LOCATION

gcloud compute networks vpc-access connectors create myconnector \
  --region=$LOCATION \
  --subnet-project=$GOOGLE_CLOUD_PROJECT \
  --subnet=mysubnet


# create NAT

gcloud compute routers create myrouter \
  --network=default \
  --region=$LOCATION

gcloud compute addresses create myoriginip --region=$LOCATION

gcloud compute routers nats create mynat \
  --router=myrouter \
  --region=$LOCATION \
  --nat-custom-subnet-ip-ranges=mysubnet \
  --nat-external-ip-pool=myoriginip


gcloud run deploy sample-go \
   --image=gcr.io/$GOOGLE_CLOUD_PROJECT/sample-go \
   --vpc-connector=myconnector \
   --vpc-egress=all-traffic

   

