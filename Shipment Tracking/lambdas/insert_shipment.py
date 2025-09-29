import json
import boto3
import os
from datetime import datetime
from decimal import Decimal
import uuid
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Attr

# Initialize DynamoDB table
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE', 'test-shipment-trips')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        body = parse_body(event)
        validation_result = validate_request(body)
        if not validation_result['valid']:
            return create_response(400, {'error': 'Validation failed', 'details': validation_result['errors']})

        shipment_id = body['shipmentId']
        timestamp = body['location']['timestamp']
        record_id = str(uuid.uuid4())

        item = {
            'shipmentId': shipment_id,
            'timestamp': timestamp,
            'recordId': record_id,
            'orderId': body['orderId'],
            'logisticId': body['logisticId'],
            'plateNumber': body['plateNumber'],
            'latitude': Decimal(str(body['location']['latitude'])),
            'longitude': Decimal(str(body['location']['longitude'])),
            'speedKmh': Decimal(str(body['location']['speedKmh'])),
            'heading': Decimal(str(body['location']['heading'])),
            'createdAt': datetime.utcnow().isoformat() + 'Z',
            'isFirstLocation': True
        }

        try:
            table.put_item(
                Item=item,
                ConditionExpression='attribute_not_exists(shipmentId) AND attribute_not_exists(timestamp)'
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                existing = table.get_item(Key={'shipmentId': shipment_id, 'timestamp': timestamp}).get('Item', {})
                item['isFirstLocation'] = False
                return create_response(409, {
                    'error': 'Duplicate location update',
                    'message': 'Location already exists for this shipment and timestamp',
                    'existingRecordId': existing.get('recordId', 'unknown')
                })
            else:
                raise

        return create_response(201, {
            'message': "Location added successfully",
            'recordId': record_id,
            'isNewShipment': item['isFirstLocation']
        })

    except json.JSONDecodeError as e:
        return create_response(400, {'error': 'Invalid JSON', 'details': str(e)})
    except ClientError as e:
        return create_response(500, {'error': 'Database failed', 'details': str(e)})
    except Exception as e:
        return create_response(500, {'error': 'Internal server error', 'details': str(e)})

def parse_body(event):
    if 'body' in event:
        if event['body']:
            return json.loads(event['body']) if isinstance(event['body'], str) else event['body']
        raise ValueError("No body provided")
    return event

def validate_request(body):
    errors = []
    required_fields = ['orderId', 'logisticId', 'shipmentId', 'plateNumber', 'location']
    for field in required_fields:
        if not body.get(field):
            errors.append(f"Missing required field: {field}")

    loc = body.get('location')
    if loc:
        for field in ['latitude', 'longitude', 'timestamp', 'speedKmh', 'heading']:
            if loc.get(field) is None:
                errors.append(f"Missing location field: {field}")
        try:
            if not -90 <= float(loc['latitude']) <= 90:
                errors.append("Latitude must be -90 to 90")
            if not -180 <= float(loc['longitude']) <= 180:
                errors.append("Longitude must be -180 to 180")
            if float(loc['speedKmh']) < 0:
                errors.append("Speed cannot be negative")
            if not 0 <= float(loc['heading']) < 360:
                errors.append("Heading must be 0 to 359")
            datetime.fromisoformat(loc['timestamp'].replace('Z', '+00:00'))
        except (ValueError, TypeError) as e:
            errors.append(f"Invalid location value: {str(e)}")
    else:
        errors.append("Missing location object")
    return {'valid': len(errors) == 0, 'errors': errors}

def create_response(status, body):
    return {
        'statusCode': status,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(body)
    }