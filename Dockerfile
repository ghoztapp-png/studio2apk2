# ── Stage 1: extract & build ──────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Install unzip utility
RUN apk add --no-cache unzip

WORKDIR /app

# Copy all ZIP archives into the image
COPY ["files.zip", "files (1).zip", "./"]

# Extract every ZIP file into the working directory.
# The `|| true` guard keeps the build going even if a ZIP has no new files.
RUN for z in *.zip; do \
      echo "Extracting $z …"; \
      unzip -o "$z" -d . || true; \
    done \
 && rm -f *.zip

# Install dependencies (package.json must be present after extraction)
RUN npm install

# Build the TypeScript application
RUN npm run build

# ── Stage 2: production image ─────────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

# Copy only what is needed to run the app
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

EXPOSE 3000

# Prefer the "start" script defined in package.json; fall back to dist/index.js
CMD ["sh", "-c", "npm run start 2>/dev/null || node dist/index.js"]
