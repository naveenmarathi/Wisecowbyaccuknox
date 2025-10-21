#!/bin/bash

# URL of the application
URL="https://accuknox.com"  

# Send request and get HTTP status code
STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" "$URL")

echo "Checking application: $URL"
echo "Status Code: $STATUS"

# Check if status is 200 (OK)
if [ "$STATUS" -eq 200 ]; then
    echo "✅ Application is UP"
else
    echo "❌ Application is DOWN"
fi
