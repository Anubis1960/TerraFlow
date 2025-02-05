from http import HTTPStatus

from flask import Blueprint, request, jsonify
from src.service.rest_service import login, register, google_login

auth_blueprint = Blueprint('auth', __name__)


@auth_blueprint.route('/login', methods=['POST'])
def handle_login():
    pass


@auth_blueprint.route('/register', methods=['POST'])
def handle_register():
    pass


@auth_blueprint.route('/google_login', methods=['POST'])
def handle_google_login():
    pass
