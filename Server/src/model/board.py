
class Controller:
    def __init__(self, sensor_data: dict = None):
        if sensor_data is None:
            sensor_data = []
        self.sensor_data = sensor_data
