# 🚀 CI/CD Pipeline with GitHub Actions, Amazon ECS (EC2), and AWS ECR

This guide documents the complete step-by-step process to set up a **CI/CD pipeline** for deploying a **Next.js application** to **Amazon ECS (EC2) with AWS ECR** using **GitHub Actions**.

---

## **📌 Overview**
- **CI/CD Tool**: GitHub Actions
- **Containerization**: Docker
- **Container Registry**: Amazon Elastic Container Registry (ECR)
- **Orchestration**: Amazon Elastic Container Service (ECS) with EC2 launch type
- **Compute Instance**: Amazon EC2 (Free Tier compatible)

---

## **1️⃣ Setup AWS Services**
### **1.1 Create an Amazon ECS Cluster**
1. **Go to AWS ECS Console**: [AWS ECS](https://console.aws.amazon.com/ecs/)
2. Click **Clusters** → **Create Cluster**
3. **Choose EC2 Linux + Networking**
4. **Cluster name**: `nextjs-ec2-cluster`
5. **Instance type**: `t2.micro` (for Free Tier compatibility)
6. **Number of instances**: `1`
7. **Create the cluster**

### **1.2 Register EC2 Instance with ECS**
1. **Go to AWS EC2 Console**: [AWS EC2](https://console.aws.amazon.com/ec2/)
2. Select your **EC2 instance** → Click **Actions** → **Security** → **Modify IAM Role**
3. **Attach an IAM Role** with the policy `AmazonEC2ContainerServiceforEC2Role`.
4. **SSH into your EC2 instance**:
   ```sh
   ssh -i your-key.pem ec2-user@your-ec2-public-ip
   ```
5. **Install ECS Agent**:
   ```sh
   sudo yum update -y
   sudo yum install -y ecs-init
   sudo systemctl enable --now ecs
   ```
6. **Configure the ECS Cluster on EC2**:
   ```sh
   echo "ECS_CLUSTER=nextjs-ec2-cluster" | sudo tee -a /etc/ecs/ecs.config
   sudo systemctl restart ecs
   ```
7. Verify the instance is **registered in ECS**: Check the **ECS Console** → **Clusters**.

---

## **2️⃣ Setup Amazon ECR**
### **2.1 Create an Amazon ECR Repository**
1. **Go to AWS ECR Console**: [AWS ECR](https://console.aws.amazon.com/ecr/)
2. Click **Create Repository**
3. **Repository name**: `nextjs-app`
4. **Set Image Tag Mutability**: Mutable
5. **Enable Scan on Push** (Optional)
6. Click **Create Repository**

### **2.2 Authenticate Docker with ECR**
1. **Login to AWS ECR**:
   ```sh
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com
   ```
2. **Build and Push Docker Image**:
   ```sh
   docker build -t nextjs-app .
   docker tag nextjs-app:latest <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/nextjs-app:latest
   docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/nextjs-app:latest
   ```

---

## **3️⃣ Setup ECS Task Definition**
1. **Go to AWS ECS Console** → Click **Task Definitions** → **Create new task definition**
2. **Launch Type**: EC2
3. **Task Definition Name**: `cicd-nextjs-task`
4. **Container Definitions**:
   - **Container Name**: `nextjs-container`
   - **Image URI**: `<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/nextjs-app:latest`
   - **Port Mappings**: `Host Port = 0`, `Container Port = 3000`
   - **Memory**: `256` (MB)
   - **CPU**: `256` (0.25 vCPU)
5. **Create Task Definition**

---

## **4️⃣ Setup GitHub Actions CI/CD Pipeline**
### **4.1 Store AWS Credentials as GitHub Secrets**
1. **Go to GitHub Repository** → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** for each of the following:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` → `us-east-1`
   - `ECR_REPOSITORY_URI` → `<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/nextjs-app`
   - `ECS_CLUSTER` → `nextjs-ec2-cluster`
   - `ECS_SERVICE` → `cicd-nextjs-service`

### **4.2 Create `.github/workflows/deploy.yml`**
```yaml
name: Deploy to AWS ECS (EC2)

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI

      - name: Build and Push Docker Image
        run: |
          docker build -t nextjs-app .
          docker tag nextjs-app:latest $ECR_REPOSITORY_URI:latest
          docker push $ECR_REPOSITORY_URI:latest

      - name: Deploy to Amazon ECS
        run: |
          aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE \
          --desired-count 1 --force-new-deployment \
          --deployment-configuration "minimumHealthyPercent=0,maximumPercent=100"
```

---

## **5️⃣ Debugging Common Errors**
### **🚨 Deployment Fails Due to Port Conflict**
✔ **Fix:** Ensure `Minimum Healthy Percent = 0` in ECS Service settings.

### **🚨 Task Fails to Start Due to Insufficient CPU**
✔ **Fix:** Reduce task CPU allocation in Task Definition (Set `256` instead of `512`).

### **🚨 ECS Keeps Restarting Old Tasks**
✔ **Fix:** Manually stop tasks or set `desired-count=0` before deploying.

---

## **🎉 Conclusion**
This setup **automates deployments** using **GitHub Actions** and **AWS ECS**, ensuring a **fully functional CI/CD pipeline**. 🚀

