# backend/gacha/models.py
from django.db import models
from django.conf import settings


class CatSpecies(models.Model):
    RARITY_CHOICES = [
        ('common', '普通'),
        ('rare', '稀有'),
        ('epic', '史詩'),
        ('legendary', '傳說'),
    ]
    name = models.CharField(max_length=50)
    job_title = models.CharField(max_length=50)
    rarity = models.CharField(max_length=10, choices=RARITY_CHOICES)
    emoji = models.CharField(max_length=10)
    description = models.TextField(blank=True, default='')

    image_url = models.URLField(blank=True, null=True, default=None)

    class Meta:
        db_table = 'cat_species'
        ordering = ['rarity', 'name']

    def __str__(self):
        return f"{self.emoji} {self.name} ({self.rarity})"


class UserCat(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='user_cats'
    )
    cat_species = models.ForeignKey(CatSpecies, on_delete=models.CASCADE)
    star_level = models.IntegerField(default=1)
    acquired_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_cats'
        unique_together = ('user', 'cat_species')

    def __str__(self):
        return f"{self.user.username} - {self.cat_species.name} ★{self.star_level}"


class GachaHistory(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='gacha_history'
    )
    cat_species = models.ForeignKey(CatSpecies, on_delete=models.CASCADE)
    pulled_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'gacha_history'
        ordering = ['-pulled_at']