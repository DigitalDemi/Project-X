package model

import "time"

type Topic struct {
    ID            int         `json:"id"`            // Unique identifier for the topic
    SkillID       int         `json:"skill_id"`      // The skill this topic belongs to
    Name          string      `json:"name"`          // Name of the topic (e.g., "Binary Trees")
    Content       string      `json:"content"`       // Content related to the topic, e.g., notes or learning material
    Progress      float64     `json:"progress"`      // User-specific progress on the topic (0.0 to 1.0)
    LastReviewed  time.Time   `json:"last_reviewed"` // Last time this topic was reviewed
    NextReview    time.Time   `json:"next_review"`   // Next scheduled review time for this topic
    StudyHistory  []*StudySession `json:"study_history"` // List of study sessions related to this topic
}

