# 1. Build Stage
FROM oven/bun:alpine AS builder
WORKDIR /app

COPY package.json bun.lock ./
COPY apps/web/client/package.json ./apps/web/client/
COPY apps/web/server/package.json ./apps/web/server/
COPY packages/db/package.json ./packages/db/package.json
COPY packages/constants/package.json ./packages/constants/package.json
COPY packages/email/package.json ./packages/email/package.json
COPY packages/utility/package.json ./packages/utility/package.json
COPY packages/growth/package.json ./packages/growth/package.json
COPY packages/models/package.json ./packages/models/package.json
COPY packages/parser/package.json ./packages/parser/package.json
COPY packages/penpal/package.json ./packages/penpal/package.json
COPY packages/rpc/package.json ./packages/rpc/package.json
COPY packages/stripe/package.json ./packages/stripe/package.json
COPY packages/ui/package.json ./packages/ui/package.json
COPY packages/ai/package.json ./packages/ai/package.json
COPY packages/fonts/package.json ./packages/fonts/package.json
COPY tooling/typescript/package.json ./tooling/typescript/package.json
COPY package.json ./
COPY bun.lock ./

RUN bun install


COPY . .


WORKDIR /app/apps/web/client
ENV NODE_OPTIONS=--max-old-space-size=2048
ENV NEXT_BUILD_WORKERS=1
RUN bun run build


FROM oven/bun:alpine AS runner
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/apps/web/client/.next ./apps/web/client/.next
COPY --from=builder /app/apps/web/client/public ./apps/web/client/public
COPY --from=builder /app/apps/web/client/package.json ./apps/web/client/package.json

WORKDIR /app/apps/web/client
EXPOSE 3000


CMD ["bun", "run", "start"] 