import re
import os
from datetime import datetime
from markdown import parse_markdown
from journal_entry import JournalEntry
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, format="%(asctime)s - %(levelname)s - %(message)s")

vault_path = "/home/demi/.Obsidian"

def find_notes(vault_path):
    date_pattern = re.compile(r"\d{4}-\d{2}-\d{2}\.md")
    daily_notes = []

    for root, _, files in os.walk(vault_path):
        for file_name in files:
            if date_pattern.match(file_name):
                file_path = os.path.join(root, file_name)
                daily_notes.append(file_path)
                logging.debug(f"Found daily note: {file_path}")

    logging.info(f"Total daily notes found: {len(daily_notes)}")
    return daily_notes

# Process notes and convert them into JournalEntry instances with skill links
def process_notes(vault_path):
    daily_notes = find_notes(vault_path)
    journal_entries = []

    for note_path in daily_notes:
        try:
            # Extract date from filename
            note_date_str = os.path.splitext(os.path.basename(note_path))[0]
            note_date = datetime.strptime(note_date_str, "%Y-%m-%d").date()
            logging.debug(f"Parsed date {note_date} from file name {note_path}")

            # Read note content
            with open(note_path, "r") as file:
                content = file.read()
            logging.debug(f"Read content from {note_path}")

            # Parse Markdown content to HTML
            parsed_content = parse_markdown(content)
            logging.debug(f"Parsed Markdown content from {note_path}")

            # Create a JournalEntry instance and add linked skills
            entry = JournalEntry(date=note_date, content=parsed_content)
            skill_tags = re.findall(r"#Skill:([A-Za-z]+)", content)
            for skill in skill_tags:
                entry.add_linked_skill(skill)
                logging.debug(f"Linked skill '{skill}' found in {note_path}")

            # Append the JournalEntry instance to journal_entries
            journal_entries.append(entry)
            logging.info(f"Created JournalEntry for {note_date} with skills: {entry.linked_skills}")

        except Exception as e:
            logging.error(f"Error processing note {note_path}: {e}")

    logging.info(f"Total journal entries created: {len(journal_entries)}")
    return journal_entries

if __name__ == '__main__':
    journal_entries = process_notes(vault_path)
    for entry in journal_entries:
        if isinstance(entry, JournalEntry):  # Verify entry type
            logging.debug(f"Date: {entry.date}, Linked Skills: {entry.linked_skills}")
            logging.debug(f"Content with Links: {entry.display_with_links()[:100]}...")
        else:
            logging.error(f"Unexpected object in journal_entries: {entry} (type: {type(entry)})")

