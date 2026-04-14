FROM node:20-alpine

# Install unzip utility
RUN apk add --no-cache unzip

WORKDIR /app

# Copy both ZIP archives into the image
COPY ["files.zip", "files (1).zip", "./"]

# Extract every ZIP file into the working directory, then remove the archives
RUN for z in *.zip; do \
      echo "Extracting $z …"; \
      unzip -o "$z" -d . || true; \
    done \
 && rm -f *.zip

# Make the startup script executable
RUN chmod +x startup.sh

EXPOSE 3000

# Use startup.sh as the container entry point
CMD ["sh", "startup.sh"]
