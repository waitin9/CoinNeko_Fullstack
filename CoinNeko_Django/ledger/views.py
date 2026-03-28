# backend/ledger/views.py
from datetime import date
from decimal import Decimal

from django.db.models import Sum, Q
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from .models import Category, Transaction, Budget, DailyCheckin
from .serializers import (
    CategorySerializer, TransactionSerializer,
    BudgetSerializer,
)

COINS_PER_TRANSACTION = 10  # 每筆記帳得 10 金幣
TICKET_DAILY_FIRST = 1       # 每日首筆記帳送 1 扭蛋券


# ──────────────────────────────────────────────
# Categories
# ──────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([AllowAny])
def category_list(request):
    """GET /api/categories/"""
    cats = Category.objects.all()
    return Response(CategorySerializer(cats, many=True).data)


# ──────────────────────────────────────────────
# Transactions
# ──────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def transaction_list(request):
    """GET /api/transactions/?month=YYYY-MM"""
    qs = Transaction.objects.filter(user=request.user)
    month = request.query_params.get('month')
    if month:
        try:
            year, m = map(int, month.split('-'))
            qs = qs.filter(transacted_at__year=year, transacted_at__month=m)
        except ValueError:
            pass
    return Response(TransactionSerializer(qs, many=True).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def transaction_create(request):
    """POST /api/transactions/
    Body: { category_id, amount, note }
    副作用: 給金幣 +10，每日首筆給扭蛋券 +1
    """
    serializer = TransactionSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    tx = serializer.save(user=request.user)

    user = request.user
    user.coins += COINS_PER_TRANSACTION
    ticket_earned = 0

    # 每日首登獎勵
    today = date.today()
    checkin, created = DailyCheckin.objects.get_or_create(
        user=user, checkin_date=today,
        defaults={'transactions_count': 0}
    )
    if created:
        ticket_earned = TICKET_DAILY_FIRST
        user.gacha_tickets += TICKET_DAILY_FIRST
    else:
        DailyCheckin.objects.filter(pk=checkin.pk).update(
            transactions_count=checkin.transactions_count + 1
        )

    user.save(update_fields=['coins', 'gacha_tickets'])

    from accounts.serializers import UserSerializer
    return Response({
        'success': True,
        'transaction': TransactionSerializer(tx).data,
        'coins_earned': COINS_PER_TRANSACTION,
        'ticket_earned': ticket_earned,
        'user': UserSerializer(user).data,
    }, status=status.HTTP_201_CREATED)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def transaction_delete(request, pk):
    """DELETE /api/transactions/<pk>/"""
    try:
        tx = Transaction.objects.get(pk=pk, user=request.user)
        tx.delete()
        return Response({'success': True})
    except Transaction.DoesNotExist:
        return Response({'error': '找不到此筆記帳'}, status=status.HTTP_404_NOT_FOUND)


# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def summary(request):
    """GET /api/summary/?month=YYYY-MM"""
    month = request.query_params.get('month') or date.today().strftime('%Y-%m')
    try:
        year, m = map(int, month.split('-'))
    except ValueError:
        return Response({'error': '無效月份格式'}, status=status.HTTP_400_BAD_REQUEST)

    base_qs = Transaction.objects.filter(
        user=request.user,
        transacted_at__year=year,
        transacted_at__month=m,
    )

    income = base_qs.filter(category__type='income').aggregate(
        total=Sum('amount'))['total'] or Decimal('0')
    expense = base_qs.filter(category__type='expense').aggregate(
        total=Sum('amount'))['total'] or Decimal('0')

    by_category = list(
        base_qs.values(
            'category__name', 'category__icon', 'category__type'
        ).annotate(total=Sum('amount')).order_by('-total')
    )
    # 重命名 key 對齊前端
    by_category = [
        {
            'name': r['category__name'],
            'icon': r['category__icon'],
            'type': r['category__type'],
            'total': r['total'],
        }
        for r in by_category
    ]

    return Response({
        'income': income,
        'expense': expense,
        'balance': income - expense,
        'by_category': by_category,
    })


# ──────────────────────────────────────────────
# Budgets
# ──────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def budget_list(request):
    """GET /api/budgets/?month=YYYY-MM"""
    month = request.query_params.get('month') or date.today().strftime('%Y-%m')
    budgets = Budget.objects.filter(user=request.user, month=month)
    return Response(BudgetSerializer(budgets, many=True).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def budget_create(request):
    """POST /api/budgets/"""
    category_id = request.data.get('category_id')
    month = request.data.get('month')
    limit_amount = request.data.get('limit_amount')

    if not all([category_id, month, limit_amount]):
        return Response({'error': '缺少必要欄位'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        category = Category.objects.get(pk=category_id)
    except Category.DoesNotExist:
        return Response({'error': '找不到類別'}, status=status.HTTP_404_NOT_FOUND)

    budget, created = Budget.objects.update_or_create(
        user=request.user,
        category=category,
        month=month,
        defaults={'limit_amount': limit_amount}
    )
    return Response(BudgetSerializer(budget).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)