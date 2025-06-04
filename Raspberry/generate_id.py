import utime
import urandom
import uhashlib

# Counter to ensure uniqueness within the same second
_counter = 0

# A fixed salt value (you can generate this once and store it securely)
_salt = urandom.getrandbits(32)

def generate_object_id():
    """
    Generates a unique Object ID using the following components:
    
    1. **Timestamp (4 bytes)**: The current Unix timestamp in seconds (from `utime.time()`).
    2. **Random Value (8 bytes)**: A 64-bit random value generated using `urandom.getrandbits`. 
       If 64-bit randomness is not supported, it falls back to combining two 32-bit values.
    3. **Counter (3 bytes)**: A global counter that increments with each call. 
       It ensures uniqueness within the same second and wraps around at 0xFFFFFF.
    4. **Salt (4 bytes)**: A fixed 32-bit random value initialized when the module loads.
    
    All these components are combined into a string, which is then hashed using SHA-256 to
    produce a secure, random, and unique identifier.
    
    The first 24 characters of the SHA-256 hash (12 bytes) are returned as the Object ID.
    
    Returns:
        str: A 24-character hexadecimal string representing the unique Object ID.
    """
    global _counter

    # Get current timestamp (4 bytes)
    timestamp = int(utime.time())  # Seconds since Unix epoch

    # Generate a 64-bit random value using urandom (if available)
    try:
        random_value = int.from_bytes(urandom.getrandbits(64).to_bytes(8, 'big'), 'big')
    except:
        # Fallback to 32-bit random value if 64-bit is not supported
        random_value_high = urandom.getrandbits(32)  # First 32 bits
        random_value_low = urandom.getrandbits(32)   # Next 32 bits
        random_value = (random_value_high << 32) | random_value_low  # Combine into 64 bits

    # Increment the counter (3 bytes)
    _counter = (_counter + 1) & 0xFFFFFF  # Ensure it stays within 3 bytes (0xFFFFFF)

    # Combine all parts with the salt
    combined = f"{timestamp:08x}{random_value:016x}{_counter:06x}{_salt:08x}"

    # Hash the combined string using SHA-256 to ensure randomness and security
    sha256 = uhashlib.sha256(combined.encode())
    hashed_bytes = sha256.digest()  # Get the hash as bytes
    hashed_hex = ''.join('{:02x}'.format(b) for b in hashed_bytes)  # Convert bytes to hex string

    # Use the first 24 characters of the hash as the ObjectId (12 bytes)
    object_id = hashed_hex[:24]

    return object_id
