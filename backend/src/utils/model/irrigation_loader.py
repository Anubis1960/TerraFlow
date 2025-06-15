import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler


class DataLoader:
    """
    DataLoader class for loading and preparing the dataset.
    """

    def __init__(self, path: str, columns: list[str]):
        """
        Initialize the DataLoader with the path to the dataset and the columns to be used.

        :param path: str, path to the dataset file.
        :param columns: list, list of column names to be used in the dataset.
        """
        self.path = path
        self.columns = columns
        self.scaler = StandardScaler()

    def load_data(self) -> pd.DataFrame:
        """
        Load data from the specified path, perform necessary cleaning, and handle NULL values.

        :return: pd.DataFrame, cleaned dataset with 'status' column converted to binary.
        """
        dataset = pd.read_csv(self.path)
        dataset[self.columns[-1]] = dataset[self.columns[-1]].apply(lambda x: 1 if x == "ON" or x == 1 else 0)
        dataset.dropna(inplace=True)
        print(f"Loaded dataset with {len(dataset)} rows and {len(self.columns)} columns.")
        return dataset

    def prepare_data(self, split_ratio=0.2) -> tuple:
        """
        Divide features and outputs, create train and test subsets, and scale the values.

        :param split_ratio: float, the proportion of the dataset to include in the test split.
        :return: tuple, containing scaled training and testing features and labels.
        """
        dataset = self.load_data()
        x = dataset[self.columns[:-1]]
        y = dataset[self.columns[-1]]
        x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=split_ratio, random_state=42)
        x_train_scaled = self.scaler.fit_transform(x_train)
        x_test_scaled = self.scaler.transform(x_test)
        return x_train_scaled, x_test_scaled, y_train, y_test
