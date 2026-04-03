FROM python:3.11-slim

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

COPY cloud_run/dbt/requirements.txt ./cloud_run/dbt/requirements.txt
RUN pip install --no-cache-dir -r cloud_run/dbt/requirements.txt

COPY dbt /app/dbt

RUN mkdir -p /root/.dbt \
  && cp /app/dbt/profiles.yml /root/.dbt/profiles.yml

WORKDIR /app/dbt

RUN GCP_PROJECT_ID=placeholder-project \
  GCP_REGION=placeholder-region \
  RAW_DATASET_ID=placeholder-raw \
  STG_DATASET_ID=placeholder-stg \
  INT_DATASET_ID=placeholder-int \
  MART_DATASET_ID=placeholder-mart \
  dbt deps --target prod

ENTRYPOINT ["dbt"]
