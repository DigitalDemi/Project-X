from flask import Flask, request, jsonify
import sqlite3
from flask_cors import CORS
from datetime import datetime, timedelta
import logging
from db_config import DatabaseManager, init_db
from ssp_mmc.algorithm import ssp_mmc_plus_algorithm
from ssp_mmc.retrain import retrain_model
from models.skill import Skill, SubSkill

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})

# In-memory storage for user data (for retraining)
user_data = []

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

        topic_id = data.get('topicId')
        if not topic_id:
            return jsonify({"error": "Topic ID is required"}), 400

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

        skill = Skill(
            name=topic_data[0],
            last_reviewed=parse_date(topic_data[1]) if topic_data[1] else datetime.now(),
            interval=float(topic_data[2]) if topic_data[2] else 1.0,
            performance=float(data.get('performance', topic_data[3]))
        )

        next_interval, halflife = ssp_mmc_plus_algorithm(skill)
        next_review = datetime.now() + timedelta(days=next_interval)

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

        cursor.execute('''
            INSERT INTO review_history (topic_id, performance, interval)
            VALUES (?, ?, ?)
        ''', (topic_id, data.get('performance'), next_interval))

        conn.commit()

        # Store data for retraining
        user_data.append({
            "performance": skill.performance,
            "interval": skill.interval,
            "halflife": halflife
        })

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

def parse_date(date_str):
    """Parse date string to datetime object, handling None values."""
    if not date_str:  # Handle None or empty string
        return None
        
    try:
        return datetime.fromisoformat(date_str.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        try:
            return datetime.strptime(date_str.split('T')[0], "%Y-%m-%d")
        except (ValueError, AttributeError):
            logger.warning(f"Could not parse date: {date_str}")
            return None

@app.route('/api/recommendations', methods=['GET'])
def get_recommendations():
    try:
        conn = db.get_connection()
        cursor = conn.cursor()
        current_time = datetime.now().isoformat()

        # Updated query with proper datetime handling
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
                t.next_review IS NULL
                OR datetime(t.next_review) <= datetime(?)
                OR (
                    COALESCE(t.performance, 0) < 0.7 
                    AND (
                        t.last_reviewed IS NULL 
                        OR julianday(?) - julianday(t.last_reviewed) >= 1
                    )
                )
            ORDER BY 
                CASE 
                    WHEN t.last_reviewed IS NULL THEN 1
                    WHEN COALESCE(t.performance, 0) < 0.6 THEN 2
                    ELSE 3
                END,
                COALESCE(datetime(t.next_review), datetime('now')),
                COALESCE(t.performance, 0) ASC
            LIMIT 5
        ''', (current_time, current_time))

        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()
        recommendations = []

        for row in rows:
            recommendation = dict(zip(columns, row))
            
            # Handle dates safely
            last_reviewed_date = parse_date(recommendation.get('last_reviewed'))
            next_review_date = parse_date(recommendation.get('next_review'))
            
            recommendations.append({
                "subject": recommendation['subject_name'],
                "subskill": recommendation['subskill_name'],
                "topic": recommendation['topic_name'],
                "lastReviewed": last_reviewed_date.isoformat() if last_reviewed_date else None,
                "nextReview": next_review_date.isoformat() if next_review_date else None,
                "interval": float(recommendation['interval']) if recommendation['interval'] is not None else 1.0,
                "performance": float(recommendation['performance']) if recommendation['performance'] is not None else 0.5,
                "halflife": float(recommendation['halflife']) if recommendation['halflife'] is not None else None,
                "topicId": recommendation['topic_id']
            })

        logger.debug(f"Found {len(recommendations)} recommendations")
        return jsonify(recommendations)

    except Exception as e:
        logger.error(f"Error getting recommendations: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500
    finally:
        if conn:
            conn.close()

# Maintain the global user_data list
user_data = []

@app.route('/api/retrain', methods=['POST'])
def retrain():
    try:
        if not user_data:
            return jsonify({"status": "No user data available for retraining"}), 400
            
        # Validate user data before retraining
        valid_data = []
        for data in user_data:
            if all(key in data for key in ['performance', 'interval', 'halflife']):
                try:
                    valid_data.append({
                        'performance': float(data['performance']),
                        'interval': float(data['interval']),
                        'halflife': float(data['halflife'])
                    })
                except (ValueError, TypeError):
                    continue

        if not valid_data:
            return jsonify({"status": "No valid data for retraining"}), 400

        retrain_model(valid_data)
        user_data.clear()  # Clear the user data after retraining
        
        return jsonify({"status": "Model retrained successfully"})
        
    except Exception as e:
        logger.error(f"Error during retraining: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(port=5003, debug=True)
