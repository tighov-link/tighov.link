import json
import os

domain_name = os.environ['DOMAIN_NAME']

def lambda_handler(event, context):
    print("Received event:", json.dumps(event, indent=2))
    # Get the Origin header from the request
    headers_dict = {k.lower(): v for k, v in event.get('headers', {}).items()}
    origin = headers_dict.get('origin')
    if origin and origin.endswith('/'):
        origin = origin.rstrip('/')
    allowed_origins = ["https://www." + domain_name, "https://" + domain_name]

    # Dynamically set CORS origin if allowed
    if origin in allowed_origins:
        cors_origin = origin
    else:
        cors_origin = "https://www." + domain_name  # fallback or set to None

    headers = {
        "Access-Control-Allow-Origin": cors_origin,
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
    }

    return {
        "statusCode": 200,
        "headers": headers,
        "body": json.dumps({"message": "CORS preflight OK"})
    }