# API Keys Management Tools

This collection of Ruby scripts provides a comprehensive solution for exporting API keys from AWS API Gateway, converting them to a CSV format, and preparing them for re-importation using AWS CLI. Ideal for simplifying API key migrations and backups with advanced features like error handling and usage plan ID mapping.

## Tools Included

1. **export_api_keys.rb**: Exports API keys from AWS API Gateway to a JSON file.
2. **convert_api_keys_to_csv.rb**: Converts the JSON file of API keys into a CSV format suitable for import.

## Setup

Ensure you have Ruby and the necessary gems installed. You can install the required gems with:

```bash
gem install aws-sdk-apigateway
```

## Usage

### Export API Keys

Navigate to the directory containing `export_api_keys.rb` and execute the script with the options:

```bash
ruby export_api_keys.rb --region <YourAWSRegion> --wait-time <WaitTimeInSeconds>
```
- **--region**: Specifies the AWS region from which to export API keys.

- **--wait-time**: (optional) Defines how long the script should wait (in seconds) if it hits the rate limit.

### Convert API Keys to CSV

After exporting API keys to JSON, convert them to CSV format with `convert_api_keys_to_csv.rb`:

```bash
ruby convert_api_keys_to_csv.rb --region <YourAWSRegion> --file <PathToJsonFile>
```
- **--region**: Specifies the AWS region from which to export API keys.

- **--file**: The path to the JSON file containing exported API keys.

### Import API Keys Using AWS CLI

With the generated CSV file, use the AWS CLI to import the API keys back into AWS API Gateway:

```bash
aws apigateway import-api-keys --body 'file://<PathToCsvFile>' --format csv
```
