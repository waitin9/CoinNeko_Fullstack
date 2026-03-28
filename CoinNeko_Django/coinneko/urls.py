# backend/coinneko/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('accounts.urls')),
    path('api/', include('ledger.urls')),
    path('api/', include('gacha.urls')),
]