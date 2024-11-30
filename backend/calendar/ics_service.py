from flask import Flask, Response, send_file  # Removed abort since it's not used
from ics import Calendar, Event
from datetime import datetime
import sqlite3
import os
import logging

app = Flask(__name__)
ICS_FOLDER = "ics_files"  # Folder to store .ics files

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
logger.info("Starting the Flask app...")  # Test log message


# Ensure the ICS folder exists
if not os.path.exists(ICS_FOLDER):
    os.makedirs(ICS_FOLDER)

# Connect to the database and retrieve events for a specific user
def get_user_events(user_id):
    conn = sqlite3.connect("events.db")
    cursor = conn.cursor()
    
    # Query the database for events for this specific user
    cursor.execute("SELECT summary, start_time, end_time, description FROM events WHERE user_id = ?", (user_id,))
    rows = cursor.fetchall()
    conn.close()

    # Convert query results into a list of event dictionaries
    events = []
    for row in rows:
        events.append({
            "summary": row[0],
            "start": datetime.fromisoformat(row[1]),  # Assuming ISO format in the database
            "end": datetime.fromisoformat(row[2]),
            "description": row[3]
        })
    logger.info(f"Retrieved {len(events)} events for user_id {user_id}: {events}")
    return events

# Generate the .ics file and save it to disk
def generate_ics_file(user_id):
    calendar = Calendar()
    events = get_user_events(user_id)

    if not events:
        logger.warning(f"No events found for user_id: {user_id}")
        return None  # Return None if no events are found

    for event in events:
        e = Event()
        e.name = event["summary"]
        e.begin = event["start"]
        e.end = event["end"]
        e.description = event.get("description", "")
        calendar.events.add(e)

    filename = f"{ICS_FOLDER}/{user_id}_schedule.ics"
    with open(filename, "w") as f:
        f.writelines(calendar)
    logger.info(f"ICS file generated: {filename}")
    return filename

@app.route("/calendar/<user_id>.ics")
def get_user_ics(user_id):
    filename = f"{ICS_FOLDER}/{user_id}_schedule.ics"

    # Check if the file exists; if not, generate it
    if not os.path.exists(filename):
        generated_filename = generate_ics_file(user_id)

        if generated_filename is None:
            logger.info(f"No calendar data available for user_id: {user_id}")
            return Response("No calendar data available.", status=404)

        filename = generated_filename

    # Serve the .ics file
    logger.info(f"Serving ICS file for user_id: {user_id}")
    return send_file(filename, mimetype="text/calendar", as_attachment=True, download_name=f"{user_id}_schedule.ics")

if __name__ == "__main__":
    app.run(port=5000, debug=True)

