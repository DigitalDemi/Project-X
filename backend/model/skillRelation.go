package model


type SkillRelation struct {
    SourceSkillID int     `json:"source_skill_id"`   // The skill from which the relation starts
    TargetSkillID int     `json:"target_skill_id"`   // The skill to which the relation points
    RelationType  string  `json:"relation_type"`     // Type of relation ("Related To", "Prerequisite", etc.)
}

