from sms_backend.models import *
from rest_framework import viewsets, mixins, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, parser_classes, action
from rest_framework.parsers import FileUploadParser, MultiPartParser

# Create your views here.
class FileManagementViewset(viewsets.ModelViewSet):
    """
    This will be how files are uploaded and managed by the server
    """
    pass