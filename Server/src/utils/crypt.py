"""
AES Encryption and Decryption Utility.

This module provides functions to encrypt and decrypt data using the AES algorithm in CBC mode.
The encryption key is hashed using SHA-256 to ensure compatibility with AES key length requirements.

Functions:
- `encrypt`: Encrypts a string or bytes using AES-CBC.
- `decrypt`: Decrypts an AES-CBC encrypted string or bytes.

Dependencies:
- `pycryptodome`: Provides AES and SHA-256 functionalities.
- `base64`: For encoding and decoding encrypted data.

Constants:
- `key`: The encryption key imported from the configuration.

Usage:
- `encrypt(source)`: Encrypts the given plaintext.
- `decrypt(source)`: Decrypts the given ciphertext.

Exceptions:
- Raises `ValueError` if padding is invalid during decryption.
"""

import base64
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto import Random
from src.utils.secrets import ENCRYPT_KEY as key  # Key imported from configuration


def encrypt(source: str, encode=True) -> str:
    """
    encrypts the given plaintext using AES in CBC mode.

    Args:
        source (str or bytes): The plaintext data to encrypt. if a string, it will be encoded to bytes.
        encode (bool): Whether to encode the output in Base64. defaults to True.

    Returns:
        str or bytes: The encrypted data, encoded in Base64 if `encode=True`.

    Raises:
        TypeError: If the input data type is invalid.
    """
    if isinstance(source, str):
        source = source.encode("utf-8")  # Convert string to bytes
    elif not isinstance(source, bytes):
        raise TypeError("Source must be a string or bytes.")

    # Hash the encryption key using SHA-256
    _key = SHA256.new(key).digest()

    # Generate a random Initialization Vector (IV)
    IV = Random.new().read(AES.block_size)

    # Create AES cipher object with CBC mode
    encryptor = AES.new(_key, AES.MODE_CBC, IV)

    # Add padding to the plaintext to match AES block size
    padding = AES.block_size - len(source) % AES.block_size
    source += bytes([padding]) * padding  # Padding uses the value of the number of padding bytes

    # Encrypt the plaintext and prepend the IV
    data = IV + encryptor.encrypt(source)

    # Encode the result in Base64 if requested
    return base64.b64encode(data).decode("latin-1") if encode else data


def decrypt(source: str, decode=True) -> str:
    """
    decrypts the given AES-CBC encrypted data.

    Args:
        source (str or bytes): The encrypted data to decrypt. if a string, it should be Base64-encoded.
        decode (bool): Whether the input is Base64-encoded. defaults to True.

    Returns:
        str: The decrypted plaintext.

    Raises:
        ValueError: If the padding is invalid or corrupted.
    """
    if decode:
        # Decode the input data from Base64
        source = base64.b64decode(source.encode("latin-1"))

    # Hash the encryption key using SHA-256
    _key = SHA256.new(key).digest()

    # Extract the IV from the start of the encrypted data
    IV = source[:AES.block_size]

    # Create AES cipher object with CBC mode
    decryptor = AES.new(_key, AES.MODE_CBC, IV)

    # Decrypt the ciphertext (excluding the IV)
    data = decryptor.decrypt(source[AES.block_size:])

    # Extract the padding value from the last byte
    padding = data[-1]

    # Verify and remove the padding
    if data[-padding:] != bytes([padding]) * padding:
        raise ValueError("Invalid padding...")

    # Return the plaintext as a string
    return data[:-padding].decode()
