import psutil

# thresholds
CPU_THRESHOLD = 80
MEM_THRESHOLD = 65
DISK_THRESHOLD = 90

cpu = psutil.cpu_percent(interval=1)
mem = psutil.virtual_memory().percent
disk = psutil.disk_usage('/').percent

print("-------System Health Report------")
print(f"CPU: {cpu}%")
print(f"Memory: {mem}%")
print(f"Disk: {disk}%")

if cpu > CPU_THRESHOLD:
    print("⚠️ High CPU usage")
if mem > MEM_THRESHOLD:
    print("⚠️ High Memory usage")
if disk > DISK_THRESHOLD:
    print("⚠️ High Disk usage")
