from authlib.integrations.flask_client import OAuth
from src.utils.secrets import GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET


class OAuthManager:
    """
    Manages OAuth 2.0 authentication with external providers, in this case, Google.
    """

    def __init__(self, app=None):
        """
        Initializes the OAuthManager object. Optionally initializes OAuth with the Flask app.

        Args:
            app (Flask, optional): A Flask app instance to initialize the OAuth object with. Defaults to None.
        """
        self.oauth = OAuth()
        if app:
            self.init_app(app)

    def init_app(self, app):
        """
        Initializes OAuth with the app configuration and registers the Google OAuth provider.

        :param app: Flask app instance to initialize OAuth with.
        """
        self.oauth.init_app(app)
        self.oauth.register(
            name='google',
            client_id=GOOGLE_CLIENT_ID,
            client_secret=GOOGLE_CLIENT_SECRET,
            access_token_url='https://accounts.google.com/o/oauth2/token',
            access_token_params=None,
            authorize_url='https://accounts.google.com/o/oauth2/auth',
            authorize_params=None,
            api_base_url='https://www.googleapis.com/oauth2/v1/',
            userinfo_endpoint='https://openidconnect.googleapis.com/v1/userinfo',
            client_kwargs={'scope': 'email profile'},
            server_metadata_url='https://accounts.google.com/.well-known/openid-configuration'
        )

    def get_provider(self, name):
        """
        Retrieves a registered OAuth provider by name.

        :param name: str: The name of the OAuth provider to retrieve.
        :return: OAuth client instance for the specified provider.
        """
        return self.oauth.create_client(name)
