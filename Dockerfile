# Use Node.js base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Expose port 3000
EXPOSE 3000

# Install Docker CLI inside the container
RUN apt-get update && apt-get install -y docker.io

# Run as root (no user switching needed)
CMD ["npm", "run", "dev"]
