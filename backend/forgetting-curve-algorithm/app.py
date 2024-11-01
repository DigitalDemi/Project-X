from flask import Flask, request, jsonify
import sqlite3
from flask_cors import CORS
from datetime import datetime, timedelta
import logging
from db_config import DatabaseManager, init_db
from ssp_mmc.algorithm import ssp_mmc_plus_algorithm
from models.skill import Skill, SubSkill

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response


# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize database
init_db()
db = DatabaseManager()

def parse_date(date_str):
    """Parse date string to datetime object."""
    try:
        # Try ISO format first
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except ValueError:
        try:
            # Try simple date format
            return datetime.strptime(date_str.split('T')[0], "%Y-%m-%d")
        except ValueError:
            # Default to current date if parsing fails
            logger.warning(f"Could not parse date: {date_str}, using current date")
            return datetime.now()

@app.route('/api/subjects', methods=['GET', 'POST'])
def handle_subjects():
    if request.method == 'POST':
        data = request.json
        subject_name = data.get('name')
        if subject_name:
            try:
                db.add_subject(subject_name)
                return jsonify({"message": f"Subject '{subject_name}' added successfully"})
            except sqlite3.IntegrityError:
                return jsonify({"error": "Subject already exists"}), 400
        return jsonify({"error": "Subject name is required"}), 400
    else:
        structure = db.get_learning_structure()
        return jsonify(structure)

@app.route('/api/subskills', methods=['POST'])
def add_subskill():
    data = request.json
    subject = data.get('subject')
    name = data.get('name')
    
    if subject and name:
        try:
            db.add_subskill(subject, name)
            return jsonify({"message": f"Subskill '{name}' added successfully"})
        except sqlite3.IntegrityError:
            return jsonify({"error": "Subskill already exists"}), 400
    return jsonify({"error": "Subject and subskill names are required"}), 400

@app.route('/api/topics', methods=['POST'])
def add_topic():
    data = request.json
    subject = data.get('subject')
    subskill = data.get('subskill')
    name = data.get('name')
    
    if all([subject, subskill, name]):
        try:
            db.add_topic(subject, subskill, name)
            return jsonify({"message": f"Topic '{name}' added successfully"})
        except sqlite3.IntegrityError:
            return jsonify({"error": "Topic already exists"}), 400
    return jsonify({"error": "Subject, subskill, and topic names are required"}), 400


@app.route('/api/schedule', methods=['POST'])
def schedule_review():
    conn = None
    try:
        data = request.json
        logger.debug(f"Received schedule request: {data}")

        # Ensure we have a topic ID
        topic_id = data.get('topicId')
        if not topic_id:
            return jsonify({"error": "Topic ID is required"}), 400

        # Get current topic data
        conn = db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT name, last_reviewed, interval, performance
            FROM topics 
            WHERE id = ?
        ''', (topic_id,))
        
        topic_data = cursor.fetchone()
        if not topic_data:
            return jsonify({"error": "Topic not found"}), 404

        # Create Skill object with current data
        skill = Skill(
            name=topic_data[0],
            last_reviewed=parse_date(topic_data[1]) if topic_data[1] else datetime.now(),
            interval=float(topic_data[2]) if topic_data[2] else 1.0,
            performance=float(data.get('performance', topic_data[3]))
        )

        # Calculate next review using SSP-MMC-Plus algorithm
        next_interval, halflife = ssp_mmc_plus_algorithm(skill)
        next_review = datetime.now() + timedelta(days=next_interval)

        # Update the topic with new data
        cursor.execute('''
            UPDATE topics
            SET last_reviewed = ?,
                next_review = ?,
                interval = ?,
                performance = ?,
                halflife = ?
            WHERE id = ?
        ''', (
            datetime.now().isoformat(),
            next_review.isoformat(),
            next_interval,
            data.get('performance'),
            halflife,
            topic_id
        ))

        # Add to review history
        cursor.execute('''
            INSERT INTO review_history (topic_id, performance, interval)
            VALUES (?, ?, ?)
        ''', (topic_id, data.get('performance'), next_interval))

        conn.commit()

        return jsonify({
            "topic_id": topic_id,
            "next_review": next_review.strftime("%Y-%m-%d"),
            "halflife": halflife,
            "performance": data.get('performance')
        })

    except Exception as e:
        logger.error(f"Error during schedule processing: {e}")
        if conn:
            conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()



@app.route('/api/recommendations', methods=['GET'])
def get_recommendations():
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        current_time = datetime.now()

        # Get topics that are due for review with more sophisticated criteria
        cursor.execute('''
            SELECT 
                sub.name as subject_name,
                sk.name as subskill_name,
                t.name as topic_name,
                t.last_reviewed,
                t.next_review,
                t.interval,
                t.performance,
                t.halflife,
                t.id as topic_id
            FROM topics t
            JOIN subskills sk ON t.subskill_id = sk.id
            JOIN subjects sub ON sk.subject_id = sub.id
            WHERE 
                (
                    -- Topics that have never been reviewed
                    t.next_review IS NULL
                    OR 
                    -- Topics that are due for review
                    datetime(t.next_review) <= datetime(?)
                    OR
                    -- Topics with low performance that haven't been reviewed recently
                    (t.performance < 0.7 AND (
                        t.last_reviewed IS NULL OR 
                        julianday(?) - julianday(t.last_reviewed) >= 1
                    ))
                )
                -- Exclude topics reviewed in the last 12 hours
                AND (t.last_reviewed IS NULL OR 
                    julianday(?) - julianday(t.last_reviewed) >= 0.5)
            ORDER BY 
                CASE 
                    WHEN t.last_reviewed IS NULL THEN 1  -- Highest priority for never reviewed
                    WHEN t.performance < 0.6 THEN 2      -- Next priority for low performance
                    ELSE 3                               -- Normal priority
                END,
                datetime(t.next_review),                 -- Earlier due dates first
                t.performance ASC                        -- Lower performance first
            LIMIT 5                                      -- Limit to 5 recommendations at a time
        ''', (current_time, current_time, current_time))

        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()
        recommendations = []

        for row in rows:
            recommendation = dict(zip(columns, row))
            recommendations.append({
                "subject": recommendation['subject_name'],
                "subskill": recommendation['subskill_name'],
                "topic": recommendation['topic_name'],
                "lastReviewed": recommendation['last_reviewed'],
                "nextReview": recommendation['next_review'],
                "interval": float(recommendation['interval']) if recommendation['interval'] else 1.0,
                "performance": float(recommendation['performance']) if recommendation['performance'] else 0.5,
                "halflife": float(recommendation['halflife']) if recommendation['halflife'] else None,
                "topicId": recommendation['topic_id']
            })

        return jsonify(recommendations)

    except Exception as e:
        logger.error(f"Error getting recommendations: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


if __name__ == '__main__':
    app.run(port=5000, debug=True)
