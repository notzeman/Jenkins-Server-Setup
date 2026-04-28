# Jenkins Docker Setup & Update Tool

A robust Bash script designed to automate the lifecycle of a Jenkins server running in Docker. This script handles backups with progress bars, image updates, persistence, and Docker-out-of-Docker (DooD) capabilities.

## Features

- **Zero-Config Update**: Automatically detects if it's an update or a fresh install.
- **Docker-in-Jenkins**: Mounts the host Docker socket, binary, and CLI plugins (Buildx) so Jenkins can run Docker commands.
- **Persistence**: Uses Docker named volumes to ensure your jobs and settings survive container removals.
- **Downtime Minimization**: Pulls the new image before stopping the old container.

## Prerequisites

The script requires a few tools to be installed on your Linux host:

```bash
sudo apt update
sudo apt install pv gzip tar docker.io -y
```

## How to Use

1. Download/Create the script:

   ```bash
   nano update_jenkins.sh
   ```

2. Paste the script content and save.

3. Make it executable:

   ```bash
   chmod +x update_jenkins.sh
   ```

4. Run it:

   ```bash
   ./update_jenkins.sh
   ```

## Configuration

You can modify the variables at the top of the script to match your environment:

- **PORT_MAPPING**: Currently set to `8090:8080`.
- **VOLUME_NAME**: The Docker volume where Jenkins data is stored (`jenkins_home`).
- **BACKUP_DIR**: Where the jenkins backups are saved.

## Important Notes 

- **Permissions**: The script uses `sudo` for the backup step to access protected Docker volume files. Ensure your user has sudo privileges.
- **Docker Socket**: If you get a "Permission Denied" when running Docker commands inside Jenkins, run `sudo chmod 666 /var/run/docker.sock` on your host. **important**
- **First-Time Install**: If this is a brand new setup, run `docker logs jenkins-server` after the script finishes to retrieve your Initial Admin Password.

## File Structure

- **Data**: `/var/lib/docker/volumes/jenkins_home/_data`
- **Backups**: `~/jenkins_backups/jenkins_backup_YYYY-MM-DD_HHMMSS.tar.gz`
