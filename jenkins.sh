#!/bin/bash

# Configuration
CONTAINER_NAME="jenkins-server"
IMAGE="jenkins/jenkins:lts"
VOLUME_NAME="jenkins_home"
PORT_MAPPING="8090:8080"
BACKUP_DIR="$HOME/jenkins_backups"
DATE=$(date +%Y-%m-%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "--- Starting Jenkins Update Process ---"

# 1. Pull the new image first (minimizes downtime)
echo "Step 1: Pulling latest image ($IMAGE)..."
docker pull $IMAGE

# 2. Check for volume and Backup data
echo "Step 2: Checking for existing data..."

# Check if the volume actually exists in Docker
if docker volume inspect "$VOLUME_NAME" > /dev/null 2>&1; then
    VOL_PATH=$(docker volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')
    echo "Existing volume found at $VOL_PATH. Starting backup..."

    # Calculate total size for the progress bar
    SIZE=$(sudo du -sb "$VOL_PATH" | awk '{print $1}')

    # Run tar through pv for progress
    sudo tar -cf - -C "$VOL_PATH" . | pv -p -t -e -r -s $SIZE | gzip > "$BACKUP_DIR/jenkins_backup_$DATE.tar.gz"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "Backup successful: $BACKUP_DIR/jenkins_backup_$DATE.tar.gz"
    else
        echo "Backup FAILED!"
        exit 1
    fi
else
    echo "No existing volume '$VOLUME_NAME' found. Skipping backup for first-time setup..."
    echo "Creating fresh volume..."
    docker volume create "$VOLUME_NAME"
fi


# 3. Stop and Remove old container (if it exists)
echo "Step 3: Cleaning up container..."

if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Found existing container: $CONTAINER_NAME. Stopping and removing..."
    docker stop $CONTAINER_NAME >/dev/null
    docker rm $CONTAINER_NAME >/dev/null
else
    echo "No existing container named '$CONTAINER_NAME' found. Ready for fresh install."
fi

# 4. Run the new container
echo "Step 4: Starting new Jenkins container..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $PORT_MAPPING -p 50000:50000 \
  -v $VOLUME_NAME:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \  # mount the docker socket
  -v /usr/bin/docker:/usr/bin/docker \  # mount the docker binary
  -v /usr/libexec/docker/cli-plugins:/usr/lib/docker/cli-plugins \  # mount the docker cli plugins
  --restart=on-failure \
  $IMAGE


echo "--- Update Complete! ---"
echo "Check logs with: docker logs -f $CONTAINER_NAME"
