from django.shortcuts import render
from django.http import HttpResponseNotFound, HttpResponseForbidden, FileResponse , HttpResponse, Http404
from .models import *

# Create your views here.

def pdf_view(request, tag):
    file = Files.objects.filter(tag=tag).latest()
    try:
        return FileResponse(open(file.file.path, 'rb'), content_type = 'application/pdf')
    except FileNotFoundError:
        raise Http404