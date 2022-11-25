from django.urls import path
from django.views.generic import TemplateView
from django.conf import settings
from django.conf.urls.static import static

from .views import *

app_name = 'sms_backend'

# Pages
urlpatterns = [
    path('' ,TemplateView.as_view(template_name='index.html'), name='index'),
    path('about' ,TemplateView.as_view(template_name='about.html'), name='about'),
    path('cpp_project' ,TemplateView.as_view(template_name='cpp_project.html'), name='cpp_project'),
    path('python_project' ,TemplateView.as_view(template_name='python_project.html'), name='python_project'),
    path('cv' ,TemplateView.as_view(template_name='cv.html'), name='cv'),
    path('hobbies' ,TemplateView.as_view(template_name='hobbies.html'), name='hobbies'),
    path('programming' ,TemplateView.as_view(template_name='programming.html'), name='programming'),
]  + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# Internal endpoints
urlpatterns += [
    path("show_latest_pdf/<str:tag>/", pdf_view, name="show_latest_pdf")
]