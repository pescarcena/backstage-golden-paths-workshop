FROM node:${{ values.nodeVersion }}-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:${{ values.nodeVersion }}-alpine

# Crear usuario no-root por seguridad
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Cambiar a usuario no-root
USER nodejs

EXPOSE ${{ values.port }}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${{ values.port }}/health || exit 1

CMD ["node", "src/index.js"]
