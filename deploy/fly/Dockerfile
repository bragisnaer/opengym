# openGym for Fly.io, built from this repository. One machine runs nginx (the built
# frontend, proxying /api) and the Node API together, so passkeys keep a single origin.
# Build context is the repository root.

FROM --platform=$BUILDPLATFORM node:22-alpine AS webbuild
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci --ignore-scripts
COPY api/coach/core/ /app/api/coach/core/
COPY frontend/ ./
ARG APP_BUILD=""
RUN APP_BUILD="$APP_BUILD" npm run build

FROM node:22-alpine AS apibuild
WORKDIR /app
COPY api/package.json api/package-lock.json* ./
RUN npm ci --omit=dev --omit=optional && npm cache clean --force
COPY api/server.js api/push-messages.js api/verify-error.js api/password.js api/rate-limit.js api/passkeys-store.js api/device-link.js api/media.js ./
COPY api/coach ./coach

FROM alpine/git AS media
RUN git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset /ds \
 && mkdir -p /out/img /out/gif \
 && cp /ds/images/*.jpg /out/img/ \
 && cp /ds/videos/*.gif /out/gif/

FROM nginx:alpine
RUN apk add --no-cache nodejs
COPY web/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=webbuild /app/frontend/dist /usr/share/nginx/html
COPY --from=apibuild /app /app
COPY --from=media /out/img /usr/share/nginx/html/img
COPY --from=media /out/gif /usr/share/nginx/html/gif
COPY deploy/fly/start.sh /start.sh
RUN chmod +x /start.sh
ENV NGINX_PORT=8080 \
    BACKEND=127.0.0.1 \
    PORT=3000 \
    RESOLVER=127.0.0.1 \
    CF_CONNECTING_IP="" \
    BASE_PATH="" \
    MEDIA_UPLOAD_MAX=48m \
    DATA_DIR=/data \
    NODE_ENV=production \
    TRUST_PROXY=1
CMD ["/start.sh"]