FROM node:24-alpine AS build
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:24-alpine
WORKDIR /app
ENV NODE_ENV=production
# ponytail: ships full node_modules (vite is needed at runtime for `vite preview`); prune if image size matters
COPY --chown=node:node --from=build /app/package.json /app/vite.config.ts ./
COPY --chown=node:node --from=build /app/node_modules ./node_modules
COPY --chown=node:node --from=build /app/dist ./dist
# Numeric, so Kubernetes runAsNonRoot can verify it (the image's `node` user is 1000).
USER 1000:1000
EXPOSE 3000
CMD ["node_modules/.bin/vite", "preview", "--host", "0.0.0.0", "--port", "3000", "--strictPort"]
