import logging
from flask import Flask, request, jsonify
from ssp_mmc.algorithm import ssp_mmc_plus_algorithm
from ssp_mmc.retrain import retrain_model
from models.skill import Skill, SubSkill
from datetime import datetime, timedelta

app = Flask(__name__)

# In-memory storage for user data (replace with a database if needed)
user_data = []

@app.route('/schedule', methods=['POST'])
def schedule_review():
    try:
        logging.debug("Received schedule request")
        data = request.json
        logging.debug(f"Input data: {data}")

        skill_name = data['name']
        last_reviewed = datetime.strptime(data['last_reviewed'], "%Y-%m-%d")
        interval = data['interval']
        performance = data['performance']

        # Create a Skill object (no mock)
        subskills_data = data.get('sub_skills', [])
        sub_skills = [SubSkill(sub['name'], datetime.strptime(sub['last_reviewed'], "%Y-%m-%d"), sub['interval'], sub['performance']) for sub in subskills_data]
        skill = Skill(skill_name, last_reviewed, interval, performance, sub_skills)

        # Logging the created skill and subskills
        logging.debug(f"Created Skill object: {skill_name}, Last reviewed: {last_reviewed}, Interval: {interval}, Performance: {performance}")
        for sub_skill in sub_skills:
            logging.debug(f"SubSkill: {sub_skill.name}, Last reviewed: {sub_skill.last_reviewed}, Interval: {sub_skill.interval}, Performance: {sub_skill.performance}")

        # Calculate next review using SSP-MMC-Plus algorithm
        next_interval, halflife = ssp_mmc_plus_algorithm(skill)
        skill.update_review(last_reviewed + timedelta(days=next_interval), halflife)

        logging.debug(f"Main skill next review in {next_interval} days with halflife {halflife}")

        # Adjust sub-skills based on main skill performance
        skill.adjust_subskills()
        for sub_skill in skill.sub_skills:
            sub_skill_interval, sub_skill_halflife = ssp_mmc_plus_algorithm(sub_skill)
            sub_skill.update_review(last_reviewed + timedelta(days=sub_skill_interval), sub_skill_halflife)
            logging.debug(f"SubSkill {sub_skill.name} next review in {sub_skill_interval} days with halflife {sub_skill_halflife}")

        # Log user data for future model retraining
        user_data.append({
            "performance": skill.performance,
            "interval": skill.interval,
            "halflife": halflife
        })
        for sub_skill in skill.sub_skills:
            user_data.append({
                "performance": sub_skill.performance,
                "interval": sub_skill.interval,
                "halflife": sub_skill.halflife
            })
        logging.debug(f"User data for retraining: {user_data}")

        # Return updated review times for both main skill and sub-skills
        response = jsonify({
            "next_review_main_skill": skill.next_review.strftime("%Y-%m-%d"),
            "halflife_main_skill": halflife,
            "sub_skills": [
                {
                    "name": sub_skill.name,
                    "next_review": sub_skill.next_review.strftime("%Y-%m-%d"),
                    "halflife": sub_skill.halflife
                }
                for sub_skill in skill.sub_skills
            ]
        })

        logging.debug(f"Response: {response.get_json()}")
        return response

    except Exception as e:
        logging.error(f"Error during schedule processing: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/retrain', methods=['POST'])
def retrain():
    if user_data:
        retrain_model(user_data)
        user_data.clear()  # Clear the user data after retraining
        return jsonify({"status": "Model retrained successfully"})
    else:
        return jsonify({"status": "No user data available for retraining"}), 400

if __name__ == '__main__':
    app.run(port=5003, debug=True)

