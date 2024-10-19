package model

import "time"

type StudySession struct {
    ID          int       `json:"id"`            // Unique identifier for the study session
    TopicID     int       `json:"topic_id"`      // The topic that was studied
    SkillID     int       `json:"skill_id"`      // The skill that the topic belongs to
    StudyDate   time.Time `json:"study_date"`    // Date and time of the study session
    Duration    int       `json:"duration"`      // Length of the study session in minutes
    Notes       string    `json:"notes"`         // User's notes or reflections during the session
    Progress    float64   `json:"progress"`      // How much progress was made during this session (0.0 to 1.0)
}
