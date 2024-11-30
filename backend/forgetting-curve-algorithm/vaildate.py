import torch
import torch.optim as optim
import torch.nn as nn
from ssp_mmc.model import GRUModel
from sklearn.model_selection import KFold
import requests

# Function to train the model
def train_model(train_data, epochs=75):
    # Create the model
    model = GRUModel(input_size=2, hidden_size=32)
    model.train()

    # Prepare the dataset from train data
    X_train = torch.Tensor([[data['performance'], data['interval']] for data in train_data]).unsqueeze(1)
    y_train = torch.Tensor([[data['halflife']] for data in train_data])

    # Create a DataLoader for batching
    dataset = torch.utils.data.TensorDataset(X_train, y_train)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    # Optimizer and loss function
    optimizer = optim.Adam(model.parameters(), lr=0.0001, weight_decay=1e-5)
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

    return model

# Function to evaluate the model on the test data
def evaluate_model(model, test_data):
    model.eval()

    X_test = torch.Tensor([[data['performance'], data['interval']] for data in test_data]).unsqueeze(1)
    y_test = torch.Tensor([[data['halflife']] for data in test_data])

    # Forward pass to get predictions
    with torch.no_grad():
        predictions = model(X_test)
        criterion = nn.MSELoss()
        test_loss = criterion(predictions, y_test).item()

    return test_loss

# Cross-validation function
def cross_validate_model(anki_data, k=5, epochs=75):
    kf = KFold(n_splits=k)
    fold = 1
    total_test_loss = 0

    for train_index, test_index in kf.split(anki_data):
        # Split data into train and test sets for this fold
        train_data = [anki_data[i] for i in train_index]
        test_data = [anki_data[i] for i in test_index]

        print(f"Training on fold {fold}...")

        # Train the model on the current fold's training data
        model = train_model(train_data, epochs=epochs)

        # Evaluate the model on the current fold's test data
        test_loss = evaluate_model(model, test_data)
        total_test_loss += test_loss

        print(f"Fold {fold} test loss: {test_loss:.4f}")
        fold += 1

    # Average test loss across all folds
    average_test_loss = total_test_loss / k
    print(f"Average test loss after {k}-fold cross-validation: {average_test_loss:.4f}")

# Fetch the Anki data from the service
response = requests.get("http://localhost:5000/anki_data")
anki_data = response.json()

# Perform k-fold cross-validation
cross_validate_model(anki_data, k=5, epochs=75)

