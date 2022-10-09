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




# create Cloud SQL Instance
DB_PWD=secretpassword

gcloud sql instances create poll-database \
  --database-version=POSTGRES_13  \
  --cpu=2  \
  --memory=8GiB \
  --region=us-central1  \
  --root-password=${DB_PWD}


# Create DB
# SQL handling - not SH

gcloud sql connect poll-database --user=postgres

# \connect postgres;

psql -u "postgres" -p $DB_PWD "postgres" <<EOF

CREATE TABLE IF NOT EXISTS votes
( vote_id SERIAL NOT NULL, time_cast timestamp NOT NULL,
candidate VARCHAR(6) NOT NULL, PRIMARY KEY (vote_id) );

INSERT INTO totals (candidate, num_votes) VALUES ('TABS', 0);

INSERT INTO totals (candidate, num_votes) VALUES ('SPACES', 0);
EOF



CLOUD_SQL_CONNECTION_NAME=$(gcloud sql instances describe poll-database --format='value(connectionName)')

gcloud beta run deploy poll-service \
   --image gcr.io/qwiklabs-resources/gsp737-tabspaces \
   --region $LOCATION \
   --allow-unauthenticated \
   --add-cloudsql-instances=$CLOUD_SQL_CONNECTION_NAME \
   --set-env-vars "DB_USER=postgres" \
   --set-env-vars "DB_PASS=secretpassword" \
   --set-env-vars "DB_NAME=postgres" \
   --set-env-vars "CLOUD_SQL_CONNECTION_NAME=$CLOUD_SQL_CONNECTION_NAME"

POLL_APP_URL=$(gcloud run services describe poll-service --platform managed --region us-central1 --format="value(status.address.url)")


echo "check the Cloud Run services"




