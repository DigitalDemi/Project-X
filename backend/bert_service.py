from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import logging
from flask import Flask, request, jsonify

# Load BERT model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Configure logging
logging.basicConfig(level=logging.INFO)

app = Flask(__name__)

@app.route('/relationships', methods=['POST'])
def create_relationships():
    data = request.json
    notes = data['notes']

    logging.info("Received %d notes for relationship calculation", len(notes))

    # Encode notes to embeddings
    note_embeddings = [model.encode(note['content']) for note in notes]

    relationships = []
    for i, note1 in enumerate(notes):
        for j, note2 in enumerate(notes):
            if i != j:
                # Calculate cosine similarity between embeddings
                similarity = cosine_similarity([note_embeddings[i]], [note_embeddings[j]])[0][0]
                relationships.append({
                    "note1": note1['title'],
                    "note2": note2['title'],
                    "similarity": float(similarity)
                })

    logging.info("Generated %d relationships", len(relationships))

    return jsonify(relationships)

if __name__ == '__main__':
    logging.info("Starting Flask app with BERT-based relationship service")
    app.run(debug=True)

