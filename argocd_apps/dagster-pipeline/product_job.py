Simple Product Job - Dagster Pipeline
Fetches data from a free public API, processes it, and stores in S3

import os
import requests
from dagster import (
    asset,
    job,
    get_dagster_logger,
    run_status_sensor,
    RunStatusSensorContext,
    DagsterRunStatus,
    Definitions,
)
import boto3
import json
from datetime import datetime

logger = get_dagster_logger()

API_URL = "https://jsonplaceholder.typicode.com/posts"


@asset
def fetch_data():
    logger.info(f"Fetching data from {API_URL}...")
    
    try:
        response = requests.get(API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        logger.info(f"Successfully fetched {len(data)} items")
        return data
    except Exception as e:
        logger.error(f"Failed to fetch data: {e}")
        raise


@asset
def process_data(fetch_data):
    logger.info("Processing data...")
    
    count = len(fetch_data)
    avg_length = sum(len(item.get("title", "")) for item in fetch_data) / count if count > 0 else 0
    
    result = {
        "count": count,
        "average_title_length": round(avg_length, 2),
        "timestamp": datetime.now().isoformat(),
        "sample_data": fetch_data[:3] if count > 0 else []
    }
    
    logger.info(f"Processed {count} items. Average title length: {avg_length:.2f}")
    return result


@asset
def store_to_s3(process_data):
    s3_bucket_name = os.getenv("S3_BUCKET_NAME")
    aws_region = os.getenv("AWS_REGION", "eu-west-1")

    if not s3_bucket_name:
        raise ValueError("S3_BUCKET_NAME environment variable not set")

    logger.info(f"Storing data to S3 bucket: {s3_bucket_name}")

    try:
        s3_client = boto3.client("s3", region_name=aws_region)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_key = f"data_{timestamp}.json"

        s3_client.put_object(
            Bucket=s3_bucket_name,
            Key=file_key,
            Body=json.dumps(process_data, indent=2),
            ContentType="application/json",
        )

        logger.info(f"Successfully stored to s3://{s3_bucket_name}/{file_key}")
        return {"bucket": s3_bucket_name, "key": file_key, "status": "success"}
    except Exception as e:
        logger.error(f"Failed to store to S3: {e}")
        raise


@job
def product_pipeline_job():
    store_to_s3(process_data(fetch_data()))


@run_status_sensor(run_status=DagsterRunStatus.FAILURE)
def job_failure_sensor(context: RunStatusSensorContext):
    run = context.dagster_run
    dagster_ui_url = os.getenv("DAGSTER_UI_URL", "")
    
    message = {
        "text": f"🚨 Dagster Job Failed",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🚨 Dagster Job Failed"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Job Name:*\n{run.job_name}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Run ID:*\n`{run.run_id}`"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Timestamp:*\n{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
                    }
                ]
            }
        ]
    }
    
    if dagster_ui_url:
        message["blocks"].append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"<{dagster_ui_url}/runs/{run.run_id}|View Run in Dagster UI>"
            }
        })
    
    logger.error(f"Job failed: {run.job_name} (Run ID: {run.run_id})")
    
    webhook_url = os.getenv("ALERT_WEBHOOK_URL")
    if webhook_url:
        try:
            response = requests.post(webhook_url, json=message, timeout=5)
            response.raise_for_status()
            logger.info(f"Alert sent to Slack webhook successfully")
        except Exception as e:
            logger.error(f"Failed to send alert to Slack: {e}")


defs = Definitions(
    assets=[fetch_data, process_data, store_to_s3],
    jobs=[product_pipeline_job],
    sensors=[job_failure_sensor],
)

