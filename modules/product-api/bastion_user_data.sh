#!/bin/bash
yum update -y
yum install -y aws-cli jq

cat > /home/ec2-user/fetch-products.sh <<'SCRIPT'
BUCKET_NAME="${s3_bucket_name}"
REGION="${aws_region}"

echo "=========================================="
echo "Product Data Fetcher"
echo "=========================================="
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

show_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -l, --list          List all files in bucket"
    echo "  -d, --download      Download all product files"
    echo "  -s, --summary       Show summary statistics"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --list
    echo "  $0 --download
    echo "  $0 --summary
}

ACTION="download"
if [ "$1" = "--list" ] || [ "$1" = "-l" ]; then
    ACTION="list"
elif [ "$1" = "--download" ] || [ "$1" = "-d" ]; then
    ACTION="download"
elif [ "$1" = "--summary" ] || [ "$1" = "-s" ]; then
    ACTION="summary"
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_usage
    exit 0
fi

if [ "$ACTION" = "list" ] || [ "$ACTION" = "download" ] || [ "$ACTION" = "summary" ]; then
    echo "Listing files in bucket..."
    aws s3 ls s3://$BUCKET_NAME/ --region $REGION | grep "data_" || echo "No product files found"
    echo ""
fi

if [ "$ACTION" = "list" ]; then
    exit 0
fi

FILES=$(aws s3 ls s3://$BUCKET_NAME/ --region $REGION | grep "data_" | awk '{print $4}')

if [ -z "$FILES" ]; then
    echo "No product data files found in bucket."
    exit 0
fi

mkdir -p /home/ec2-user/products

FILE_COUNT=$(echo "$FILES" | wc -l)
echo "Found $FILE_COUNT product file(s)"
echo ""

if [ "$ACTION" = "summary" ]; then
    TOTAL_SIZE=0
    for FILE in $FILES; do
        SIZE=$(aws s3 ls s3://$BUCKET_NAME/$FILE --region $REGION | awk '{print $3}')
        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    done
    echo "Summary:"
    echo "  Files: $FILE_COUNT"
    echo "  Total size: $TOTAL_SIZE bytes"
    echo "  Latest file: $(echo "$FILES" | head -n1)"
    exit 0
fi

PRODUCT_COUNT=0
for FILE in $FILES; do
    echo "Processing: $FILE"
    aws s3 cp s3://$BUCKET_NAME/$FILE /home/ec2-user/products/$FILE --region $REGION -q
    
    if [ $? -eq 0 ]; then
        COUNT=$(cat /home/ec2-user/products/$FILE | jq '.sample_data | length' 2>/dev/null || echo "0")
        PRODUCT_COUNT=$((PRODUCT_COUNT + COUNT))
        echo "  ✓ Downloaded ($COUNT products)"
    else
        echo "  ✗ Failed to download"
    fi
done

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Files downloaded: $FILE_COUNT"
echo "Total products: $PRODUCT_COUNT"
echo "Location: /home/ec2-user/products/"
echo ""
echo "View a file:"
echo "  cat /home/ec2-user/products/<filename> | jq ."
echo ""
echo "List all files:"
echo "  ls -lh /home/ec2-user/products/"
SCRIPT

chmod +x /home/ec2-user/fetch-products.sh
chown ec2-user:ec2-user /home/ec2-user/fetch-products.sh

cat > /home/ec2-user/README.md <<'README'

This bastion host provides secure access to product data stored in S3.


The S3 bucket is configured to only allow access from:
- This bastion host
- EKS cluster nodes


Run the script with options:

```bash
/home/ec2-user/fetch-products.sh --help

/home/ec2-user/fetch-products.sh --list

/home/ec2-user/fetch-products.sh --download

/home/ec2-user/fetch-products.sh --summary
```


You can also use AWS CLI directly:

```bash
aws s3 ls s3://${s3_bucket_name}/

aws s3 cp s3://${s3_bucket_name}/data_20240101_120000.json /tmp/

aws s3 cp s3://${s3_bucket_name}/data_20240101_120000.json - | jq .
```


- The S3 bucket has a restrictive bucket policy
- Only this bastion host and EKS nodes can access the bucket
- All access is logged via CloudTrail
README

chown ec2-user:ec2-user /home/ec2-user/README.md

echo "=========================================="
echo "Bastion host setup complete!"
echo "=========================================="
echo "S3 bucket: ${s3_bucket_name}"
echo "Region: ${aws_region}"
echo ""
echo "To fetch product data, run:"
echo "  /home/ec2-user/fetch-products.sh --help"
echo ""
echo "Documentation: /home/ec2-user/README.md"