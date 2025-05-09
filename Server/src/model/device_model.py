from pymongoose.mongo_types import Types, Schema


class Device(Schema):
    schema_name = "devices"  # Name of the schema that mongo uses

    # Attributes
    id = None
    record = None
    water_usage = None

    def __init__(self, **kwargs):
        self.schema = {
            "record": [{
                "sensor_data": {
                    "temperature": {
                        "type": Types.Number,
                        "default": 0.0,
                    },
                    "humidity": {
                        "type": Types.Number,
                        "default": 0.0,
                    },
                    "moisture": {
                        "type": Types.Number,
                        "default": 0.0,
                    },
                },
                "timestamp": {
                    "type": Types.Date,
                    "default": None,
                },

            }],
            "water_usage": [{
                "water_used": {
                    "type": Types.Number,
                    "default": 0.0,
                },
                "timestamp": {
                    "type": Types.Date,
                    "default": None,
                },
            }]
        }

        super().__init__(self.schema_name, self.schema, kwargs)

    def __str__(self):
        return f"Device(id={self.id}, record={self.record}, water_usage={self.water_usage})"
