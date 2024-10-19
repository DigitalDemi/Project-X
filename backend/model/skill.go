package model

import "time"

type Skill struct {
    ID          int           `json:"id"`            // Unique identifier for the skill (node)
    Name        string        `json:"name"`          // Name of the skill (e.g., "Data Structures")
    Description string        `json:"description"`   // A brief description of the skill
    Progress    float64       `json:"progress"`      // User-specific progress on the skill
    Topics      []*Topic      `json:"topics"`        // List of topics under this skill
    LastReviewed time.Time    `json:"last_reviewed"` // Last time this skill was reviewed
    NextReview   time.Time    `json:"next_review"`   // Next scheduled review time for this skill
}

