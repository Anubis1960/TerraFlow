import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import confusion_matrix
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2, ResNet50V2

from src.utils.model.disease_dataset import preprocess_dataset, reclass_and_save_images

tf.config.threading.set_intra_op_parallelism_threads(4)
tf.config.threading.set_inter_op_parallelism_threads(4)


def train_model(model, X_train, y_train, X_val, y_val, batch_size=128, epochs=100, callbacks=None, shuffle=True,
                class_weights=None):
    """
    Train the model with the given training and validation data.

    :param model: The Keras model to be trained.
    :param X_train: Training data features.
    :param y_train: Training data labels.
    :param X_val: Validation data features.
    :param y_val: Validation data labels.
    :param batch_size: Size of the batches used in training.
    :param epochs: Number of epochs to train the model.
    :param callbacks: List of Keras callbacks to apply during training.
    :param shuffle: Whether to shuffle the training data before each epoch.
    :param class_weights: Class weights for handling class imbalance.
    :return: History object containing training metrics.
    """

    if callbacks is None:
        callbacks = []
    history = model.fit(
        x=X_train,
        y=y_train,
        epochs=epochs,
        batch_size=batch_size,
        validation_data=(X_val, y_val),
        callbacks=[callbacks],
        class_weight=class_weights,
        shuffle=shuffle,
        verbose=2
    )

    return history


def plot_history(history):
    """
    Plot the training and validation loss and accuracy curves.

    :param history: History object returned by the model's fit method.
    :return: None
    """

    # Plot the loss curves
    plt.plot(history.history['loss'], label='Train Loss')
    plt.plot(history.history['val_loss'], label='Validation Loss')
    plt.legend()
    plt.show()

    # Plot the accuracy curves
    plt.plot(history.history['accuracy'], label='Train Accuracy')
    plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
    plt.legend()
    plt.show()


def plot_confussion_matrix(model, X_test, y_test):
    """
    Evaluate the model on the test set and plot the confusion matrix.

    :param model: The trained Keras model.
    :param X_test: Test data features.
    :param y_test: Test data labels.
    :return: None
    """

    test_loss, test_accuracy = model.evaluate(X_test, y_test)
    print(f"Test Loss: {test_loss}")
    print(f"Test Accuracy: {test_accuracy}")
    y_pred_proba = model.predict(X_test)
    y_pred = np.argmax(y_pred_proba, axis=1)
    cm = confusion_matrix(y_test, y_pred)
    sns.heatmap(cm, annot=True, fmt='d')
    plt.show()
    print("Confusion Matrix")
    print(cm)


def build_custom_cnn(input_shape=(224, 224, 3), output_size=7, batch_size=128, epochs=100, max_images=1000):
    """
    Build a custom CNN model for image classification.

    :param input_shape: Shape of the input images.
    :param output_size: Number of output classes.
    :param batch_size: Size of the batches used in training.
    :param epochs: Number of epochs to train the model.
    :param max_images: Maximum number of images to use for training.
    :return: None
    """
    model = tf.keras.models.Sequential([
        tf.keras.layers.Conv2D(64, (3, 3), padding='same', activation='relu', input_shape=input_shape),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Conv2D(64, (3, 3), padding='same', activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),

        # Block 2
        tf.keras.layers.Conv2D(128, (3, 3), padding='same', activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.Conv2D(128, (3, 3), padding='same', activation='relu'),
        tf.keras.layers.BatchNormalization(),
        tf.keras.layers.MaxPooling2D((2, 2)),

        # Global average pooling instead of Flatten()
        tf.keras.layers.GlobalAveragePooling2D(),

        # Dense layers
        tf.keras.layers.Dense(512, activation='relu'),
        tf.keras.layers.Dropout(0.5),
        tf.keras.layers.Dense(128, activation='relu'),
        tf.keras.layers.Dropout(0.3),
        tf.keras.layers.Dense(output_size, activation='softmax')
    ])

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    model.summary()
    X_train, y_train, X_val, y_val, X_test, y_test = preprocess_dataset(img_size=(input_shape[0], input_shape[1]),
                                                                        max_images=max_images)
    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_accuracy',
        patience=7,
        restore_best_weights=True
    )

    history = train_model(model, X_train, y_train, X_val, y_val, batch_size=batch_size, epochs=epochs,
                          callbacks=[early_stopping])

    plot_history(history)
    plot_confussion_matrix(model, X_test, y_test)
    model.save(f"{batch_size}_custom_{max_images}_{input_shape[0]}_{output_size}.keras")


def build_mobilenetv2(input_shape=(224, 224, 3), output_size=7, batch_size=128, epochs=100, max_images=1000):
    """
    Build a MobileNetV2 model for image classification.

    :param input_shape: Shape of the input images.
    :param output_size: Number of output classes.
    :param batch_size: Size of the batches used in training.
    :param epochs: Number of epochs to train the model.
    :param max_images: Maximum number of images to use for training.
    :return: None
    """

    base_model = MobileNetV2(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet'
    )

    # Freeze the base model
    base_model.trainable = False

    inputs = tf.keras.Input(shape=input_shape)
    x = base_model(inputs, training=False)

    # Global pooling and dense layers
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(512, activation='relu')(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation='relu')(x)
    outputs = layers.Dense(output_size, activation='softmax')(x)

    # Final model
    model = models.Model(inputs, outputs)

    # Compile the model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    # Summary of the model
    model.summary()

    X_train, y_train, X_val, y_val, X_test, y_test = preprocess_dataset(img_size=(input_shape[0], input_shape[1]),
                                                                        max_images=max_images)

    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_accuracy',
        patience=7,
        restore_best_weights=True
    )

    history = train_model(model, X_train, y_train, X_val, y_val, batch_size=batch_size, epochs=epochs,
                          callbacks=[early_stopping])

    plot_history(history)
    plot_confussion_matrix(model, X_test, y_test)
    model.save(f"{max_images}_mobilenetv2_{max_images}_{input_shape[0]}_{output_size}.keras")


def build_resnet50v2(input_shape=(224, 224, 3), output_size=7, batch_size=128, epochs=100, max_images=1000):
    """
    Build a ResNet50V2 model for image classification.

    :param input_shape: Shape of the input images.
    :param output_size: Number of output classes.
    :param batch_size: Size of the batches used in training.
    :param epochs: Number of epochs to train the model.
    :param max_images: Maximum number of images to use for training.
    :return: None
    """

    base_model = ResNet50V2(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet'
    )

    # Freeze the base model
    base_model.trainable = False

    inputs = tf.keras.Input(shape=input_shape)
    x = base_model(inputs, training=False)

    # Global pooling and dense layers
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(512, activation='relu')(x)
    x = layers.Dropout(0.5)(x)
    x = layers.Dense(128, activation='relu')(x)
    outputs = layers.Dense(output_size, activation='softmax')(x)

    # Final model
    model = models.Model(inputs, outputs)

    # Compile the model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )

    # Summary of the model
    model.summary()

    X_train, y_train, X_val, y_val, X_test, y_test = preprocess_dataset(img_size=(input_shape[0], input_shape[1]),
                                                                        max_images=max_images)

    early_stopping = tf.keras.callbacks.EarlyStopping(
        monitor='val_accuracy',
        patience=7,
        restore_best_weights=True
    )

    history = train_model(model, X_train, y_train, X_val, y_val, batch_size=batch_size, epochs=epochs,
                          callbacks=[early_stopping])

    plot_history(history)
    plot_confussion_matrix(model, X_test, y_test)
    model.save(f"{max_images}_resnet50v2_{max_images}_{input_shape[0]}_{output_size}.keras")


def main():
    reclass_and_save_images()

    INPUT_SHAPE = (224, 224, 3)
    OUTPUT_SIZE = 7
    BATCH_SIZE = 128
    EPOCHS = 100
    MAX_IMAGES = 1000

    build_custom_cnn(input_shape=INPUT_SHAPE, output_size=OUTPUT_SIZE, batch_size=BATCH_SIZE, epochs=EPOCHS, max_images=MAX_IMAGES)

    build_mobilenetv2(input_shape=INPUT_SHAPE, output_size=OUTPUT_SIZE, batch_size=BATCH_SIZE, epochs=EPOCHS, max_images=MAX_IMAGES)

    build_resnet50v2(input_shape=INPUT_SHAPE, output_size=OUTPUT_SIZE, batch_size=BATCH_SIZE, epochs=EPOCHS, max_images=MAX_IMAGES)

    INPUT_SHAPE = (48, 48, 3)
    build_custom_cnn(input_shape=INPUT_SHAPE, output_size=OUTPUT_SIZE, batch_size=BATCH_SIZE, epochs=EPOCHS, max_images=MAX_IMAGES)


if __name__ == "__main__":
    main()
