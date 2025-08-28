#!/bin/bash
set -e

# -------- CONFIG --------
AWS_REGION="us-east-1"
ACCOUNT_ID="123456789012"       # Replace with your AWS account ID
REPO_NAME="myapp"
CLUSTER_NAME="myapp-cluster"
SERVICE_NAME="myapp-service"
IMAGE_TAG="latest"
DOCKERFILE_PATH="."             # Path to your Dockerfile

# Full ECR repository URL
ECR_URL="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME"

# -------- 1. Check & Create ECR Repository if not exists --------
echo "Checking if ECR repository exists..."
if ! aws ecr describe-repositories --repository-names $REPO_NAME --region $AWS_REGION >/dev/null 2>&1; then
    echo "ECR repository not found. Creating repository: $REPO_NAME"
    aws ecr create-repository --repository-name $REPO_NAME --region $AWS_REGION >/dev/null
    echo "Repository created."
else
    echo "ECR repository exists."
fi

# -------- 2. Authenticate Docker to ECR --------
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

# -------- 3. Build Docker image --------
echo "Building Docker image..."
docker build -t $REPO_NAME $DOCKERFILE_PATH

# -------- 4. Tag Docker image for ECR --------
echo "Tagging Docker image for ECR..."
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URL:$IMAGE_TAG

# -------- 5. Push Docker image to ECR --------
echo "Pushing Docker image to ECR..."
docker push $ECR_URL:$IMAGE_TAG

# -------- 6. Update ECS Service --------
echo "Updating ECS service to use the new image..."
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment \
  --region $AWS_REGION

echo "✅ Deployment complete! ECS service is now running the new image."




# chmod +x deploy.sh
# ./deploy.sh