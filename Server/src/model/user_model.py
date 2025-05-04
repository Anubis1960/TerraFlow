from bson.objectid import ObjectId
from pymongoose.mongo_types import Types, Schema


class User(Schema):
    schema_name = "users"  # Name of the schema that mongo uses

    # Attributes
    id = None
    email = None
    password = None
    devices = None

    def __init__(self, **kwargs):
        self.schema = {
            "email": {
                "type": Types.String,
                "required": True,
                "unique": True,
            },
            "password": {
                "type": Types.String,
                "required": True,
            },
            "devices": [{
                "type": Types.String,
            }]
        }

        super().__init__(self.schema_name, self.schema, kwargs)

    def __str__(self):
        return f"User(id={self.id}, email={self.email}, devices={self.devices})"