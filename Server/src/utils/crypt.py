import base64
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto import Random
from src.utils.secrets import ENCRYPT_KEY as key


def encrypt(source: str, encode=True) -> str:
    """
    encrypts the given plaintext using AES in CBC mode.

    :param source: str: The plaintext data to encrypt. if a string, it will be encoded to bytes.
    :param encode: bool: Whether to encode the output in Base64. defaults to True.
    :return: str: The encrypted data as a Base64-encoded string if `encode` is True, otherwise as bytes.
    """
    if isinstance(source, str):
        source = source.encode("utf-8")  # Convert string to bytes
    elif not isinstance(source, bytes):
        raise TypeError("Source must be a string or bytes.")

    # Hash the encryption key using SHA-256
    _key = SHA256.new(key).digest()

    # Generate a random Initialization Vector (IV)
    IV = Random.new().read(AES.block_size)

    # Create an AES cipher object with CBC mode
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
    decrypts the given AES-CBC encrypted data

    :param source: str: The encrypted data to decrypt. if a string, it should be Base64-encoded.
    :param decode: bool: Whether the input is Base64-encoded. defaults to True.
    :return: str: The decrypted plaintext.
    """
    if decode:
        # Decode the input data from Base64
        source = base64.b64decode(source.encode("latin-1"))

    # Hash the encryption key using SHA-256
    _key = SHA256.new(key).digest()

    # Extract the IV from the start of the encrypted data
    IV = source[:AES.block_size]

    # Create an AES cipher object with CBC mode
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
