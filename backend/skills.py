class Skill:
    def __init__(self, name, last_reviewed, interval, performance):
        self.name = name
        self.last_reviewed = last_reviewed
        self.interval = interval  # Days between reviews
        self.performance = performance  # How well the user performed
        self.next_review = None
        self.halflife = None

    def update_review(self, next_review, halflife):
        self.next_review = next_review
        self.halflife = halflife

