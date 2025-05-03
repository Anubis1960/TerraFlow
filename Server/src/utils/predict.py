import pickle as pkl
import pandas as pd


def load_model(path: str):
    """
    Load the model from the pickle file.
    """
    with open(path, 'rb') as file:
        model = pkl.load(file)
    return model


def predict_water(data: pd.DataFrame) -> list[int]:
    """
    Predict the output using the model.
    """
    model = load_model('model/random_forest.pkl')
    prediction = model.predict(data)
    return prediction
