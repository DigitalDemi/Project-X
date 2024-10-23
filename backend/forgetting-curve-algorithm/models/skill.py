from datetime import datetime, timedelta

class Skill:
    def __init__(self, name, last_reviewed, interval, performance, sub_skills=None):
        self.name = name
        self.last_reviewed = last_reviewed
        self.interval = interval  # Days between reviews
        self.performance = performance
        self.sub_skills = sub_skills if sub_skills else []
        self.next_review = None
        self.halflife = None

    def update_review(self, next_review, halflife):
        self.next_review = next_review
        self.halflife = halflife

    def adjust_subskills(self):
        """Adjust sub-skills based on the main skill's performance."""
        for sub_skill in self.sub_skills:
            sub_skill.adjust_based_on_parent(self.performance)


class SubSkill(Skill):
    def adjust_based_on_parent(self, parent_performance):
        """Adjust sub-skill performance based on the parent skill's performance."""
        if parent_performance < 0.5:
            self.performance *= 0.9  # Slow down if parent skill is weak
        else:
            self.performance *= 1.1  # Speed up if parent skill is strong

