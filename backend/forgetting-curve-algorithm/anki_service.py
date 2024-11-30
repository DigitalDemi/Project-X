import os
import requests
from flask import Flask, jsonify
from anki.collection import Collection

app = Flask(__name__)

ANKI_COLLECTION_PATH = os.path.expanduser("/home/demi/.local/share/Anki2/User 1/collection.anki2")

# Load the Anki collection
def load_collection():
    return Collection(ANKI_COLLECTION_PATH)

# Remove "Everything" from deck names
def clean_deck_name(deck_name):
    if deck_name.startswith("Everything::"):
        return deck_name.replace("Everything::", "")
    return deck_name

# Track seen decks using a set to avoid processing the same deck multiple times
seen_decks = set()

# Aggregate ease and interval (average) and sum lapses
def aggregate_card_stats(cards):
    total_lapses = 0
    total_ease = 0
    total_interval = 0
    num_cards = len(cards)

    for card in cards:
        total_lapses += card['lapses']
        total_ease += card['ease']
        total_interval += card['interval']

    return {
        "lapses": total_lapses,  # Sum lapses
        "ease": total_ease / num_cards,  # Average ease
        "interval": total_interval / num_cards  # Average interval
    }

@app.route('/anki_data', methods=['GET'])
def get_anki_data():
    col = load_collection()
    anki_data = []

    for cid in col.find_cards("is:due"):
        card = col.get_card(cid)
        lapses = card.lapses
        ease = card.factor / 1000.0  # Normalized ease (factor is in thousands)
        interval = card.ivl  # Interval is already in days

        # We can estimate halflife as interval * (0.8 to 1.2) as an initial assumption
        halflife = interval * (0.8 + (lapses * 0.1))

        anki_data.append({
            'performance': ease,
            'interval': interval,
            'halflife': halflife
        })

    col.close()
    return jsonify(anki_data)


# Flask route to get weak cards and calculate their next review
@app.route('/anki_weak_cards', methods=['GET'])
def get_weak_cards_with_review():
    col = load_collection()
    weak_cards = []

    for cid in col.find_cards("is:due"):
        card = col.get_card(cid)
        lapses = card.lapses
        ease = card.factor
        interval = card.ivl

        # Clean the deck name by removing "Everything::"
        deck_id = card.did
        deck_name = clean_deck_name(col.decks.name(deck_id))

        # Skip if we've already processed this deck
        if deck_name in seen_decks:
            continue
        seen_decks.add(deck_name)

        # Get all cards in the same deck
        deck_cards = [col.get_card(card_id) for card_id in col.find_cards(f"deck:{deck_name}")]
        aggregated_stats = aggregate_card_stats(deck_cards)

        # Send the aggregated stats to the SSP-MMC-Plus service for next review calculation
        ssp_response = requests.post(
            "http://localhost:5001/calculate_review",
            json={
                "ease": aggregated_stats['ease'],
                "interval": aggregated_stats['interval'],
                "lapses": aggregated_stats['lapses']
            }
        )
        ssp_data = ssp_response.json()
        next_review = ssp_data['next_review_interval']
        halflife = ssp_data['halflife']

        # Append weak cards data with review time and halflife
        note = card.note()
        weak_cards.append({
            "card_id": cid,
            "lapses": lapses,
            "ease": ease,
            "interval": interval,
            "question": note.fields[0],
            "answer": note.fields[1],
            "deck_name": deck_name,
            "next_review": next_review,
            "halflife": halflife
        })

    col.close()
    return jsonify(weak_cards)

if __name__ == '__main__':
    app.run(port=5000)

