import json
from http.client import HTTPException

from flask import Blueprint

error_handle_blueprint = Blueprint('error', __name__)


@error_handle_blueprint.errorhandler(HTTPException)
def handle_http_exception(e):
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
