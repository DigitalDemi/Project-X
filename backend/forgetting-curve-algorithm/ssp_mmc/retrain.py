import torch
import torch.optim as optim
import torch.nn as nn
from ssp_mmc.model import GRUModel

# Function to retrain the model based on user data
def retrain_model(user_data, model_path='model.pt', epochs=50):
    # Load the existing model
    model = GRUModel(input_size=2, hidden_size=54)
    model.load_state_dict(torch.load(model_path))
    model.train()

    # Prepare the dataset from user data
    X = torch.Tensor([[data['performance'], data['interval']] for data in user_data]).unsqueeze(1)
    y = torch.Tensor([[data['halflife']] for data in user_data])

    # Create a DataLoader for batching
    dataset = torch.utils.data.TensorDataset(X, y)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=32, shuffle=True)

    # Optimizer and loss function
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    # Training loop
    for epoch in range(epochs):
        for X_batch, y_batch in dataloader:
            optimizer.zero_grad()
            output = model(X_batch)
            loss = criterion(output, y_batch)
            loss.backward()
            optimizer.step()

    # Save the retrained model
    torch.save(model.state_dict(), model_path)

