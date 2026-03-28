# backend/gacha/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('cats/species/', views.species_list, name='species_list'),
    path('cats/collection/', views.collection, name='collection'),
    path('gacha/pull/', views.gacha_pull, name='gacha_pull'),
]