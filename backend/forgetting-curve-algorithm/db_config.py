# db_config.py
import sqlite3
from datetime import datetime
import json

def init_db():
    conn = sqlite3.connect('learning.db')
    c = conn.cursor()
    
    # Create tables
    c.executescript('''
        CREATE TABLE IF NOT EXISTS subjects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS subskills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (subject_id) REFERENCES subjects (id),
            UNIQUE(subject_id, name)
        );

        CREATE TABLE IF NOT EXISTS topics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subskill_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            last_reviewed TIMESTAMP,
            next_review TIMESTAMP,
            interval FLOAT DEFAULT 1,
            performance FLOAT DEFAULT 0.5,
            halflife FLOAT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (subskill_id) REFERENCES subskills (id),
            UNIQUE(subskill_id, name)
        );

        CREATE TABLE IF NOT EXISTS review_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            topic_id INTEGER NOT NULL,
            performance FLOAT NOT NULL,
            interval FLOAT NOT NULL,
            review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (topic_id) REFERENCES topics (id)
        );
    ''')
    
    conn.commit()
    conn.close()

class DatabaseManager:
    def __init__(self, db_name='learning.db'):
        self.db_name = db_name
        
    def get_connection(self):
        return sqlite3.connect(self.db_name)
    
    def add_subject(self, name):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO subjects (name) VALUES (?)', (name,))
            return cursor.lastrowid
            
    def add_subskill(self, subject_name, subskill_name):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO subskills (subject_id, name)
                SELECT id, ?
                FROM subjects
                WHERE name = ?
            ''', (subskill_name, subject_name))
            return cursor.lastrowid
            
    def add_topic(self, subject_name, subskill_name, topic_name):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO topics (subskill_id, name, last_reviewed)
                SELECT s.id, ?, CURRENT_TIMESTAMP
                FROM subskills s
                JOIN subjects sub ON s.subject_id = sub.id
                WHERE sub.name = ? AND s.name = ?
            ''', (topic_name, subject_name, subskill_name))
            return cursor.lastrowid
            
    def update_topic_review(self, topic_id, performance, interval, halflife):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            now = datetime.now()
            next_review = datetime.now()  # Calculate based on interval
            
            # Update topic
            cursor.execute('''
                UPDATE topics
                SET last_reviewed = ?,
                    next_review = ?,
                    interval = ?,
                    performance = ?,
                    halflife = ?
                WHERE id = ?
            ''', (now, next_review, interval, performance, halflife, topic_id))
            
            # Add to review history
            cursor.execute('''
                INSERT INTO review_history (topic_id, performance, interval)
                VALUES (?, ?, ?)
            ''', (topic_id, performance, interval))
            
    def get_learning_structure(self):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT 
                    sub.name as subject_name,
                    sk.name as subskill_name,
                    t.name as topic_name,
                    t.last_reviewed,
                    t.next_review,
                    t.interval,
                    t.performance,
                    t.halflife
                FROM subjects sub
                LEFT JOIN subskills sk ON sk.subject_id = sub.id
                LEFT JOIN topics t ON t.subskill_id = sk.id
                ORDER BY sub.name, sk.name, t.name
            ''')
            
            rows = cursor.fetchall()
            structure = {}
            
            for row in rows:
                subject_name, subskill_name, topic_name = row[0:3]
                if subject_name not in structure:
                    structure[subject_name] = {}
                
                if subskill_name:
                    if subskill_name not in structure[subject_name]:
                        structure[subject_name][subskill_name] = []
                    
                    if topic_name:
                        topic_data = {
                            'name': topic_name,
                            'last_reviewed': row[3],
                            'next_review': row[4],
                            'interval': row[5],
                            'performance': row[6],
                            'halflife': row[7]
                        }
                        structure[subject_name][subskill_name].append(topic_data)
            
            return structure
    def calculate_next_review(self, topic_data):
        """Helper function to calculate the next review date based on current performance"""
        try:
            skill = Skill(
                name=topic_data['name'],
                last_reviewed=parse_date(topic_data['last_reviewed']),
                interval=float(topic_data['interval']),
                performance=float(topic_data['performance'])
            )
            
            next_interval, halflife = ssp_mmc_plus_algorithm(skill)
            next_review = datetime.now() + timedelta(days=next_interval)
            
            return next_review.isoformat(), halflife
        except Exception as e:
            logger.error(f"Error calculating next review: {e}")
            # Return default values if calculation fails
            return (datetime.now() + timedelta(days=1)).isoformat(), 1.0

    def dict_factory(self, cursor, row):
        d = {}
        for idx, col in enumerate(cursor.description):
            d[col[0]] = row[idx]
        return d

    def get_db_dict(self):
        """Alternative connection that returns dictionaries"""
        conn = sqlite3.connect('learning.db')
        conn.row_factory = dict_factory
        return conn
    def add_topic(self, subject_name, subskill_name, topic_name):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO topics (subskill_id, name, last_reviewed)
                SELECT s.id, ?, CURRENT_TIMESTAMP
                FROM subskills s
                JOIN subjects sub ON s.subject_id = sub.id
                WHERE sub.name = ? AND s.name = ?
                RETURNING id, name, last_reviewed, interval, performance
            ''', (topic_name, subject_name, subskill_name))
            
            result = cursor.fetchone()
            if result:
                return {
                    'id': result[0],
                    'name': result[1],
                    'last_reviewed': result[2],
                    'interval': result[3],
                    'performance': result[4]
                }
            return None

    def get_learning_structure(self):
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT 
                    sub.name as subject_name,
                    sk.name as subskill_name,
                    t.id as topic_id,
                    t.name as topic_name,
                    t.last_reviewed,
                    t.next_review,
                    t.interval,
                    t.performance,
                    t.halflife
                FROM subjects sub
                LEFT JOIN subskills sk ON sk.subject_id = sub.id
                LEFT JOIN topics t ON t.subskill_id = sk.id
                ORDER BY sub.name, sk.name, t.name
            ''')
            
            rows = cursor.fetchall()
            structure = {}
            
            for row in rows:
                subject_name, subskill_name = row[0:2]
                if subject_name not in structure:
                    structure[subject_name] = {}
                
                if subskill_name:
                    if subskill_name not in structure[subject_name]:
                        structure[subject_name][subskill_name] = []
                    
                    if row[2]:  # if there's a topic
                        topic_data = {
                            'id': row[2],
                            'name': row[3],
                            'last_reviewed': row[4],
                            'next_review': row[5],
                            'interval': row[6],
                            'performance': row[7],
                            'halflife': row[8]
                        }
                        structure[subject_name][subskill_name].append(topic_data)
            
            return structure
