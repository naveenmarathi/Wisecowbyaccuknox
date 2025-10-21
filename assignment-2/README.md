# Problem Statement 2: System health Monitoring & Application health checker


### 1. System Health Monitoring Script ✅
**File**: `system-health.py`

**Features**:
- Monitors CPU, memory, and disk usage
- Tracks running processes count
- Configurable thresholds (CPU: 80%, Memory: 65%, Disk: 90%)
- Real-time alerts for threshold violations
- Timestamped reports

**Usage**:
```bash
python3 system-health.py
```

**Sample Output**:
```
[2025-09-17 12:50:04] System Health Report
Running Processes: 393
CPU Usage: 4.3%
Memory Usage: 69.9%
Disk Usage: 7.2%
⚠️ Alerts:
High Memory usage: 69.9%
```


### 4. Application Health Checker ✅
**File**: `app-health.sh`

**Features**:
- HTTP status code monitoring
- Simple UP/DOWN status reporting
- Configurable target URL
- Lightweight curl-based implementation

**Usage**:
```bash
chmod +x app-health.sh
./app-health.sh
```

**Configuration**:
```bash
# Edit the URL in the script
URL="https://accuknox.com"
```

**Sample Output**:
```
Checking application: https://accuknox.com
Status Code: 200
✅ Application is UP
```

**Prerequisites**:
```bash
# Ensure curl is installed
sudo apt install curl -y
```
