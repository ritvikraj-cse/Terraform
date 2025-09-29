import json
import boto3
import os
from botocore.exceptions import ClientError
from decimal import Decimal
from boto3.dynamodb.conditions import Key

# DynamoDB table
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'test-shipment-trips')
table = dynamodb.Table(table_name)

MAX_LOCATIONS = int(os.environ.get('MAX_LOCATIONS', 50))
MAX_LOCATIONS = max(1, min(MAX_LOCATIONS, 500))  # Between 1 and 500

def lambda_handler(event, context):
    path_params = event.get('pathParameters') or {}
    shipment_id = (path_params.get('shipmentId') or '').strip()

    if not shipment_id:
        return create_response(400, {
            'error': 'Missing shipmentId',
            'message': 'shipmentId is required in the URL path'
        })

    try:
        response = table.query(
            KeyConditionExpression=Key('shipmentId').eq(shipment_id),
            ScanIndexForward=False,
            Limit=MAX_LOCATIONS,
            ProjectionExpression="orderId, logisticId, plateNumber, timestamp, latitude, longitude, speedKmh, heading"
        )

        items = response.get('Items', [])
        if not items:
            return create_response(404, {
                'error': 'Shipment not found',
                'message': f'No locations found for shipmentId: {shipment_id}'
            })

        items.reverse()
        first_record = items[0]

        shipment_data = {
            'orderId': first_record.get('orderId', ''),
            'logisticId': first_record.get('logisticId', ''),
            'shipmentId': shipment_id,
            'plateNumber': first_record.get('plateNumber', ''),
            'locations': [
                {
                    'timestamp': safe_float(item.get('timestamp', 0)),
                    'latitude': safe_float(item.get('latitude', 0.0)),
                    'longitude': safe_float(item.get('longitude', 0.0)),
                    'speedKmh': safe_float(item.get('speedKmh', 0.0)),
                    'heading': safe_float(item.get('heading', 0.0))
                } for item in items
            ]
        }

        return create_response(200, shipment_data)

    except ClientError as e:
        return create_response(500, {
            'error': 'Database operation failed',
            'details': str(e)
        })
    except Exception as e:
        return create_response(500, {
            'error': 'Internal server error',
            'details': str(e)
        })

def safe_float(value):
    if isinstance(value, (Decimal, int, float)):
        return float(value)
    try:
        return float(value)
    except (TypeError, ValueError):
        return value

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body)
    }