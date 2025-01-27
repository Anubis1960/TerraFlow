import base64
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto import Random
from src.util.config import ENCRYPT_KEY as key


def encrypt(source, encode=True):
    if isinstance(source, str):
        source = source.encode("utf-8")
    _key = SHA256.new(key).digest()  # use SHA-256 over our key to get a proper-sized AES key
    IV = Random.new().read(AES.block_size)  # generate IV
    encryptor = AES.new(_key, AES.MODE_CBC, IV)
    padding = AES.block_size - len(source) % AES.block_size  # calculate needed padding
    source += bytes([padding]) * padding  # Python 2.x: source += chr(padding) * padding
    data = IV + encryptor.encrypt(source)  # store the IV at the beginning and encrypt
    return base64.b64encode(data).decode("latin-1") if encode else data


def decrypt(source, decode=True):
    if decode:
        source = base64.b64decode(source.encode("latin-1"))
    _key = SHA256.new(key).digest()  # use SHA-256 over our key to get a proper-sized AES key
    IV = source[:AES.block_size]  # extract the IV from the beginning
    decryptor = AES.new(_key, AES.MODE_CBC, IV)
    data = decryptor.decrypt(source[AES.block_size:])  # decrypt
    padding = data[-1]  # pick the padding value from the end; Python 2.x: ord(data[-1])
    if data[-padding:] != bytes([padding]) * padding:  # Python 2.x: chr(padding) * padding
        raise ValueError("Invalid padding...")
    return data[:-padding].decode()  # remove the padding


if __name__ == '__main__':
    txt = 'Hello, World!'
    encrypted = encrypt(txt)
    print(f'Encrypted: {encrypted}')
    decrypted = decrypt(encrypted)
    print(f'Decrypted: {decrypted}')
    assert txt == decrypted
