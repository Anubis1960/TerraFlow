from flask_socketio import SocketIO
from flask_mqtt import Mqtt
from authlib.integrations.flask_client import OAuth
from src.util.config import GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET

# Initialize socketio (but don't bind it to the app yet)
socketio = SocketIO(cors_allowed_origins='*', logger=False, engineio_logger=False)
mqtt = Mqtt()

# Initialize OAuth
oauth = OAuth()

google = oauth.register(
    name='google',
    client_id=GOOGLE_CLIENT_ID,
    client_secret=GOOGLE_CLIENT_SECRET,
    authorize_url='https://accounts.google.com/o/oauth2/auth',
    authorize_params=None,
    access_token_url='https://accounts.google.com/o/oauth2/token',
    access_token_params=None,
    refresh_token_url=None,
    redirect_uri='http://localhost:5000/auth/google',
    client_kwargs={'scope': 'openid profile email'},
)