from django.contrib import admin
from .models import CatSpecies, UserCat

@admin.register(CatSpecies)
class CatSpeciesAdmin(admin.ModelAdmin):
    list_display = ('name', 'emoji', 'job_title', 'rarity')
    search_fields = ('name', 'job_title')

admin.site.register(UserCat)
