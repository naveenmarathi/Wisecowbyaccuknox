#!/bin/bash

# Enhanced Automated Backup Solution
# Supports local, remote server, and cloud storage backups with detailed reporting

# Default configuration - modify as needed
SOURCE_DIR=""
BACKUP_TYPE="local"  # Options: "local", "remote", "s3"
BACKUP_NAME=""

# Local backup configuration
LOCAL_BACKUP_DIR="./backups"

# Remote server configuration (rsync/scp)
REMOTE_USER="backup_user"
REMOTE_HOST="backup.example.com"
REMOTE_PATH="/backup/destination/"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# AWS S3 configuration
S3_BUCKET="your-backup-bucket"
S3_PATH="backups/"

# Logging
LOG_DIR="./logs"
LOG_FILE="$LOG_DIR/backup_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="$LOG_DIR/backup-report_$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create log directory
mkdir -p "$LOG_DIR"

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" | tee -a "$LOG_FILE"
}

# Function to print colored status messages
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}$message${NC}"
    log_message "INFO" "$message"
}

# Function to check prerequisites based on backup type
check_prerequisites() {
    log_message "INFO" "Checking prerequisites for $BACKUP_TYPE backup..."
    
    case "$BACKUP_TYPE" in
        "remote")
            if ! command -v rsync &> /dev/null; then
                print_status "$RED" "ERROR: rsync is not installed!"
                return 1
            fi
            if ! command -v ssh &> /dev/null; then
                print_status "$RED" "ERROR: ssh is not installed!"
                return 1
            fi
            ;;
        "s3")
            if ! command -v aws &> /dev/null; then
                print_status "$RED" "ERROR: AWS CLI is not installed!"
                print_status "$YELLOW" "Install with: pip install awscli"
                return 1
            fi
            if ! aws sts get-caller-identity &> /dev/null; then
                print_status "$RED" "ERROR: AWS credentials not configured!"
                print_status "$YELLOW" "Configure with: aws configure"
                return 1
            fi
            ;;
        "local")
            mkdir -p "$LOCAL_BACKUP_DIR"
            ;;
    esac
    return 0
}

# Function to create local backup
backup_local() {
    log_message "INFO" "Creating local backup..."
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_filename
    
    if [ -n "$BACKUP_NAME" ]; then
        backup_filename="${BACKUP_NAME}_${timestamp}.tar.gz"
    else
        local dir_name=$(basename "$SOURCE_DIR")
        backup_filename="${dir_name}_backup_${timestamp}.tar.gz"
    fi
    
    local backup_path="$LOCAL_BACKUP_DIR/$backup_filename"
    
    log_message "INFO" "Creating compressed archive: $backup_path"
    
    if tar -czf "$backup_path" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>>"$LOG_FILE"; then
        echo "$backup_path"
        return 0
    else
        log_message "ERROR" "Failed to create local backup"
        return 1
    fi
}

# Function to backup to remote server using rsync
backup_remote() {
    log_message "INFO" "Starting remote backup to $REMOTE_HOST..."
    
    # Create temporary archive first
    local temp_backup=$(backup_local)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Transfer to remote server
    local remote_filename=$(basename "$temp_backup")
    local rsync_cmd="rsync -avz --progress"
    
    if [ -f "$SSH_KEY_PATH" ]; then
        rsync_cmd="$rsync_cmd -e 'ssh -i $SSH_KEY_PATH'"
    fi
    
    rsync_cmd="$rsync_cmd $temp_backup $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"
    
    log_message "INFO" "Executing: $rsync_cmd"
    
    if eval "$rsync_cmd" >> "$LOG_FILE" 2>&1; then
        log_message "INFO" "Remote backup completed successfully"
        echo "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH$remote_filename"
        return 0
    else
        log_message "ERROR" "Remote backup failed"
        return 1
    fi
}

# Function to backup to AWS S3
backup_s3() {
    log_message "INFO" "Starting S3 backup to s3://$S3_BUCKET/$S3_PATH..."
    
    # Create temporary archive first
    local temp_backup=$(backup_local)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Upload to S3
    local s3_key="$S3_PATH$(basename "$temp_backup")"
    local s3_uri="s3://$S3_BUCKET/$s3_key"
    
    log_message "INFO" "Uploading to $s3_uri"
    
    if aws s3 cp "$temp_backup" "$s3_uri" >> "$LOG_FILE" 2>&1; then
        log_message "INFO" "S3 backup completed successfully"
        echo "$s3_uri"
        return 0
    else
        log_message "ERROR" "S3 backup failed"
        return 1
    fi
}

# Function to generate comprehensive report
generate_report() {
    local status="$1"
    local backup_location="$2"
    local start_time="$3"
    local end_time="$4"
    local backup_size="$5"
    
    local duration=$((end_time - start_time))
    local source_size=$(du -sh "$SOURCE_DIR" 2>/dev/null | cut -f1 || echo "N/A")
    
    {
        echo "=========================================="
        echo "         BACKUP OPERATION REPORT"
        echo "=========================================="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo ""
        echo "SOURCE INFORMATION:"
        echo "  Directory: $SOURCE_DIR"
        echo "  Size: $source_size"
        echo ""
        echo "BACKUP DETAILS:"
        echo "  Type: $BACKUP_TYPE"
        echo "  Status: $status"
        echo "  Location: $backup_location"
        echo "  Size: $backup_size"
        echo "  Duration: ${duration} seconds"
        echo ""
        
        case "$BACKUP_TYPE" in
            "remote")
                echo "REMOTE SERVER DETAILS:"
                echo "  Host: $REMOTE_HOST"
                echo "  User: $REMOTE_USER"
                echo "  Path: $REMOTE_PATH"
                ;;
            "s3")
                echo "AWS S3 DETAILS:"
                echo "  Bucket: $S3_BUCKET"
                echo "  Path: $S3_PATH"
                ;;
            "local")
                echo "LOCAL BACKUP DETAILS:"
                echo "  Directory: $LOCAL_BACKUP_DIR"
                ;;
        esac
        
        echo ""
        echo "LOG FILES:"
        echo "  Main Log: $LOG_FILE"
        echo "  Report: $REPORT_FILE"
        echo ""
        
        if [ "$status" = "FAILED" ]; then
            echo "ERROR DETAILS:"
            echo "=============="
            tail -10 "$LOG_FILE" 2>/dev/null || echo "No error details available"
        fi
        
        echo "=========================================="
    } > "$REPORT_FILE"
    
    # Display report
    cat "$REPORT_FILE"
}

# Function to display usage information
usage() {
    echo "Enhanced Backup Solution"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --source DIR      Source directory to backup (required)"
    echo "  -t, --type TYPE       Backup type: local, remote, s3 (default: local)"
    echo "  -n, --name NAME       Custom backup name"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s /home/user/documents -t local"
    echo "  $0 -s /var/www -t remote -n website_backup"
    echo "  $0 -s /home/user/photos -t s3"
    echo ""
    echo "Configuration:"
    echo "  Edit script variables for remote server and S3 settings"
}

echo -e "${BLUE}Starting Automated Backup Solution...${NC}"

# Validate input
if [ -z "$SOURCE_DIR" ]; then
    echo -e "${RED}Usage: $0 <source_directory> [backup_name]${NC}"
    echo "Example: $0 /home/user/documents my_backup"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory '$SOURCE_DIR' doesn't exist${NC}"
    exit 1
fi

# Start timing
start_time=$(date +%s)
log_message "=== Backup process started ==="
log_message "Source directory: $SOURCE_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup filename
timestamp=$(date '+%Y%m%d_%H%M%S')
if [ -n "$BACKUP_NAME" ]; then
    backup_filename="${BACKUP_NAME}_${timestamp}.tar.gz"
else
    dir_name=$(basename "$SOURCE_DIR")
    backup_filename="${dir_name}_backup_${timestamp}.tar.gz"
fi

backup_path="$BACKUP_DIR/$backup_filename"

log_message "Creating backup: $backup_path"
echo -e "${YELLOW}Creating backup: $backup_filename${NC}"

# Create compressed backup
if tar -czf "$backup_path" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null; then
    end_time=$(date +%s)
    backup_size=$(du -h "$backup_path" | cut -f1)
    
    echo -e "${GREEN}✓ Backup created successfully${NC}"
    log_message "Backup created successfully"
    log_message "Backup size: $backup_size"
    log_message "Backup location: $backup_path"
    
    # Generate success report
    generate_report "SUCCESS" "$backup_path" "$start_time" "$end_time"
    
    echo -e "${GREEN}✓ Backup completed successfully${NC}"
    echo "Backup size: $backup_size"
    echo "Backup location: $backup_path"
    echo "Report: $REPORT_FILE"
    
else
    end_time=$(date +%s)
    echo -e "${RED}✗ Backup failed${NC}"
    log_message "ERROR: Backup creation failed"
    
    # Generate failure report
    generate_report "FAILED" "$backup_path" "$start_time" "$end_time"
    
    exit 1
fi

log_message "=== Backup process completed ==="
