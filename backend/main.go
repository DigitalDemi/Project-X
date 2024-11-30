package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "path/filepath"

    "github.com/neo4j/neo4j-go-driver/v5/neo4j"
)

type Note struct {
    Title   string `json:"title"`
    Content string `json:"content"`
}

type Relationship struct {
    Note1      string  `json:"note1"`
    Note2      string  `json:"note2"`
    Similarity float64 `json:"similarity"`
}

type RelationshipRequest struct {
    Notes []Note `json:"notes"`
}
const batchSize = 100

func createNoteNode(tx neo4j.Transaction, noteID string, content string) error {
    _, err := tx.Run(
        "MERGE (n:Note {id: $id}) SET n.content = $content",
        map[string]interface{}{
            "id":      noteID,
            "content": content,
        },
    )
    return err
}

// Extract notes and log the process
func extractNotes(vaultPath string) ([]Note, error) {
    log.Println("Starting to extract notes from Obsidian vault:", vaultPath)
    var notes []Note
    err := filepath.Walk(vaultPath, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if filepath.Ext(path) == ".md" {
            content, err := os.ReadFile(path)
            if err != nil {
                log.Printf("Failed to read note: %v", path)
                return err
            }
            notes = append(notes, Note{Title: info.Name(), Content: string(content)})
        }
        return nil
    })
    if err != nil {
        log.Printf("Error extracting notes: %v", err)
    } else {
        log.Printf("Successfully extracted %d notes", len(notes))
    }
    return notes, err
}

// Send notes to the BERT service and log the process
func sendNotesToBERTService(notes []Note) ([]Relationship, error) {
    log.Println("Sending notes to BERT service")
    url := "http://localhost:5000/relationships"
    requestBody, err := json.Marshal(RelationshipRequest{Notes: notes})
    if err != nil {
        log.Printf("Error marshaling request body: %v", err)
        return nil, err
    }

    resp, err := http.Post(url, "application/json", bytes.NewBuffer(requestBody))
    if err != nil {
        log.Printf("Error sending request to BERT service: %v", err)
        return nil, err
    }
    defer resp.Body.Close()

    var relationships []Relationship
    err = json.NewDecoder(resp.Body).Decode(&relationships)
    if err != nil {
        log.Printf("Error decoding response from BERT service: %v", err)
        return nil, err
    }
    log.Println("Successfully received relationships from BERT service")
    return relationships, nil
}

func createRelationship(tx neo4j.Transaction, note1ID string, note2ID string, similarity float64) error {
    _, err := tx.Run(
        "MATCH (a:Note {id: $note1ID}), (b:Note {id: $note2ID}) "+
            "CREATE (a)-[:RELATED_TO {similarity: $similarity}]->(b)",
        map[string]interface{}{
            "note1ID":    note1ID,
            "note2ID":    note2ID,
            "similarity": similarity,
        },
    )
    return err
}

func storeRelationshipsInNeo4j(relationships []Relationship) error {
    log.Println("Connecting to Neo4j...")
    driver, err := neo4j.NewDriver("bolt://localhost:7687", neo4j.BasicAuth("neo4j", "your_password", ""))
    if err != nil {
        log.Printf("Error connecting to Neo4j: %v", err)
        return err
    }
    defer driver.Close()

    session := driver.NewSession(neo4j.SessionConfig{})
    defer session.Close()

    tx, err := session.BeginTransaction()
    if err != nil {
        log.Printf("Error beginning Neo4j transaction: %v", err)
        return err
    }

    for i := 0; i < len(relationships); i += batchSize {
        end := i + batchSize
        if end > len(relationships) {
            end = len(relationships)
        }

        batch := relationships[i:end]
        for _, relation := range batch {
            err = createNoteNode(tx, relation.Note1, "")
            if err != nil {
                tx.Rollback()
                log.Printf("Error creating node for note1: %v", err)
                return err
            }
            err = createNoteNode(tx, relation.Note2, "")
            if err != nil {
                tx.Rollback()
                log.Printf("Error creating node for note2: %v", err)
                return err
            }
            err = createRelationship(tx, relation.Note1, relation.Note2, relation.Similarity)
            if err != nil {
                tx.Rollback()
                log.Printf("Error creating relationship: %v", err)
                return err
            }
        }

        log.Printf("Processed batch of %d relationships", len(batch))
    }

    log.Println("Committing transaction in Neo4j")
    return tx.Commit()
}


func main() {
	// 1. Parse notes from Obsidian
	vaultPath := "/home/demi/.Obsidian"
	notes, err := extractNotes(vaultPath)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	// 2. Send notes to BERT service to find relationships
	relationships, err := sendNotesToBERTService(notes)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	// 3. Store relationships in Neo4j
	err = storeRelationshipsInNeo4j(relationships)
	if err != nil {
		fmt.Println("Error storing relationships in Neo4j:", err)
	}
}

