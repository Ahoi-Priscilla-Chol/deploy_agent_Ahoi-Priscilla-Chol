# deploy_agent - student Attendance Tracker Setup

A shell script that automates the full bootstrapping of the student Attendance Tracker project work.

## How to run

chmod +x setup_project.sh
./setup_project.sh

You will be prompted for:
- A project name suffix → creates attendance_tracker_<suffix>/
-Whether to update thresholds (y/n)
  - If yes: new warning % and failure % (defaults: 75% / 50%)

## Project structure created

attendance_tracker_<input>/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
    └── reports.log

## How to trigger the aechive feature

Press Ctrl+C at any point while the script is running.
The SIGINT trap will:
1. Compress the current directory into attendance_tracker_<input>_archive.tar.gz
2. Delete the incomplete directory to keep the workspace clean
3. Exit

## Running the trcker after setup

cd attendance_tracker_<input>
python3 attendance_checker.py

## Requirements
- Bash
- python3
- tar and sed (standard on linux / macOS / Git Bash on Windows)
