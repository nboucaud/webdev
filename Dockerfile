FROM oven/bun:alpine AS builder

WORKDIR /app

# Install npm (needed for Next.js)
RUN apk add --no-cache npm

# Copy package.json files first for better caching
COPY package.json bun.lock ./
COPY apps/web/client/package.json ./apps/web/client/package.json
COPY apps/web/server/package.json ./apps/web/server/package.json
COPY packages/ai/package.json ./packages/ai/package.json
COPY packages/constants/package.json ./packages/constants/package.json
COPY packages/db/package.json ./packages/db/package.json
COPY packages/email/package.json ./packages/email/package.json
COPY packages/fonts/package.json ./packages/fonts/package.json
COPY packages/git/package.json ./packages/git/package.json
COPY packages/growth/package.json ./packages/growth/package.json
COPY packages/mastra/package.json ./packages/mastra/package.json
COPY packages/models/package.json ./packages/models/package.json
COPY packages/parser/package.json ./packages/parser/package.json
COPY packages/penpal/package.json ./packages/penpal/package.json
COPY packages/rpc/package.json ./packages/rpc/package.json
COPY packages/scripts/package.json ./packages/scripts/package.json
COPY packages/stripe/package.json ./packages/stripe/package.json
COPY packages/types/package.json ./packages/types/package.json
COPY packages/ui/package.json ./packages/ui/package.json
COPY packages/utility/package.json ./packages/utility/package.json
COPY tooling/typescript/package.json ./tooling/typescript/package.json

# Install dependencies with optimized bun settings (this layer will be cached!)
RUN bun install --concurrent 10 --no-save

# Copy all source code (after dependencies are installed)
COPY . .

# Set working directory to client and build
WORKDIR /app/apps/web/client
RUN bun run build:fast

# Production stage with Node.js (reliable multi-arch)
FROM node:20-alpine

WORKDIR /app

# Copy built application and node_modules
COPY --from=builder /app/apps/web/client/.next ./.next
COPY --from=builder /app/apps/web/client/public ./public
COPY --from=builder /app/apps/web/client/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

# Copy .env file if it exists (optional, for development)
COPY --from=builder /app/apps/web/client/.env.production .env

# Runtime config
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Use Node.js instead of bun for runtime
CMD ["npm", "start"]
