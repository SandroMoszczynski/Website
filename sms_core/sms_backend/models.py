from django.db import models

# Create your models here.

class Files(models.Model):

    class Meta:
        get_latest_by = 'upload_date'

    file = models.FileField()
    tag = models.CharField(max_length=10, blank=True, null=True)
    upload_date = models.DateTimeField(auto_now_add=True)

    