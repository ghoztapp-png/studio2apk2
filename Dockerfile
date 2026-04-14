FROM node:20-alpine

# Install unzip utility
RUN apk add --no-cache unzip

WORKDIR /app

# Copy ZIP archives into the image
COPY ["files.zip", "files (1).zip", "./"]

# Extract both ZIP files
RUN for z in *.zip; do \
      echo "Extracting $z ..."; \
      unzip -o "$z" -d . || true; \
    done \
 && rm -f *.zip

# Make startup script executable
RUN chmod +x startup.sh

CMD ["sh", "startup.sh"]
