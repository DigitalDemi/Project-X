import torch
import torch.nn as nn

# GRU model structure
class GRUModel(nn.Module):
    def __init__(self, input_size, hidden_size):
        super(GRUModel, self).__init__()
        self.gru = nn.GRU(input_size, hidden_size, batch_first=True)
        self.fc = nn.Linear(hidden_size, 1)

    def forward(self, x):
        out, _ = self.gru(x)
        return torch.exp(self.fc(out[:, -1, :]))  # Predict half-life

# Function to load the model
def load_model(model_path='model.pt'):
    model = GRUModel(input_size=2, hidden_size=32)
    model.load_state_dict(torch.load(model_path))
    model.eval()
    return model

