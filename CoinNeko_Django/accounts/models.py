# backend/accounts/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """擴充 Django 內建 User，加入貓咪幣與扭蛋券"""
    coins = models.IntegerField(default=0)
    gacha_tickets = models.IntegerField(default=0)

    class Meta:
        db_table = 'users'

    def __str__(self):
        return f"{self.username} (💰{self.coins} 🎟️{self.gacha_tickets})"