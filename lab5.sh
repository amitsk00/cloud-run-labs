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
gcloud config set run/region us-central1
LOCATION="us-central1"

mkdir helloworld && cd helloworld

cat > ./main.py <<EOF
import os
from flask import Flask
app = Flask(__name__)
@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    return "Hello {}!".format(name)
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

cat > ./Dockerfile <<EOF
# Use the official lightweight Python image.
# https://hub.docker.com/_/python
FROM python:3.9-slim
# Allow statements and log messages to immediately appear in the Knative logs
    ENV PYTHONUNBUFFERED True
# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./
# Install production dependencies.
RUN pip install Flask gunicorn
# Run the web service on container startup. Here we use the gunicorn
# webserver, with one worker process and 8 threads.
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
# Timeout is set to 0 to disable the timeouts of the workers to allow Cloud Run to handle instance scaling.
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
EOF

gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/helloworld

# Deploy to Run
gcloud run deploy --image gcr.io/$GOOGLE_CLOUD_PROJECT/helloworld

# Reserve an IP

gcloud compute addresses create example-ip \
    --ip-version=IPV4 \
    --global

gcloud compute addresses describe example-ip \
    --format="get(address)" \
    --global

IP_ADDR = $(gcloud compute addresses describe example-ip --format="get(address)" --global)
echo "IP for HTTPS Load Balancer is : ${IP_ADDR} "

# create LB

gcloud compute network-endpoint-groups create myneg \
   --region=$LOCATION \
   --network-endpoint-type=serverless  \
   --cloud-run-service=helloworld

gcloud compute backend-services create mybackendservice \
    --global

gcloud compute backend-services add-backend mybackendservice \
    --global \
    --network-endpoint-group=myneg \
    --network-endpoint-group-region=$LOCATION

gcloud compute url-maps create myurlmap \
    --default-service mybackendservice

gcloud compute target-http-proxies create mytargetproxy \
    --url-map=myurlmap

gcloud compute forwarding-rules create myforwardingrule \
    --address=example-ip \
    --target-http-proxy=mytargetproxy \
    --global \
    --ports=80

echo "check if LB is fine with below link"                       
echo "http://${IP_ADDR}"
