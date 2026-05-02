from datetime import datetime

activity_logs = [
    {"time": datetime.now().strftime("%H:%M:%S"), "event": "Logger initialized", "type": "system"}
]

def add_log(event, log_type="info"):
    activity_logs.insert(0, {"time": datetime.now().strftime("%H:%M:%S"), "event": event, "type": log_type})
    if len(activity_logs) > 50: # Increased log history
        activity_logs.pop()
