import os

import cv2
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

tf.config.threading.set_intra_op_parallelism_threads(4)
tf.config.threading.set_inter_op_parallelism_threads(4)

GENERALIZED_CLASSES = {
    0: [  # Fungal
        "Apple__black_rot",
        "Grape__black_rot",
        "Corn__common_rust",
        "Corn__gray_leaf_spot",
        "Corn__northern_leaf_blight",
        "Cherry__powdery_mildew",
        "Chili__leaf spot",
        "Coffee__cercospora_leaf_spot",
        "Coffee__rust",
        "Cucumber__diseased",
        "Grape__leaf_blight_(isariopsis_leaf_spot)",
        "Strawberry___leaf_scorch",
        "Tea__algal_leaf",
        "Tea__anthracnose",
        "Tea__bird_eye_spot",
        "Tea__brown_blight",
        "Tea__red_leaf_spot",
        "Tomato__early_blight",
        "Tomato__late_blight",
        "Tomato__leaf_mold",
        "Tomato__septoria_leaf_spot",
        "Tomato__target_spot",
        "Wheat__brown_rust",
        "Wheat__yellow_rust",
        "Wheat__septoria"
    ],
    1: [  # Bacterial
        "Apple__scab",
        "Cassava__bacterial_blight",
        "Chili__leaf curl",
        "Chili__whitefly",
        "Peach__bacterial_spot",
        "Pepper_bell__bacterial_spot",
        "Potato__early_blight",
        "Potato__late_blight",
        "Sugarcane__bacterial_blight",
        "Tomato__bacterial_spot",
        "Soybean__bacterial_blight"
    ],
    2: [  # Viral
        "Chili__yellowish",
        "Jamun__diseased",
        "Lemon__diseased",
        "Mango__diseased",
        "Pomegranate__diseased",
        "Tomato__mosaic_virus",
        "Tomato__yellow_leaf_curl_virus",
        "Soybean__mosaic_virus"
    ],
    3: [  # Pest
        "Apple__rust",
        "Cassava__mosaic_disease",
        "Rice__hispa",
        "Soybean__caterpillar",
        "Soybean__diabrotica_speciosa",
        "Coffee__red_spider_mite",
        "Tomato__spider_mites_(two_spotted_spider_mite)"
    ],
    4: [  # Disorder
        "Cassava__brown_streak_disease",
        "Cassava__green_mottle",
        "Gauva__diseased",
        "Grape__black_measles",
        "Rice__leaf_blast",
        "Rice__neck_blast",
        "Soybean__southern_blight",
        "Sugarcane__red_rot",
        "Sugarcane__red_stripe",
        "Sugarcane__rust"
    ],
    5: [  # Healthy
        "Apple__healthy",
        "Cassava__healthy",
        "Cherry__healthy",
        "Chili__healthy",
        "Coffee__healthy",
        "Corn__healthy",
        "Cucumber__healthy",
        "Gauva__healthy",
        "Grape__healthy",
        "Jamun__healthy",
        "Lemon__healthy",
        "Mango__healthy",
        "Peach__healthy",
        "Pepper_bell__healthy",
        "Pomegranate__healthy",
        "Potato__healthy",
        "Rice__healthy",
        "Soybean__healthy",
        "Strawberry__healthy",
        "Sugarcane__healthy",
        "Tea__healthy",
        "Tomato__healthy",
        "Wheat__healthy"
    ],
    6: [  # Unknown
        "unknown"
    ]
}


def load_images_from_folder(folder_path, img_size=(224, 224), max_images=500):
    """
    Loads images from a folder, preprocesses them:
    - Resizes to specified dimensions
    - Normalizes pixel values to [0, 1]

    Skips invalid or unreadable files.

    :param max_images: int, maximum number of images to load
    :param folder_path: str Path to the folder containing images
    :param img_size: tuple Target size for resizing (width, height)
    :return: np.array, Array of preprocessed images with shape (num_samples, img_size[0], img_size[1])
    """
    processed = []

    if not os.path.exists(folder_path):
        print(f"Folder does not exist: {folder_path}")
        return np.array(processed)

    # Get list of files and shuffle them
    filenames = [
        f for f in os.listdir(folder_path)
        if os.path.isfile(os.path.join(folder_path, f))
    ]
    np.random.shuffle(filenames)  # <--- Shuffle happens here

    print(f"Processing images in folder: {folder_path}")
    print(f"Found {len(filenames)} files. Loading up to {max_images}...")

    for filename in filenames:
        if max_images <= 0:
            break

        img_path = os.path.join(folder_path, filename)

        # Load image
        img = cv2.imread(img_path)

        if img is None:
            print(f"Failed to load image: {img_path}")
            continue

        try:
            # Resize image
            resized = cv2.resize(img, img_size, interpolation=cv2.INTER_AREA)

            # Normalize pixel values to [0, 1]
            normalized = resized.astype('float32') / 255.0

            # Add to list
            processed.append(normalized)
            max_images -= 1

        except Exception as e:
            print(f"Error processing image {img_path}: {e}")
            continue

    return np.array(processed)


def restructure_class_datasets(class_arrays_dict, train_ratio=0.7, val_ratio=0.15, test_ratio=0.15):
    """
    Takes a dictionary of {class_name: array_of_images}, combines train+valid,
    then splits into new train/val/test sets.

    :param class_arrays_dict: dict, Dictionary mapping class names to arrays of images
    :param train_ratio: float, Ratio of train set size
    :param val_ratio: float, Ratio of validation set size
    :param test_ratio: float, Ratio of test set size
    :return X_train, y_train, X_val, y_val, X_test, y_test
    """
    assert round(train_ratio + val_ratio + test_ratio) == 1, "Ratios must sum to 1"

    all_X = []
    all_y = []

    class_names = list(class_arrays_dict.keys())
    for idx, cls_name in enumerate(class_names):
        images = class_arrays_dict[cls_name]
        labels = [idx] * len(images)

        all_X.append(images)
        all_y.extend(labels)

    all_X = np.vstack(all_X)
    all_y = np.array(all_y)

    X_train, X_temp, y_train, y_temp = train_test_split(
        all_X, all_y, test_size=(val_ratio + test_ratio), random_state=42
    )

    val_test_ratio = test_ratio / (val_ratio + test_ratio)
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=val_test_ratio, random_state=42
    )

    return (X_train, y_train), (X_val, y_val), (X_test, y_test), class_names


def reclass_and_save_images(base_dir='merge', output_dir='processed_images'):
    """
    Processes images from base_dir and saves them directly to output_dir/class_X/
    without storing all images in memory.

    :param base_dir: str, Base directory containing subfolders of images
    :param output_dir: str, Directory where processed images will be saved
    :return: None
    """
    os.makedirs(output_dir, exist_ok=True)

    for folder in os.listdir(base_dir):
        src_path = os.path.join(base_dir, folder)
        if not os.path.isdir(src_path):
            continue

        class_label = map_folder_to_class(folder)
        if class_label is None:
            print(f"Folder '{folder}' not found in GENERALIZED_CLASSES mapping.")
            continue

        dest_class_dir = os.path.join(output_dir, f"class_{class_label}")
        os.makedirs(dest_class_dir, exist_ok=True)

        count = 0
        for filename in os.listdir(src_path):

            file_path = os.path.join(src_path, filename)
            img = cv2.imread(file_path)
            if img is None:
                print(f"Failed to load image: {file_path}")
                continue

            try:
                # Save path
                output_path = os.path.join(dest_class_dir, f"{count}_{filename}")
                cv2.imwrite(output_path, img)

                count += 1
            except Exception as e:
                print(f"Error processing {file_path}: {e}")

        print(f"Saved {count} images from '{folder}' to '{dest_class_dir}'")


def map_folder_to_class(folder_name):
    """
    Returns the generalized class label for a given folder name.

    :param folder_name: str, Name of the folder to map
    :return: int or None, Class label if found, otherwise None
    """
    for cls_label, folder_list in GENERALIZED_CLASSES.items():
        if folder_name in folder_list:
            return cls_label
    return None


def preprocess_dataset(base_dir: str = 'processed_images', img_size=(224, 224), max_images=1000):
    """
    Preprocesses the dataset by loading images from the specified base directory,
    resizing them to the specified image size, and splitting them into training,
    validation, and test sets.

    :param base_dir: str, Base directory containing subfolders of images
    :param img_size: tuple, Size to which images will be resized (width, height)
    :param max_images: int, Maximum number of images to load from each class folder
    :return: tuple, (X_train, y_train, X_val, y_val, X_test, y_test)
    """
    images = {}

    # Loop through each directory and load images
    for folder in os.listdir(base_dir):
        imags = load_images_from_folder(f"{base_dir}/{folder}", img_size=img_size, max_images=max_images)
        images[folder] = imags

    del imags

    generalized_datasets = {
        0: images['class_0'],
        1: images['class_1'],
        2: images['class_2'],
        3: images['class_3'],
        4: images['class_4'],
        5: images['class_5'],
        6: images['class_6'],
    }

    (X_train, y_train), (X_val, y_val), (X_test, y_test), class_names = restructure_class_datasets(generalized_datasets)

    del generalized_datasets

    x_shuffle = np.random.permutation(len(X_train))
    X_train = X_train[x_shuffle]
    y_train = y_train[x_shuffle]

    return X_train, y_train, X_val, y_val, X_test, y_test
