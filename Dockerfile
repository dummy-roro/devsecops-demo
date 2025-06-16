# --- Stage 1: Build the Node.js application ---
# Use a specific and minimal Node.js image for building
FROM node:20-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker's caching.
# If these files don't change, the 'npm ci' step won't rerun.
COPY package*.json ./

# Install Node.js dependencies
# 'npm ci' is preferred over 'npm install' in CI/CD environments as it uses package-lock.json
RUN npm ci

# Copy the rest of the application source code
COPY . .

# Run the build command for your Node.js application
# This typically creates optimized static assets in a 'dist' or 'build' folder
RUN npm run build

# --- Stage 2: Serve the application with Nginx ---
# Use a specific and minimal Nginx image for production
FROM nginx:alpine

# Set the working directory for Nginx to serve files from
# This is typically where Nginx looks for HTML files
WORKDIR /usr/share/nginx/html

# Set the user to 'nginx' for security.
# The 'nginx:alpine' image already includes a non-root 'nginx' user.
# Running as non-root limits potential damage if the container is compromised.
USER nginx

# Copy the built static assets from the 'build' stage to the Nginx serving directory.
# Use --chown to ensure the copied files are owned by the 'nginx' user,
# preventing potential permission issues at runtime.
COPY --from=build --chown=nginx:nginx /app/dist /usr/share/nginx/html

# Optional: Add custom Nginx configuration if your application requires it.
# Uncomment and modify if you have a custom nginx.conf file.
# COPY --from=build --chown=nginx:nginx /app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose the port Nginx listens on (default HTTP port)
EXPOSE 80

# Define the command to run Nginx in the foreground.
# 'daemon off;' ensures Nginx runs in the foreground, essential for Docker containers.
CMD ["nginx", "-g", "daemon off;"]
