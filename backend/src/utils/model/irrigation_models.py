import pickle as pkl
import pandas as pd
import tensorflow as tf
from lightgbm import LGBMClassifier
from scipy.interpolate import interp1d
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from xgboost import XGBClassifier

from src.utils.model.irrigation_loader import DataLoader


class Model:
    """
    Generic model class for training and evaluating a classifier model.
    """

    def __init__(self, data_loader: DataLoader):
        """
        Initialize the model with the provided data loader.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        """
        self.data_loader = data_loader
        self.model = None
        self.accuracy = 0
        self.confusion_matrix = None

    def train_model(self) -> float:
        """
        Train the classifier model.

        :return: float, accuracy of the trained model.
        """
        if self.model is None:
            raise NotImplementedError("Model not implemented.")
        x_train, x_test, y_train, y_test = self.data_loader.prepare_data()

        self.model.fit(x_train, y_train)

        y_pred = self.model.predict(x_test)
        self.accuracy = accuracy_score(y_test, y_pred)

        self.confusion_matrix = pd.crosstab(y_test, y_pred, rownames=['Actual'], colnames=['Predicted'], margins=True)

        return self.accuracy

    def show_params(self):
        """
        Display model params.
        """
        if self.model is None:
            raise NotImplementedError("Model not implemented.")
        print(f'{self.__class__.__name__} Model Accuracy: {self.accuracy * 100:.2f}%')

        print(f'Confusion Matrix:\n{self.confusion_matrix}')

    def save_model(self, filename: str) -> None:
        """
        Save the trained model.

        :param filename: str, the name of the file to save the model.
        :return: None
        """
        file = open(filename, 'wb')
        pkl.dump(self.model, file)

    def predict(self, data) -> list:
        """
        Predict the class of the given data.

        :param data: array-like, input data for prediction.
        :return: list, predicted classes.
        """
        if self.model is None:
            raise NotImplementedError("Model not implemented.")
        return self.model.predict(data)


class KNNModel(Model):
    """
    KNNModel class for training and evaluating a K-Nearest Neighbors classifier.
    """

    def __init__(self, data_loader: DataLoader, **kwargs):
        """
        Initialize the KNN model with the provided data loader and parameters.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for KNN model initialization.
        :return: None
        """
        super().__init__(data_loader)
        self.model = KNeighborsClassifier(**kwargs)


class RandomForestModel(Model):
    """
    RandomForestModel class for training and evaluating a Random Forest classifier.
    """

    def __init__(self, data_loader: DataLoader, **kwargs):
        """
        Initialize the Random Forest model with the provided data loader and parameters.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for Random Forest model initialization.
        :return: None
        """
        super().__init__(data_loader)
        self.model = RandomForestClassifier(**kwargs)


class XGBoostModel(Model):
    """
    XGBoostModel class for training and evaluating a XGBoost classifier.
    """

    def __init__(self, data_loader: DataLoader, **kwargs):
        """
        Initialize the XGBoost model with the provided data loader and parameters.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for XGBoost model initialization.
        :return: None
        """
        super().__init__(data_loader)
        self.model = XGBClassifier(**kwargs)


class LGBMModel(Model):
    """
    LGBMModel class for training and evaluating a LightGBM classifier.
    """

    def __init__(self, data_loader: DataLoader, **kwargs):
        """
        Initialize the LightGBM model with the provided data loader and parameters.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for LightGBM model initialization.
        :return: None
        """
        super().__init__(data_loader)
        self.model = LGBMClassifier(**kwargs)


class NNModel(Model):
    """
    NNModel class for training and evaluating a Neural Network classifier.
    """

    def __init__(self, data_loader: DataLoader, **kwargs):
        """
        Initialize the Neural Network model with the provided data loader and parameters.

        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for model initialization, such as epochs and batch_size.
        :return: None
        """
        super().__init__(data_loader)
        self.model = tf.keras.Sequential([
            tf.keras.layers.Dense(64, activation='relu', input_shape=(len(columns) - 1,)),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dense(1, activation='sigmoid')
        ])
        self.model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])

    def train_model(self, **kwargs):
        """
        Train the neural network model and evaluate its accuracy.

        :param kwargs: additional keyword arguments for training, such as epochs and batch_size.
        :return: float, accuracy of the trained model.
        """
        x_train, x_temp, y_train, y_temp = self.data_loader.prepare_data(split_ratio=0.3)
        x_validation, x_test, y_validation, y_test = train_test_split(x_temp, y_temp, test_size=0.5, random_state=42)
        self.model.fit(
            x_train,
            y_train,
            validation_data=(x_validation, y_validation),
            epochs=kwargs.get('epochs', 10),
            batch_size=kwargs.get('batch_size', 32),
            callbacks=kwargs.get('callbacks', []),
            verbose=0
        )

        _, self.accuracy = self.model.evaluate(x_test, y_test, verbose=0)
        y_pred = self.model.predict(x_test)
        self.confusion_matrix = pd.crosstab(
            y_test,
            (y_pred > 0.5).astype(int).flatten(),
            rownames=['Actual'],
            colnames=['Predicted'],
            margins=True
        )
        return self.accuracy


class Factory:
    """
    Factory class for creating a model.
    """

    @staticmethod
    def create_model(model_name: str, data_loader: DataLoader, **kwargs):
        """
        Create a model.

        :param model_name: str, the name of the model to create.
        :param data_loader: DataLoader, the DataLoader instance to use for loading data.
        :param kwargs: additional keyword arguments for model initialization.
        :return: Model instance.
        """
        if model_name == 'knn':
            return KNNModel(data_loader, **kwargs)
        if model_name == 'random_forest':
            return RandomForestModel(data_loader, **kwargs)
        if model_name == 'xgboost':
            return XGBoostModel(data_loader, **kwargs)
        if model_name == 'lightgbm':
            return LGBMModel(data_loader, **kwargs)
        if model_name == 'neural_network':
            return NNModel(data_loader, **kwargs)
        raise NotImplementedError(f"{model_name} model not implemented.")

    @staticmethod
    def load_model_from_file(filename: str):
        """
        Load a model from a file.

        :param filename: str, the name of the file to load the model from.
        :return: Loaded model instance.
        """
        return pkl.load(open(filename, 'rb'))


# Example usage:
if __name__ == "__main__":
    # Example usage of the DataLoader and Model classes
    path = "TARP.csv"

    df = pd.read_csv(path)
    try:
        df['Status'] = df['Status'].apply(lambda x: 1 if x == "ON" or x == 1 else 0)
    except KeyError:
        print("Column 'Status' not found in the DataFrame. Please check the CSV file.")

    df.rename(columns={'Air temperature (C)': 'Temperature', 'Air humidity (%)': 'Air Humidity'}, inplace=True)
    df.rename(columns={'Status': 'Pump Data'}, inplace=True)

    df.to_csv(path, index=False)

    columns = ['Soil Moisture', 'Temperature', 'Air Humidity', 'Pump Data']

    dl = DataLoader(path, columns)

    knn_model = Factory.create_model('knn', dl, n_neighbors=5)
    knn_model.train_model()
    knn_model.show_params()
    knn_model.save_model("knn_model_AWS.pkl")

    rf_model = Factory.create_model('random_forest', dl, n_estimators=100)
    rf_model.train_model()
    rf_model.show_params()
    rf_model.save_model("rf_model_AWS.pkl")

    xgb_model = Factory.create_model('xgboost', dl, n_estimators=100)
    xgb_model.train_model()
    xgb_model.show_params()
    xgb_model.save_model("xgb_model_AWS.pkl")

    lgbm_model = Factory.create_model('lightgbm', dl, n_estimators=100)
    lgbm_model.train_model()
    lgbm_model.show_params()
    lgbm_model.save_model("lgbm_model_AWS.pkl")

    nn_model = Factory.create_model('neural_network', dl, epochs=10, batch_size=32)
    nn_model.train_model()
    nn_model.show_params()
    nn_model.save_model("nn_model_AWS.keras")

    path = 'Soil Moisture, Air Temperature and humidity, and Water Motor onoff Monitor data.AmritpalKaur.csv'

    df = pd.read_csv(path)
    df['Soil Moisture'] = interp1d([df['Soil Moisture'].min(), df['Soil Moisture'].max()], [0, 100])(
        df['Soil Moisture'])
    df.to_csv(path, index=False)

    columns = ['Soil Moisture', 'Temperature', 'Air Humidity', 'Pump Data']

    dl = DataLoader(path, columns)

    knn_model = Factory.create_model('knn', dl, n_neighbors=5)
    knn_model.train_model()
    knn_model.show_params()
    knn_model.save_model("knn_model_Amritpal.pkl")

    rf_model = Factory.create_model('random_forest', dl, n_estimators=100)
    rf_model.train_model()
    rf_model.show_params()
    rf_model.save_model("rf_model_Amritpal.pkl")

    xgb_model = Factory.create_model('xgboost', dl, n_estimators=100)
    xgb_model.train_model()
    xgb_model.show_params()
    xgb_model.save_model("xgb_model_Amritpal.pkl")

    lgbm_model = Factory.create_model('lightgbm', dl, n_estimators=100)
    lgbm_model.train_model()
    lgbm_model.show_params()
    lgbm_model.save_model("lgbm_model_Amritpal.pkl")

    nn_model = Factory.create_model('neural_network', dl, epochs=10, batch_size=32)
    nn_model.train_model(epochs=10, batch_size=32)
    nn_model.show_params()
    nn_model.save_model("nn_model_Amritpal.keras")
