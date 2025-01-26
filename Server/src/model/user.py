from src.model.board import Board


class User:
    def __init__(self, email, password, boards: list[Board] = None):
        if boards is None:
            boards = []
        self.email = email
        self.password = password
        self.boards = boards
