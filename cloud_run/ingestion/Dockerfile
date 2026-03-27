FROM python:3.11-slim

WORKDIR /app

COPY cloud_run/ingestion/requirements.txt ./cloud_run/ingestion/requirements.txt
RUN pip install --no-cache-dir -r cloud_run/ingestion/requirements.txt

COPY cloud_run /app/cloud_run

CMD ["python", "-m", "cloud_run.ingestion.app.main"]
