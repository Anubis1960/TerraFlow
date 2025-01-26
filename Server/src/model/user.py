class User:
    def __init__(self, email, password, controllers: list[str] = None):
        if controllers is None:
            controllers = []
        self.email = email
        self.password = password
        self.controllers = controllers
