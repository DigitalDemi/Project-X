import torch
import torch.nn as nn
import torch.optim as optim

# GRU model structure
class GRUModel_n(nn.Module):
    def __init__(self, input_size, hidden_size):
        super(GRUModel_n, self).__init__()
        self.gru = nn.GRU(input_size, hidden_size, batch_first=True)
        self.fc = nn.Linear(hidden_size, 1)
        self.dropout = nn.Dropout(0.5)  # Added dropout layer for regularization

    def forward(self, x):
        out, _ = self.gru(x)
        out = self.dropout(out[:, -1, :])  # Apply dropout
        return torch.exp(self.fc(out))  # Predict half-life

# Function to load the model
def load_model(model_path='model.pt'):
    model = GRUModel_n(input_size=2, hidden_size=32)
    model.load_state_dict(torch.load(model_path))
    model.eval()
    return model

