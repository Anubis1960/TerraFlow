import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

# Load the dataset
data = pd.read_csv(
    'dataset/AmritpalKaur.csv')

X = data[['Soil Moisture', 'Temperature', 'Air Humidity']]
y = data['Pump Data']

X['Soil Moisture'] = interp1d([X['Soil Moisture'].min(), X['Soil Moisture'].max()], [0, 100])(X['Soil Moisture'])

print(X)

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

rf = RandomForestClassifier(n_estimators=100)
rf.fit(X_train, y_train)

y_pred = rf.predict(X_test)

print(f'Accuracy: {accuracy_score(y_test, y_pred)}')
print(f'Report: {classification_report(y_test, y_pred)}')

sample = X_test.iloc[0:1]  # Keep as DataFrame to match model input format
prediction = rf.predict(sample)

# Retrieve and display the sample
sample_dict = sample.iloc[0].to_dict()
print(f"\nSample Passenger: {sample_dict}")

print(f"Prediction: {prediction}")

# Create the confusion matrix
cm = confusion_matrix(y_test, y_pred)

ConfusionMatrixDisplay(confusion_matrix=cm).plot()
plt.show()

# Plot the feature importances
importances = rf.feature_importances_

plt.bar(X.columns, importances)
plt.xlabel('Features')
plt.ylabel('Importance')
plt.title('Feature Importance')

plt.show()