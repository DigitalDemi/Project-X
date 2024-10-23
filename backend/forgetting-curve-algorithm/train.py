import requests
import torch
import torch.optim as optim
import torch.nn as nn
from ssp_mmc.model import GRUModel


import random

def augment_data(data, augment_factor=5):
    augmented_data = []
    for sample in data:
        for _ in range(augment_factor):
            performance = sample['performance'] + random.uniform(-0.05, 0.05)
            interval = sample['interval'] + random.uniform(-1, 1)
            halflife = interval * random.uniform(0.8, 1.2)  # Slightly adjust halflife too
            augmented_data.append({
                'performance': max(0, min(performance, 1)),  # Ensure performance stays in [0, 1]
                'interval': max(1, interval),  # Ensure interval is positive
                'halflife': max(1, halflife)  # Ensure halflife is positive
            })
    return augmented_data

def train_model_with_adjustments(model_path='model.pt', epochs=75):
    # Fetch Anki data from the service
    response = requests.get("http://localhost:5000/anki_data")
    anki_data = response.json()

    # Augment the data (if needed)
    augmented_data = augment_data(anki_data, augment_factor=5)

    # Create the model
    model = GRUModel(input_size=2, hidden_size=32)
    model.train()

    # Prepare the dataset
    X = torch.Tensor([[data['performance'], data['interval']] for data in augmented_data]).unsqueeze(1)
    y = torch.Tensor([[data['halflife']] for data in augmented_data])

    # DataLoader for batching
    dataset = torch.utils.data.TensorDataset(X, y)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    # Optimizer with lower learning rate and weight decay
    optimizer = optim.Adam(model.parameters(), lr=0.0001, weight_decay=1e-5)
    criterion = nn.MSELoss()

    # Training loop with early stopping
    best_loss = float('inf')
    patience = 5  # Stop if no improvement after 5 epochs
    patience_counter = 0

    for epoch in range(epochs):
        epoch_loss = 0
        for X_batch, y_batch in dataloader:
            optimizer.zero_grad()
            output = model(X_batch)
            loss = criterion(output, y_batch)
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()

        print(f"Epoch {epoch+1}/{epochs}, Loss: {epoch_loss}")

        # Early stopping logic
        if epoch_loss < best_loss:
            best_loss = epoch_loss
            patience_counter = 0  # Reset patience if there's an improvement
        else:
            patience_counter += 1  # Increment if no improvement
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch+1}")
                break

    # Save the trained model
    torch.save(model.state_dict(), model_path)
    print(f"Model trained and saved to {model_path}")

def train_model_with_augmentation(model_path='model.pt', epochs=1500):
    # Fetch Anki data from the service
    response = requests.get("http://localhost:5000/anki_data")
    anki_data = response.json()

    # Augment the data to simulate a larger dataset
    augmented_data = augment_data(anki_data, augment_factor=10)  # Generate 10x more data

    # Create the model
    model = GRUModel(input_size=2, hidden_size=32)
    model.train()

    # Prepare the dataset from augmented Anki data
    X = torch.Tensor([[data['performance'], data['interval']] for data in augmented_data]).unsqueeze(1)
    y = torch.Tensor([[data['halflife']] for data in augmented_data])

    # Create a DataLoader for batching
    dataset = torch.utils.data.TensorDataset(X, y)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    # Optimizer and loss function
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    # Training loop
    for epoch in range(epochs):
        epoch_loss = 0
        for X_batch, y_batch in dataloader:
            optimizer.zero_grad()
            output = model(X_batch)
            loss = criterion(output, y_batch)
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()

        print(f"Epoch {epoch+1}/{epochs}, Loss: {epoch_loss}")

    # Save the trained model
    torch.save(model.state_dict(), model_path)
    print(f"Model trained with augmented data and saved to {model_path}")



# Function to train the model using Anki data
def train_model_from_anki_data(model_path='model.pt', epochs=75):
    # Fetch Anki data from the service
    response = requests.get("http://localhost:5000/anki_data")
    anki_data = response.json()

    # Create the model
    model = GRUModel(input_size=2, hidden_size=32)
    model.train()

    # Prepare the dataset from Anki data
    X = torch.Tensor([[data['performance'], data['interval']] for data in anki_data]).unsqueeze(1)
    y = torch.Tensor([[data['halflife']] for data in anki_data])

    # Create a DataLoader for batching
    dataset = torch.utils.data.TensorDataset(X, y)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    # Optimizer and loss function
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    # Training loop
    for epoch in range(epochs):
        epoch_loss = 0
        for X_batch, y_batch in dataloader:
            optimizer.zero_grad()
            output = model(X_batch)
            loss = criterion(output, y_batch)
            loss.backward()
            optimizer.step()

            epoch_loss += loss.item()

        print(f"Epoch {epoch+1}/{epochs}, Loss: {epoch_loss}")

    # Save the trained model
    torch.save(model.state_dict(), model_path)
    print(f"Model trained and saved to {model_path}")

# Train the model using Anki data
# train_model_from_anki_data()

response = requests.get("http://localhost:5000/anki_data")
anki_data = response.json()
augmented_data = augment_data(anki_data)
train_model_with_augmentation()
# train_model_with_adjustments()
