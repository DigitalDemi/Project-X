from datetime import datetime, timedelta
import json
from collections import defaultdict
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

class DayFuzzySet:
    def __init__(self, name):
        self.name = name

    def trapezoidal_mf(self, x, a, b, c, d):
        """Trapezoidal membership function"""
        if x <= a or x >= d:
            return 0
        elif b <= x <= c:
            return 1
        elif a < x < b:
            return (x - a) / (b - a)
        else:
            return (d - x) / (d - c)

class DaySpacing:
    def __init__(self):
        self.sets = {}
        self.rules = []
        
    def add_fuzzy_set(self, name, points):
        """Add a new fuzzy set with trapezoidal membership function"""
        fuzzy_set = DayFuzzySet(name)
        fuzzy_set.points = points
        self.sets[name] = fuzzy_set
    
    def calculate_membership(self, days):
        """Calculate membership degrees for given number of days"""
        memberships = {}
        for set_name, fuzzy_set in self.sets.items():
            a, b, c, d = fuzzy_set.points
            membership = fuzzy_set.trapezoidal_mf(days, a, b, c, d)
            memberships[set_name] = membership
        return memberships
    
    def add_rule(self, condition, consequence):
        """Add a fuzzy rule"""
        self.rules.append((condition, consequence))
    
    def evaluate_rules(self, memberships):
        """Evaluate all rules for given memberships"""
        rule_strengths = {}
        for condition, consequence in self.rules:
            strength = memberships.get(condition, 0)
            rule_strengths[consequence] = max(
                rule_strengths.get(consequence, 0),
                strength
            )
        return rule_strengths
    
    def defuzzify_centroid(self, rule_strengths, output_ranges):
        """Defuzzify using centroid method"""
        if not rule_strengths:
            return None
            
        numerator = 0
        denominator = 0
        
        for output_name, strength in rule_strengths.items():
            if strength > 0:
                center = sum(output_ranges[output_name]) / len(output_ranges[output_name])
                numerator += center * strength
                denominator += strength
                
        if denominator == 0:
            return None
            
        return numerator / denominator

class TopicNode:
    def __init__(self, name, parent=None):
        self.name = name
        self.parent = parent
        self.children = {}  # name: TopicNode
        self.review_data = None  # Will store the review information
        self.status = 'active'  # 'active', 'disabled', or 'completed'

class TopicGraph:
    def __init__(self):
        self.root = TopicNode("root")
        
    def add_topic_path(self, path, review_data=None):
        """Add a topic path (e.g., 'Math/Calculus/Limits')"""
        current = self.root
        parts = path.split('/')
        
        for part in parts:
            if part not in current.children:
                current.children[part] = TopicNode(part, current)
            current = current.children[part]
        
        if review_data:
            current.review_data = review_data
            current.status = review_data.get('status', 'active')
            
    def get_topic_path(self, path):
        """Get a topic node by path"""
        current = self.root
        for part in path.split('/'):
            if part not in current.children:
                return None
            current = current.children[part]
        return current
    
    def get_subtopics(self, path):
        """Get all subtopics under a path"""
        node = self.get_topic_path(path) if path else self.root
        if not node:
            return []
            
        subtopics = []
        def collect_subtopics(current_node, current_path):
            if current_node.review_data:
                subtopics.append(current_path)
            for name, child in current_node.children.items():
                new_path = f"{current_path}/{name}" if current_path else name
                collect_subtopics(child, new_path)
                
        collect_subtopics(node, path if path else "")
        return subtopics
    
    def get_parent_topics(self, path):
        """Get all parent topics of a path"""
        parents = []
        parts = path.split('/')
        current_path = ""
        
        for part in parts[:-1]:
            if current_path:
                current_path += f"/{part}"
            else:
                current_path = part
            parents.append(current_path)
            
        return parents

class LearningVisualization:
    def __init__(self, spaced_learning_system):
        self.learning_system = spaced_learning_system

    def plot_learning_progress(self):
        """Create multiple visualizations of learning progress"""
        fig = plt.figure(figsize=(15, 10))
        
        gs = fig.add_gridspec(2, 2)
        
        self._plot_stages_distribution(fig.add_subplot(gs[0, 0]))
        self._plot_review_timeline(fig.add_subplot(gs[0, 1]))
        self._plot_difficulty_distribution(fig.add_subplot(gs[1, 0]))
        self._plot_interval_progression(fig.add_subplot(gs[1, 1]))

        plt.tight_layout()
        plt.show()

    def _plot_stages_distribution(self, ax):
        """Pie chart of topics in each learning stage"""
        stages = defaultdict(int)
        for topic in self.learning_system.topics.values():
            if topic['status'] == 'active':  # Only count active topics
                stages[topic['stage']] += 1

        if sum(stages.values()) > 0:
            labels = stages.keys()
            sizes = stages.values()
            colors = ['#FF9999', '#66B2FF', '#99FF99', '#FFCC99', '#FF99CC']
            
            ax.pie(sizes, labels=labels, colors=colors, autopct='%1.1f%%', 
                  startangle=90)
            ax.set_title('Distribution of Active Topics by Learning Stage')

    def _plot_review_timeline(self, ax):
        """Line plot showing cumulative reviews over time"""
        review_dates = []
        for topic in self.learning_system.topics.values():
            if topic['status'] == 'active':  # Only plot active topics
                for review in topic['review_history']:
                    review_dates.append(review['date'])

        if review_dates:
            review_dates.sort()
            dates = np.array(review_dates)
            cumulative_reviews = np.arange(1, len(dates) + 1)
            
            ax.plot(dates, cumulative_reviews, marker='o')
            ax.set_title('Cumulative Reviews Over Time')
            ax.set_xlabel('Date')
            ax.set_ylabel('Total Reviews')
            ax.tick_params(axis='x', rotation=45)

    def _plot_difficulty_distribution(self, ax):
        """Bar chart showing distribution of difficulty ratings"""
        difficulties = defaultdict(int)
        for topic in self.learning_system.topics.values():
            if topic['status'] == 'active':  # Only count active topics
                for review in topic['review_history']:
                    difficulties[review['difficulty']] += 1

        if difficulties:
            difficulties = dict(sorted(difficulties.items()))
            bars = ax.bar(difficulties.keys(), difficulties.values())
            
            colors = {'easy': '#99FF99', 'normal': '#66B2FF', 'hard': '#FF9999'}
            for bar, difficulty in zip(bars, difficulties.keys()):
                bar.set_color(colors.get(difficulty, '#CCCCCC'))
            
            ax.set_title('Distribution of Difficulty Ratings')
            ax.set_xlabel('Difficulty')
            ax.set_ylabel('Number of Reviews')

    def _plot_interval_progression(self, ax):
        """Scatter plot showing how review intervals change over time"""
        dates = []
        intervals = []
        colors = []
        
        for topic in self.learning_system.topics.values():
            if topic['status'] == 'active':  # Only plot active topics
                for review in topic['review_history']:
                    dates.append(review['date'])
                    intervals.append(review['interval'])
                    colors.append({'easy': 'g', 'normal': 'b', 'hard': 'r'}
                                [review['difficulty']])

        if dates:
            ax.scatter(dates, intervals, c=colors, alpha=0.6)
            ax.set_title('Review Intervals Over Time')
            ax.set_xlabel('Date')
            ax.set_ylabel('Interval (days)')
            ax.tick_params(axis='x', rotation=45)

class EnhancedSpacedLearningSystem:
    def __init__(self):
        self.topics = {}
        self.spacing_system = DaySpacing()
        self.topic_graph = TopicGraph()
        self._setup_fuzzy_system()
        
    def _setup_fuzzy_system(self):
        # Define fuzzy sets based on learning stages
        self.spacing_system.add_fuzzy_set('first_time', [0, 0, 1, 2])
        self.spacing_system.add_fuzzy_set('early_stage', [1, 2, 3, 5])
        self.spacing_system.add_fuzzy_set('mid_stage', [3, 5, 10, 15])
        self.spacing_system.add_fuzzy_set('late_stage', [10, 15, 20, 30])
        self.spacing_system.add_fuzzy_set('mastered', [20, 30, 60, 60])

        # Add rules for different learning stages
        self.spacing_system.add_rule('first_time', 'same_day')
        self.spacing_system.add_rule('early_stage', 'few_days')
        self.spacing_system.add_rule('mid_stage', 'week_plus')
        self.spacing_system.add_rule('late_stage', 'two_weeks')
        self.spacing_system.add_rule('mastered', 'monthly')

        # Define output ranges
        self.output_ranges = {
            'same_day': [0, 1],
            'few_days': [2, 3],
            'week_plus': [5, 10],
            'two_weeks': [10, 20],
            'monthly': [30, 60]
        }

    def add_topic_with_subtopics(self, topic_path, status='active'):
        """Add a topic with its full path and initial status"""
        topic_id = topic_path.replace('/', ':')
        if topic_id not in self.topics:
            self.topics[topic_id] = {
                'subject': topic_path.split('/')[0],
                'topic': '/'.join(topic_path.split('/')[1:]),
                'review_history': [],
                'next_review': datetime.now(),
                'stage': 'first_time',
                'created_at': datetime.now(),
                'status': status
            }
            
            self.topic_graph.add_topic_path(topic_path, self.topics[topic_id])
            
            # Create parent topics
            parents = self.topic_graph.get_parent_topics(topic_path)
            for parent in parents:
                parent_id = parent.replace('/', ':')
                if parent_id not in self.topics:
                    self.topics[parent_id] = {
                        'subject': parent.split('/')[0],
                        'topic': '/'.join(parent.split('/')[1:]),
                        'review_history': [],
                        'next_review': datetime.now(),
                        'stage': 'first_time',
                        'created_at': datetime.now(),
                        'status': status
                    }
                    self.topic_graph.add_topic_path(parent, self.topics[parent_id])
                    
        return topic_id

    def set_topic_status(self, topic_path, status):
        """Set the status of a topic"""
        topic_id = topic_path.replace('/', ':')
        if topic_id in self.topics:
            self.topics[topic_id]['status'] = status
            node = self.topic_graph.get_topic_path(topic_path)
            if node:
                node.status = status

    def get_topics_to_review(self):
        """Get all active topics that need review today"""
        now = datetime.now()
        return {
            topic_id: topic for topic_id, topic in self.topics.items()
            if topic['next_review'].date() <= now.date() 
            and topic['status'] == 'active'
        }

    def adjust_interval(self, topic_id, difficulty):
        """Adjust review interval based on difficulty feedback"""
        if topic_id not in self.topics:
            return None

        topic = self.topics[topic_id]
        current_stage = topic['stage']
        days_since_last = 1

        if topic['review_history']:
            last_review = topic['review_history'][-1]['date']
            days_since_last = (datetime.now() - last_review).days

        memberships = self.spacing_system.calculate_membership(days_since_last)
        rule_strengths = self.spacing_system.evaluate_rules(memberships)
        base_interval = self.spacing_system.defuzzify_centroid(rule_strengths, self.output_ranges)

        if difficulty == 'hard':
            interval = max(1, base_interval * 0.6)
            new_stage = self._decrease_stage(current_stage)
        elif difficulty == 'easy':
            interval = base_interval * 1.4
            new_stage = self._increase_stage(current_stage)
        else:
            interval = base_interval
            new_stage = current_stage

        next_review = datetime.now() + timedelta(days=interval)
        self.topics[topic_id]['next_review'] = next_review
        self.topics[topic_id]['stage'] = new_stage
        self.topics[topic_id]['review_history'].append({
            'date': datetime.now(),
            'difficulty': difficulty,
            'interval': interval
        })

        return next_review

    def _decrease_stage(self, current_stage):
        stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered']
        current_idx = stages.index(current_stage)
        return stages[max(0, current_idx - 1)]

    def _increase_stage(self, current_stage):
        stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered']
        current_idx = stages.index(current_stage)
        return stages[min(len(stages) - 1, current_idx + 1)]

    def get_interval_buckets(self):
        """Get topics organized by their review intervals"""
        now = datetime.now()
        buckets = defaultdict(list)
        
        for topic_id, topic in self.topics.items():
            if topic['status'] != 'active':
                continue
                
            days_until_review = (topic['next_review'] - now).days
            stage = topic['stage']
            
            bucket_info = {
                'subject': topic['subject'],
                'topic': topic['topic'],
                'next_review': topic['next_review'].strftime('%Y-%m-%d'),
                'days_until': days_until_review,
                'stage': stage,
                'reviews_completed': len(topic['review_history'])
            }
            
            if days_until_review <= 0:
                buckets['Due Now'].append(bucket_info)
            elif days_until_review <= 3:
                buckets['Next 3 Days'].append(bucket_info)
            elif days_until_review <= 7:
                buckets['Next Week'].append(bucket_info)
            elif days_until_review <= 30:
                buckets['Next Month'].append(bucket_info)
            else:
                buckets['Later'].append(bucket_info)
            
        return buckets

    def print_interval_summary(self):
        """Print a summary of all intervals and topics"""
        buckets = self.get_interval_buckets()
        stages = {'first_time': 0, 'early_stage': 0, 'mid_stage': 0, 
                 'late_stage': 0, 'mastered': 0}
        
        print("\n=== REVIEW SCHEDULE SUMMARY ===")
        print("\nTopics by Review Date:")
        print("---------------------------")
        
        for bucket_name, topics in buckets.items():
            if topics:  # Only show non-empty buckets
                print(f"\n{bucket_name} ({len(topics)} topics):")
                for topic in sorted(topics, key=lambda x: x['next_review']):
                    stages[topic['stage']] += 1
                    print(f"  • {topic['subject']} - {topic['topic']}")
                    print(f"    Next review: {topic['next_review']} " + 
                          f"(Stage: {topic['stage']}, " +
                          f"Reviews: {topic['reviews_completed']})")

        print("\nLearning Stages Summary:")
        print("----------------------")
        total_topics = sum(stages.values())
        if total_topics > 0:
            for stage, count in stages.items():
                percentage = (count / total_topics) * 100
                print(f"{stage}: {count} topics ({percentage:.1f}%)")
        
        print("\nInterval Ranges:")
        print("---------------")
        for output_name, range_vals in self.output_ranges.items():
            print(f"{output_name}: {range_vals[0]}-{range_vals[1]} days")

    def print_topic_tree(self, show_all=False):
        """Print the topic hierarchy with status"""
        def print_node(node, level=0):
            indent = "  " * level
            if node.review_data:
                status = node.review_data.get('status', 'active')
                stage = node.review_data['stage']
                reviews = len(node.review_data['review_history'])
                status_symbol = {
                    'active': '🟢',
                    'disabled': '⚫',
                    'completed': '✅'
                }.get(status, '❓')
                
                if show_all or status == 'active':
                    print(f"{indent}└─ {status_symbol} {node.name} "
                          f"(Stage: {stage}, Reviews: {reviews})")
            else:
                print(f"{indent}└─ {node.name}/")
            
            for child in sorted(node.children.values(), key=lambda x: x.name):
                print_node(child, level + 1)

        print("\n=== TOPIC HIERARCHY ===")
        print("Status: 🟢 Active  ⚫ Disabled  ✅ Completed")
        for child in sorted(self.topic_graph.root.children.values(), 
                          key=lambda x: x.name):
            print_node(child)

    def get_related_topics(self, topic_path):
        """Get related topics (siblings, parent, children)"""
        node = self.topic_graph.get_topic_path(topic_path)
        if not node:
            return []
            
        related = set()
        
        if node.parent:
            for sibling in node.parent.children.values():
                if sibling.review_data:
                    related.add(sibling.name)
                    
        for child in node.children.values():
            if child.review_data:
                related.add(child.name)
                
        if node.parent and node.parent.name != "root":
            related.add(node.parent.name)
            
        return list(related)

    def save_state(self, filename='learning_state.json'):
        """Save the current state to a file"""
        state = {
            topic_id: {
                **topic,
                'next_review': topic['next_review'].isoformat(),
                'created_at': topic['created_at'].isoformat(),
                'review_history': [
                    {**review, 'date': review['date'].isoformat()}
                    for review in topic['review_history']
                ]
            }
            for topic_id, topic in self.topics.items()
        }
        with open(filename, 'w') as f:
            json.dump(state, f, indent=2)

    def load_state(self, filename='learning_state.json'):
        """Load state from a file"""
        try:
            with open(filename, 'r') as f:
                state = json.load(f)
                self.topics = {
                    topic_id: {
                        **topic,
                        'next_review': datetime.fromisoformat(topic['next_review']),
                        'created_at': datetime.fromisoformat(topic['created_at']),
                        'review_history': [
                            {**review, 'date': datetime.fromisoformat(review['date'])}
                            for review in topic['review_history']
                        ]
                    }
                    for topic_id, topic in state.items()
                }
                
                # Rebuild topic graph from loaded state
                for topic_id, topic in self.topics.items():
                    path = f"{topic['subject']}/{topic['topic']}"
                    self.topic_graph.add_topic_path(path, topic)
        except FileNotFoundError:
            self.topics = {}

    def visualize_progress(self):
        """Create and show visualization of learning progress"""
        viz = LearningVisualization(self)
        viz.plot_learning_progress()

def main():
    learning_system = EnhancedSpacedLearningSystem()
    learning_system.load_state()
    
    while True:
        print("\n=== SPACED LEARNING SYSTEM ===")
        print("1. Add new topic")
        print("2. Review topics")
        print("3. Show interval summary")
        print("4. Show progress visualization")
        print("5. Show topic hierarchy")
        print("6. Manage topic status")
        print("7. Save and exit")
        
        choice = input("\nChoose an option (1-7): ")
        
        if choice == '1':
            topic_path = input("Enter topic path (e.g., Mathematics/FuzzyLogic/Fundamentals): ")
            status = input("Enter initial status (active/disabled) [active]: ").lower() or 'active'
            if status in ['active', 'disabled']:
                topic_id = learning_system.add_topic_with_subtopics(topic_path, status)
                print(f"Added topic: {topic_id}")
                learning_system.print_topic_tree()
            
        elif choice == '2':
            topics_to_review = learning_system.get_topics_to_review()
            if not topics_to_review:
                print("No topics to review right now!")
                continue
            
            print("\nTopics to review:")
            for topic_id, topic in topics_to_review.items():
                print(f"\n{topic_id}")
                related = learning_system.get_related_topics(topic_id.replace(':', '/'))
                if related:
                    print("Related topics:", ", ".join(related))
                    
                difficulty = input("How was this topic? (easy/normal/hard): ").lower()
                while difficulty not in ['easy', 'normal', 'hard']:
                    difficulty = input("Please enter 'easy', 'normal', or 'hard': ").lower()
                
                next_review = learning_system.adjust_interval(topic_id, difficulty)
                print(f"Next review scheduled for: {next_review.strftime('%Y-%m-%d')}")
            
        elif choice == '3':
            learning_system.print_interval_summary()
            
        elif choice == '4':
            learning_system.visualize_progress()
            
        elif choice == '5':
            show_all = input("Show all topics (including disabled)? (y/n) [n]: ").lower() == 'y'
            learning_system.print_topic_tree(show_all)
            
        elif choice == '6':
            print("\nManage Topic Status:")
            print("1. Show all topics")
            print("2. Enable/disable topic")
            print("3. Mark topic as completed")
            
            status_choice = input("Choose an option (1-3): ")
            
            if status_choice == '1':
                learning_system.print_topic_tree(show_all=True)
            
            elif status_choice in ['2', '3']:
                topic_path = input("Enter topic path: ")
                if status_choice == '2':
                    new_status = input("Enter status (active/disabled): ")
                    if new_status in ['active', 'disabled']:
                        learning_system.set_topic_status(topic_path, new_status)
                else:
                    learning_system.set_topic_status(topic_path, 'completed')
                
                print("Topic status updated!")
                learning_system.print_topic_tree()
            
        elif choice == '7':
            learning_system.save_state()
            print("State saved. Goodbye!")
            break
            
        else:
            print("Invalid choice. Please try again.")

if __name__ == "__main__":
    main()