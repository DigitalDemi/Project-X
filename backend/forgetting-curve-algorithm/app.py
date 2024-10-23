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
    data = request.json
    skill_name = data['name']
    last_reviewed = datetime.strptime(data['last_reviewed'], "%Y-%m-%d")
    interval = data['interval']
    performance = data['performance']

    # Create a Skill object (no mock)
    subskills_data = data.get('sub_skills', [])
    sub_skills = [SubSkill(sub['name'], datetime.strptime(sub['last_reviewed'], "%Y-%m-%d"), sub['interval'], sub['performance']) for sub in subskills_data]
    skill = Skill(skill_name, last_reviewed, interval, performance, sub_skills)

    # Calculate next review using SSP-MMC-Plus algorithm
    next_interval, halflife = ssp_mmc_plus_algorithm(skill)
    skill.update_review(last_reviewed + timedelta(days=next_interval), halflife)

    # Adjust sub-skills based on main skill performance
    skill.adjust_subskills()
    for sub_skill in skill.sub_skills:
        sub_skill_interval, sub_skill_halflife = ssp_mmc_plus_algorithm(sub_skill)
        sub_skill.update_review(last_reviewed + timedelta(days=sub_skill_interval), sub_skill_halflife)

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

    # Return updated review times for both main skill and sub-skills
    return jsonify({
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

@app.route('/retrain', methods=['POST'])
def retrain():
    if user_data:
        retrain_model(user_data)
        user_data.clear()  # Clear the user data after retraining
        return jsonify({"status": "Model retrained successfully"})
    else:
        return jsonify({"status": "No user data available for retraining"}), 400

if __name__ == '__main__':
    app.run(port=5000, debug=True)

