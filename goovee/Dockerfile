FROM node:22-alpine AS goovee-base

FROM alpine/git:latest AS goovee-source

ARG GOOVEE_BRANCH=main

RUN git clone https://github.com/axelor/goovee.git -b ${GOOVEE_BRANCH} /goovee

# Install dependencies only when needed
FROM goovee-base AS goovee-deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Install dependencies based on the preferred package manager
COPY --from=goovee-source /goovee/package.json /goovee/yarn.lock* /goovee/package-lock.json* /goovee/pnpm-lock.yaml* /goovee/.npmrc* ./
RUN corepack enable pnpm && pnpm i --frozen-lockfile

# Rebuild the source code only when needed
FROM goovee-base AS goovee-builder
WORKDIR /app
COPY --from=goovee-deps /app/node_modules ./node_modules
COPY --from=goovee-source /goovee/ .

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1

RUN sed -i '/const nextConfig = {/a\  output: "standalone",' next.config.mjs && \
    corepack enable pnpm && pnpm generate && pnpm website:sass && pnpm build

# Production image, copy all the files and run next
FROM goovee-base AS runner
WORKDIR /app

ENV PGHOST=postgres
ENV PGPORT=5432
ENV PGUSER=axelor
ENV PGPASSWORD=axelor
ENV PGDATABASE=axelor

## Database ##
ENV DATABASE_URL=${DATABASE_URL:-postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}}
ENV DATA_STORAGE=/data/attachments
## Multi-Tenancy ##
ENV MULTI_TENANCY=false
## Translations ##
ENV INCLUDE_LANGUAGE=true
## Next ##
ENV GOOVEE_PUBLIC_HOST=http://localhost:3000
ENV GOOVEE_PUBLIC_AOS_URL=http://localhost:8080
# Next Auth
ENV NEXTAUTH_URL=http://localhost:3000
# Mattermost
ENV GOOVEE_PUBLIC_MATTERMOST_HOST=http://mattermost:8065
ENV GOOVEE_PUBLIC_MATTERMOST_WEBSOCKET_URL=ws://mattermost:8065/api/v4/websocket
# Social
ENV GOOVEE_PUBLIC_LINKEDIN_URL=https://www.linkedin.com
ENV GOOVEE_PUBLIC_TWITTER_URL=https://x.com
ENV GOOVEE_PUBLIC_INSTAGRAM_URL=https://www.instagram.com
ENV GOOVEE_PUBLIC_WHATSAPP_URL=https://web.whatsapp.com

ENV NODE_ENV=production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=goovee-builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=goovee-builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=goovee-builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]