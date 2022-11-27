from django.urls import include, path
from rest_framework.routers import SimpleRouter 

from .views import *

app_name = 'sms_api'

public_urls_v1 = [
    path('happy_message', return_happy_message, name='happy_message'),
]

urlpatterns = [
    path('api/public/v1/', include((public_urls_v1, 'api'), namespace='public_v1')),
]