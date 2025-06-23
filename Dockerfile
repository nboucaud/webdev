FROM oven/bun:alpine AS installer

WORKDIR /app

# Set memory constraints
ENV NODE_OPTIONS="--max-old-space-size=1536 --max-semi-space-size=128"
ENV BUN_INSTALL_CACHE_DIR=/tmp/bun-cache

# Copy root package files
COPY package.json bun.lock ./

# Copy all package.json files first for better caching
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

# Install dependencies with memory limits
RUN bun install

FROM oven/bun:alpine AS builder

WORKDIR /app

# Copy dependencies from installer
COPY --from=installer /app/node_modules ./node_modules
COPY --from=installer /app/package.json ./package.json

# Copy source code
COPY apps/web ./apps/web
COPY packages ./packages
COPY tooling ./tooling
COPY assets ./assets

# Set memory constraints for build
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Build the client with memory constraints
WORKDIR /app/apps/web/client
RUN bun run build

# Production stage
FROM oven/bun:alpine AS runner

WORKDIR /app

# Copy the entire built application
COPY --from=builder /app ./

# Ensure static files are properly accessible
RUN mkdir -p /app/apps/web/client/.next/static && \
    chown -R bun:bun /app/apps/web/client/.next

# Set runtime environment
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app/apps/web/client

EXPOSE 3000

CMD ["bun", "run", "start"]