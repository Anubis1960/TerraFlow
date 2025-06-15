import os
import pickle as pkl
import numpy as np
import pandas as pd
import cv2
from tensorflow.keras.models import load_model as load_keras_model

INT_TO_CLASS = {
    0: 'Fungal',
    1: 'Bacterial',
    2: 'Viral',
    3: 'Pest',
    4: 'Disorder',
    5: 'Healthy',
    6: 'Unknown'
}


def load_model(path: str):
    """
    Load the model from the file.
    :param path: str: Path to the model file.
    :return: Loaded model.
    """
    try:
        with open(path, 'rb') as file:
            model = pkl.load(file)
    except FileNotFoundError:
        raise FileNotFoundError(f"Model file not found at {path}. Please check the path.")
    return model


def predict_water(data: pd.DataFrame) -> list[int]:
    """
    predict the output using the model.

    :param data: pd.DataFrame: DataFrame containing the input data.
    :return: list[int]: List of predictions.
    """
    # Base directory of your project (e.g., where src/ lives)
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # Now build the correct path
    path = os.path.join(PROJECT_ROOT, 'utils', 'model', 'rf_model_Amritpal.pkl')
    model = load_model(path)
    prediction = model.predict(data)
    return prediction


def prepare_image(image: cv2.Mat, img_size=(224, 224)) -> np.ndarray:
    """
    Preprocess the image for prediction.
    This function should be customized based on the model's requirements.

    :param image: cv2.Mat: Input image in OpenCV format.
    :param img_size: tuple: Desired size for the image (default is (224, 224)).
    :return: np.ndarray: Preprocessed image ready for prediction.
    """

    # Ensure correct resizing to the specified size
    resized_image = cv2.resize(image, img_size, interpolation=cv2.INTER_AREA)

    # Normalize pixel values
    normalized_image = resized_image.astype('float32') / 255.0

    normalized_image = np.expand_dims(normalized_image, axis=0)

    return normalized_image


def predict_disease(img: cv2.Mat) -> dict[str, str | float]:
    """
    predict the disease from the image using the model.

    :param img: cv2.Mat: Input image in OpenCV format.
    :return: dict[str, str | float]: Dictionary containing the prediction and confidence score.
    """
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    print(f"Project root directory: {PROJECT_ROOT}")

    path = os.path.join(PROJECT_ROOT, 'utils', 'model', '128_resnetv50_1000_224_7.keras')
    model = load_keras_model(path)

    print(f"Model loaded from {path}")

    processed_img = prepare_image(img, img_size=(224, 224))
    prediction = model.predict(processed_img)
    max_index = np.argmax(prediction, axis=1)[0]
    res = {
        "prediction": INT_TO_CLASS[max_index] if max_index in INT_TO_CLASS else "Unknown",
        "confidence": float(prediction[0][max_index])
    }
    return res
