import json
from http.client import HTTPException

from flask import Blueprint

error_handle_blueprint = Blueprint('error', __name__)


@error_handle_blueprint.errorhandler(HTTPException)
def handle_http_exception(e):
    """
    Handles HTTP exceptions and formats the response as JSON.

    :param e: HTTPException: The exception to handle.
    :return: Response: A Flask response object with JSON data and appropriate status code.
    """
    response = e.get_response()
    response.data = json.dumps({
        'error': {
            'code': e.code,
            'message': e.description
        }
    })
    response.status_code = e.code
    response.content_type = 'application/json'
    return response


@error_handle_blueprint.errorhandler(Exception)
def handle_exception(e):
    """
    Handles general exceptions and formats the response as JSON.

    :param e: Exception: The exception to handle.
    :return: Response: A Flask response object with JSON data and a 500 status code.
    """
    response = e.get_response()
    response.data = json.dumps({
        'error': {
            'code': e.code,
            'message': e.description
        }
    })
    response.content_type = 'application/json'
    response.status_code = 500
    return response
