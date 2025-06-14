import os

def get_env_var(key: str, env_file: str = ".env") -> str | None:
    """
    Retrieves the value of an environment variable from a .env file.

    :param key: str, The name of the environment variable.
    :param env_file: str, The path to the .env file.

    :return: str, The value of the environment variable.
    """
    print(f"Reading {key} from {env_file}")
    try:
        with open(env_file, 'r') as f:
            for line in f:
                if line.startswith(key):
                    return line.split('=')[1].strip()
    except Exception as e:
        print(f"Error reading {env_file}: {e}")
    print(f"Error: {key} not found in {env_file}.")
    return None