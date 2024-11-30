from ics import Calendar, Event
from datetime import datetime, timedelta

def create_user_ics_file(user_id, events):
    calendar = Calendar()
    
    for event in events:
        e = Event()
        e.name = event["summary"]
        e.begin = event["start"]
        e.end = event["end"]
        e.description = event.get("description", "")
        calendar.events.add(e)
    
    # Save the file with a unique name for each user
    filename = f"schedule_{user_id}.ics"
    with open(filename, "w") as f:
        f.writelines(calendar)
    print(f"ICS file created for user {user_id}: {filename}")

# Example usage
user_id = "user123"
events = [
    {
        "summary": "Math Study Session",
        "start": datetime.now(),
        "end": datetime.now() + timedelta(hours=1),
        "description": "Review algebra and geometry."
    },
    {
        "summary": "History Review",
        "start": datetime.now() + timedelta(days=1),
        "end": datetime.now() + timedelta(days=1, hours=1),
        "description": "Prepare for history exam."
    }
]

create_user_ics_file(user_id, events)

