#!/bin/bash

read -rp "Enter a project name suffix (e.g your name or cohort): " PROJECT_INPUT

if [[ -z "$PROJECT_INPUT" ]]; then
 echo "Error: project name suffix cannot be empty."
 exit 1
fi

PROJECT_DIR="attendance_tracker_${PROJECT_INPUT}"

clean() {
 echo ""
 echo "Warning: Interrupt detected! Packaging current state before exit..."
 ARCHIVE_NAME="attendance_tracker_${PROJECT_INPUT}_archive.tar.gz"
 if [[ -d "$PROJECT_DIR" ]]; then
    tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR" 2>/dev/null
    echo "Archive saved: $ARCHIVE_NAME"
    rm -rf "$PROJECT_DIR"
    echo "Incomplete directory removed."
 else
    echo "Nothing to archive."
 fi
 echo "Exiting cleanly."
 exit 1
 
}

trap clean SIGINT

echo ""
echo "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/Helpers"
mkdir -p "$PROJECT_DIR/reports"

cat > "$PROJECT_DIR/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime


def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"---Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Name']
            email = row['Email']
            attended = int(row['Attendance Count'])
            attendance_pct = (attended / total_sessions) * 100
            message = ""

            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")


if __name__ == "__main__":
    run_attendance_check()
PYEOF

cat > "$PROJECT_DIR/Helpers/assets.csv" << 'CSVEOF'
Email,Name,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF

cat > "$PROJECT_DIR/Helpers/config.json" << 'JSONEOF'
{
     "thresholds": {
          "warning": 75,
          "failure": 50
      },
      "run_mode": "live",
      "total_sessions": 15
}
JSONEOF

cat > "$PROJECT_DIR/reports/reports.log" << 'LOGEOF'
---Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will failthis class.
LOGEOF

echo "All files created."

echo ""
read -rp "Do you want to update the attendance thresholds? (y/n): " UPDATE_THRES

if [[ "$UPDATE_THRES" =~ ^[Yy]$ ]]; then
   read -rp " Enter new Warning thresholds % (default 75): " NEW_WARNING
   read -rp " Enter nwe failure thresholds % (default 50): " NWE_FAILURE
   NEW_WARNING=${NEW_WARNING:-75}
   NEW_FAILURE=${NEW_FAILURE:-50}
   CONFIG_FILE="$PROJECT_DIR/Helpers/config.json"
   sed -i "s/\"warning\": [0-9]*/\"warning\": $NEW_WARNING/" "$CONFIG_FILE"
   sed -i "s/\"failure\": [0-9]*/\"failure\": $NEW_FAILURE/" "$CONFIG_FILE"
   echo "config.json updated: warning=${NEW_WARNING}%, failure=${NEW_FAILURE}%"
   cat "$CONFIG_FILE"
else
	echo "Keeping default thresholdS (warning: 75%, failure: 50%)."
fi

echo ""
echo "Running environment health check..."

if python3 --version &>/dev/null; then
  PY_VER=$(python3 --version 2>&1)
  echo "python3 found: $PY_VER"
else
   echo "WARNING: python3 is not installed."
fi

echo ""
echo "Verifying directory structure..."
ALL_OK=true
for EXPECTED in \
    "$PROJECT_DIR/attendance_checker.py" \
    "$PROJECT_DIR/Helpers/assets.csv" \
    "$PROJECT_DIR/Helpers/config.json" \
    "$PROJECT_DIR/reports/reports.log"
do
    if [[ -f "$EXPECTED" ]]; then
      echo " OK: $EXPECTED"
    else
      echo " MISSING: $EXPECTED"
      ALL_OK=false
    fi
done

echo ""
if $ALL_OK; then
   echo "setup complete! '$PROJECT_DIR' is ready."
   echo "To run: cd $PROJECT_DIR && python3 attendance_checker.py"
else
   echo "Setup finished with warnings. Some files are missing."
fi    

      


     

                    


