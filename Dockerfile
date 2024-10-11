# Stage 1: Build the React app
FROM node:16-alpine AS build

# Set working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies (with production optimizations)
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the React app for production
CMD ["npm", "start"]
