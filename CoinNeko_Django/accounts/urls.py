# backend/accounts/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register, name='register'),
    path('login/', views.login, name='login'),
    path('refresh/', views.token_refresh, name='token_refresh'),
    path('me/', views.me, name='me'),
    path('logout/', views.logout, name='logout'),
]