
class Board:
    def __init__(self, board_id: int, sensor_data: list[str] = None):
        if sensor_data is None:
            sensor_data = []
        self.board_id = board_id
        self.sensor_data = sensor_data
