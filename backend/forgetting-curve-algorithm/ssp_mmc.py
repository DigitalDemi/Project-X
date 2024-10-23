import torch
import math

# Function to load the PyTorch GRU model
def load_model():
    model = torch.load('model.pt')
    model.eval()
    return model

# Load the model (only once when this module is imported)
model = load_model()

# SSP-MMC-Plus algorithm to calculate the next review interval
def ssp_mmc_plus_algorithm(skill):
    input_tensor = torch.Tensor([[skill.performance, skill.interval]])
    halflife = model(input_tensor).item()  # Predict half-life using the GRU model

    # Calculate recall probability
    recall_probability = math.exp(-skill.interval / halflife)

    # Adjust next review interval based on performance and recall probability
    next_interval = skill.interval * (1 + skill.performance * 0.1)

    if skill.performance < 0.5 or recall_probability < 0.6:
        next_interval /= 1.5  # Shorten interval for poor performance
    else:
        next_interval *= 1.5  # Lengthen interval for good performance

    return next_interval, halflife

