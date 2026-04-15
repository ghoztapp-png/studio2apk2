FROM node:20-alpine

# Install unzip utility
RUN apk add --no-cache unzip

WORKDIR /app

# Copy package.json so npm install can read dependencies
COPY package.json ./

# Copy ZIP archives into the image
COPY ["files.zip", "files (1).zip", "./"]

# Extract both ZIP files
RUN for z in *.zip; do \
      echo "Extracting $z ..."; \
      unzip -o "$z" -d . || true; \
    done \
 && rm -f *.zip

# Move server.js into the /app/backend/ directory where startup.sh expects it
RUN mkdir -p /app/backend && mv /app/server.js /app/backend/server.js

# Fix frontend paths: index.html is at /app/index.html, not /app/frontend/index.html
RUN sed -i 's|../frontend/index\.html|../index.html|g' /app/backend/server.js \
 && sed -i 's|../frontend|..|g' /app/backend/server.js

# Copy the build-time patch script and inject the /health endpoint + safe root handler
COPY patch-server.js ./
RUN node patch-server.js

# Install npm dependencies from package.json
RUN npm install

CMD ["node", "backend/server.js"]
