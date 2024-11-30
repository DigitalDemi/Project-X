import os
from flask import Flask, jsonify
from anki.collection import Collection

app = Flask(__name__)

ANKI_COLLECTION_PATH = os.path.expanduser("/home/user/.local/share/Anki2/User 1/collection.anki2")

def load_collection():
    return Collection(ANKI_COLLECTION_PATH)

# Function to generate advice based on card stats
def generate_advice(lapses, ease, interval):
    if lapses > 5 and ease < 2000:
        return "Urgent: You should restudy this topic immediately due to frequent mistakes."
    elif lapses > 3 and ease < 2500:
        return "Review Soon: This card has moderate difficulty and frequent errors. Restudy soon."
    elif ease < 2500:
        return "Consider Improvement: This topic seems difficult. Try reviewing it more frequently."
    else:
        return "General Advice: Keep an eye on this card, but it seems manageable."

@app.route('/weak_cards', methods=['GET'])
def get_weak_cards():
    col = load_collection()

    weak_cards = []
    for cid in col.find_cards("is:due"):
        card = col.get_card(cid)
        lapses = card.lapses
        ease = card.factor
        interval = card.ivl

        deck_id = card.did
        deck_name = col.decks.name(deck_id)

        advice = generate_advice(lapses, ease, interval)

        # Prioritize cards with more lapses and lower ease
        if lapses > 3 or ease < 2500:
            note = card.note()
            weak_cards.append({
                "card_id": cid,
                "lapses": lapses,
                "ease": ease,
                "interval": interval,
                "question": note.fields[0],
                "answer": note.fields[1],
                "advice": advice,
                "deck_name": deck_name
            })

    col.close()
    return jsonify(weak_cards)

if __name__ == '__main__':
    app.run(port=5000)

