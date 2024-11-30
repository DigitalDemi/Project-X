class JournalEntry:
    def __init__(self, date, content, linked_skills=None):
        self.date = date
        self.content = content
        self.linked_skills = linked_skills if linked_skills else []

    def add_linked_skill(self, skill):
        if skill not in self.linked_skills:
            self.linked_skills.append(skill)

    def display_with_links(self):
        # Convert skill tags to clickable links in the content
        linked_content = self.content
        for skill in self.linked_skills:
            linked_content = linked_content.replace(f"#Skill:{skill}", f'<a href="/skills/{skill}">{skill}</a>')
        return linked_content

