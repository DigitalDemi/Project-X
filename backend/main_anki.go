package main

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
)

type Card struct {
    CardID   int    `json:"card_id"`
    Lapses   int    `json:"lapses"`
    Ease     int    `json:"ease"`
    Interval int    `json:"interval"`
    Question string `json:"question"`
    Answer   string `json:"answer"`
    Advice   string `json:"advice"`
    DeckName string `json:"deck_name"`
}

func getWeakCards() ([]Card, error) {
    resp, err := http.Get("http://localhost:5000/weak_cards")
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return nil, err
    }

    var cards []Card
    if err := json.Unmarshal(body, &cards); err != nil {
        return nil, err
    }

    return cards, nil
}

func main() {
    cards, err := getWeakCards()
    if err != nil {
        fmt.Println("Error fetching weak cards:", err)
        return
    }

    for _, card := range cards {
        fmt.Printf("Card ID: %d, Lapses: %d, Ease: %d, Interval: %d\n", card.CardID, card.Lapses, card.Ease, card.Interval)
        fmt.Printf("Question: %s\n", card.Question)
        fmt.Printf("Answer: %s\n\n", card.Answer)
        fmt.Printf("Advice: %s\n\n", card.Advice) 
        fmt.Printf("Deck Name: %s\n\n", card.DeckName) 

    }
}

