# backend/ledger/serializers.py
from rest_framework import serializers
from .models import Category, Transaction, Budget, DailyCheckin
from django.contrib.auth import get_user_model

User = get_user_model()


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'


class TransactionSerializer(serializers.ModelSerializer):
    cat_name = serializers.CharField(source='category.name', read_only=True)
    cat_icon = serializers.CharField(source='category.icon', read_only=True)
    cat_type = serializers.CharField(source='category.type', read_only=True)

    class Meta:
        model = Transaction
        fields = ('id', 'category', 'cat_name', 'cat_icon', 'cat_type',
                  'amount', 'note', 'transacted_at')
        read_only_fields = ('id', 'transacted_at')


class BudgetSerializer(serializers.ModelSerializer):
    cat_name = serializers.CharField(source='category.name', read_only=True)
    cat_icon = serializers.CharField(source='category.icon', read_only=True)
    spent = serializers.SerializerMethodField()

    class Meta:
        model = Budget
        fields = ('id', 'category', 'cat_name', 'cat_icon', 'month',
                  'limit_amount', 'spent')

    def get_spent(self, obj):
        from django.db.models import Sum
        result = Transaction.objects.filter(
            user=obj.user,
            category=obj.category,
            transacted_at__year=int(obj.month[:4]),
            transacted_at__month=int(obj.month[5:]),
        ).aggregate(total=Sum('amount'))
        return result['total'] or 0


class SummarySerializer(serializers.Serializer):
    income = serializers.DecimalField(max_digits=12, decimal_places=2)
    expense = serializers.DecimalField(max_digits=12, decimal_places=2)
    balance = serializers.DecimalField(max_digits=12, decimal_places=2)
    by_category = serializers.ListField()