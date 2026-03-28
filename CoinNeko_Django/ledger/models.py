# backend/ledger/models.py
from django.db import models
from django.conf import settings


class Category(models.Model):
    TYPE_CHOICES = [('income', '收入'), ('expense', '支出')]

    name = models.CharField(max_length=50)
    icon = models.CharField(max_length=10)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)

    class Meta:
        db_table = 'categories'
        ordering = ['type', 'name']

    def __str__(self):
        return f"{self.icon} {self.name} ({self.type})"


class Transaction(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='transactions'
    )
    category = models.ForeignKey(Category, on_delete=models.PROTECT)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.CharField(max_length=200, blank=True, default='')
    transacted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'transactions'
        ordering = ['-transacted_at']

    def __str__(self):
        return f"{self.user.username}: {self.category.name} ${self.amount}"


class Budget(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='budgets'
    )
    category = models.ForeignKey(Category, on_delete=models.CASCADE)
    month = models.CharField(max_length=7)  # YYYY-MM
    limit_amount = models.DecimalField(max_digits=12, decimal_places=2)

    class Meta:
        db_table = 'budgets'
        unique_together = ('user', 'category', 'month')

    def __str__(self):
        return f"{self.user.username}: {self.category.name} {self.month} ${self.limit_amount}"


class DailyCheckin(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='checkins'
    )
    checkin_date = models.DateField()
    transactions_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'daily_checkins'
        unique_together = ('user', 'checkin_date')

    def __str__(self):
        return f"{self.user.username} @ {self.checkin_date}"