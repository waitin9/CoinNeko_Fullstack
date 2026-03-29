# backend/gacha/serializers.py
from rest_framework import serializers
from .models import CatSpecies, UserCat, GachaHistory


class CatSpeciesSerializer(serializers.ModelSerializer):
    rarity_display = serializers.CharField(source='get_rarity_display', read_only=True)

    class Meta:
        model = CatSpecies
        fields = ('id', 'name', 'job_title', 'rarity', 'rarity_display', 'emoji', 'description' , 'image_url')


class UserCatSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='cat_species.name', read_only=True)
    job_title = serializers.CharField(source='cat_species.job_title', read_only=True)
    rarity = serializers.CharField(source='cat_species.rarity', read_only=True)
    emoji = serializers.CharField(source='cat_species.emoji', read_only=True)
    description = serializers.CharField(source='cat_species.description', read_only=True)
    image_url = serializers.URLField(
        source='cat_species.image_url', read_only=True, allow_null=True)

    class Meta:
        model = UserCat
        fields = ('id', 'cat_species_id', 'name', 'job_title', 'rarity',
                  'emoji', 'description', 'star_level', 'acquired_at' , 'image_url')


class GachaHistorySerializer(serializers.ModelSerializer):
    cat = CatSpeciesSerializer(source='cat_species', read_only=True)

    class Meta:
        model = GachaHistory
        fields = ('id', 'cat', 'pulled_at')