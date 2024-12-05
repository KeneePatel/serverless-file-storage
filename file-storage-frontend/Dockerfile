# Use Node.js 22 as base image
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Enable pnpm through corepack
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy rest of the application code
COPY . .

# Build the Next.js application
RUN pnpm build

# Expose port 3000
EXPOSE 3000

# Start the application
CMD ["pnpm", "start"]
