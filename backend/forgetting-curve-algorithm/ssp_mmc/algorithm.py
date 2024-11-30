import torch
import math
import logging
from ssp_mmc.model import load_model

# Load the model (only once when this module is imported)
model = load_model()

# SSP-MMC-Plus algorithm to calculate the next review interval
def ssp_mmc_plus_algorithm(skill):
    try:
        logging.debug(f"Running SSP-MMC-Plus algorithm for skill: {skill.name}")
        
        # Convert `performance` and `interval` to tensors if needed
        performance_tensor = torch.tensor(skill.performance).float().unsqueeze(0)
        interval_tensor = torch.tensor(skill.interval).float().unsqueeze(0)
        
        # Stack and reshape the input to have shape [1, 1, 2] for GRU compatibility
        input_tensor = torch.stack([performance_tensor, interval_tensor], dim=1).unsqueeze(0)  # Shape: [1, 1, 2]

        # Log input tensor details
        logging.debug(f"Input tensor shape: {input_tensor.shape}, values: {input_tensor}")

        # Pass `input_tensor` to the model
        halflife = model(input_tensor).item()  # Predict half-life
        logging.debug(f"Predicted halflife: {halflife}")

        # Calculate recall probability
        recall_probability = math.exp(-skill.interval / halflife)
        logging.debug(f"Recall probability: {recall_probability}")

        # Adjust next review interval based on performance and recall probability
        next_interval = skill.interval * (1 + skill.performance * 0.1)

        if skill.performance < 0.5 or recall_probability < 0.6:
            next_interval /= 1.5  # Shorten interval for poor performance
            logging.debug("Shortening interval due to low performance or recall probability.")
        else:
            next_interval *= 1.5  # Lengthen interval for good performance
            logging.debug("Lengthening interval due to good performance or recall probability.")

        logging.debug(f"Calculated next review interval: {next_interval}")
        return next_interval, halflife

    except Exception as e:
        logging.error(f"Error in SSP-MMC-Plus algorithm: {e}")
        raise

