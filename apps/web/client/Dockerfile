FROM oven/bun:alpine
WORKDIR /app
COPY apps/web/client/package.json ./apps/web/client/package.json
COPY apps/web/server/package.json ./apps/web/server/package.json

COPY packages/db/package.json ./packages/db/package.json
COPY docs/package.json ./docs/package.json
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
COPY apps/web/client/ ./apps/web/client/
COPY apps/web/server/ ./apps/web/server/
COPY packages/ ./packages/
COPY tooling/ ./tooling/
WORKDIR /app/apps/web/client
EXPOSE 3000
RUN bun run build
CMD ["bun", "run", "start"] 