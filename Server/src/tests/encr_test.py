import unittest
from Crypto.Cipher import AES
from Crypto.Hash import SHA256
from Crypto import Random
from src.util.config import ENCRYPT_KEY as key
from src.util.crypt import encrypt, decrypt


class TestEncryption(unittest.TestCase):

    def setUp(self):
        # Generate a random key for testing
        self.key = key
        self.test_string = "This is a test string."
        self.test_bytes = b"This is a test byte string."

    def test_encrypt_decrypt_string(self):
        # Test encryption and decryption of a string
        encrypted = encrypt(self.test_string)
        decrypted = decrypt(encrypted)
        self.assertEqual(self.test_string, decrypted)

    def test_encrypt_decrypt_invalid_padding(self):
        # Test that decryption fails with invalid padding
        encrypted = encrypt(self.test_string)
        # Corrupt the padding
        corrupted_encrypted = encrypted[:-1] + 'x'
        with self.assertRaises(ValueError):
            decrypt(corrupted_encrypted)

    def test_encrypt_decrypt_empty_string(self):
        # Test encryption and decryption of an empty string
        empty_string = ""
        encrypted = encrypt(empty_string)
        decrypted = decrypt(encrypted)
        self.assertEqual(empty_string, decrypted)

    def test_encrypt_decrypt_large_string(self):
        # Test encryption and decryption of a large string
        large_string = "a" * 10000
        encrypted = encrypt(large_string)
        decrypted = decrypt(encrypted)
        self.assertEqual(large_string, decrypted)

    def test_encrypt_decrypt_special_characters(self):
        # Test encryption and decryption of a string with special characters
        special_string = "!@#$%^&*()_+{}|:\"<>?`~[]\\;',./"
        encrypted = encrypt(special_string)
        decrypted = decrypt(encrypted)
        self.assertEqual(special_string, decrypted)

    def test_encrypt_decrypt_non_ascii_characters(self):
        # Test encryption and decryption of a string with non-ASCII characters
        non_ascii_string = "こんにちは世界"
        encrypted = encrypt(non_ascii_string)
        decrypted = decrypt(encrypted)
        self.assertEqual(non_ascii_string, decrypted)


if __name__ == '__main__':
    unittest.main()