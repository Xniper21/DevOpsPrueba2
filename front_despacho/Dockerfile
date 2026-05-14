# Stage 1: Build
FROM node:20-alpine AS build

WORKDIR /app

# Build arguments for API endpoints
ARG VITE_API_URL_VENTAS
ARG VITE_API_URL_DESPACHOS

ENV VITE_API_URL_VENTAS=${VITE_API_URL_VENTAS}
ENV VITE_API_URL_DESPACHOS=${VITE_API_URL_DESPACHOS}

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --silent

# Copy source code
COPY . .

# Build optimized production bundle
RUN npm run build

# Stage 2: Production
FROM nginx:stable-alpine

# Add non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy optimized Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /usr/share/nginx/html

# Copy built application from builder stage
COPY --from=build /app/dist /usr/share/nginx/html

# Set proper permissions
RUN chown -R appuser:appgroup /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Run as non-root user
USER appuser

EXPOSE 80

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
