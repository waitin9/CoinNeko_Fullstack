# backend/gacha/views.py
import random

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from .models import CatSpecies, UserCat, GachaHistory
from .serializers import CatSpeciesSerializer, UserCatSerializer

# ──────── 抽卡權重設定 ────────
RARITY_WEIGHTS = {
    'legendary': 0.02,   # 2%
    'epic':      0.08,   # 8%
    'rare':      0.25,   # 25%
    'common':    0.65,   # 65%
}
RARITY_ORDER = ['legendary', 'epic', 'rare', 'common']

# 升星/重複金幣獎勵
DUPE_STAR_COINS = 30    # 重複且未滿 5 星：升星 + 30 金幣
DUPE_MAX_COINS = 50     # 重複且已滿 5 星：50 金幣
COIN_COST = 50          # 用金幣抽一次的費用


def _weighted_rarity() -> str:
    """根據權重隨機回傳稀有度字串"""
    rand = random.random()
    cumulative = 0.0
    for rarity in RARITY_ORDER:
        cumulative += RARITY_WEIGHTS[rarity]
        if rand < cumulative:
            return rarity
    return 'common'


@api_view(['GET'])
@permission_classes([AllowAny])
def species_list(request):
    """GET /api/cats/species/"""
    rarity_order = {r: i for i, r in enumerate(reversed(RARITY_ORDER))}
    all_species = CatSpecies.objects.all()
    sorted_species = sorted(all_species, key=lambda s: (rarity_order.get(s.rarity, 0), s.name), reverse=True)
    return Response(CatSpeciesSerializer(sorted_species, many=True).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def collection(request):
    """GET /api/cats/collection/"""
    user_cats = UserCat.objects.filter(user=request.user).select_related('cat_species')
    return Response(UserCatSerializer(user_cats, many=True).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def gacha_pull(request):
    """POST /api/gacha/pull/
    Body: { "use_coins": true/false }

    抽卡邏輯：
    1. 扣除資源（扭蛋券 or 50 金幣）
    2. 依權重決定稀有度
    3. 從該稀有度隨機選一隻貓
    4. 重複→升星（上限5星）/ 轉換金幣
    5. 新貓→加入圖鑑
    6. 回傳結果
    """
    user = request.user
    use_coins = request.data.get('use_coins', False)

    # ── 1. 扣除資源 ──
    if use_coins:
        if user.coins < COIN_COST:
            return Response(
                {'error': f'貓咪幣不足（需要 {COIN_COST} 枚）'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.coins -= COIN_COST
    else:
        if user.gacha_tickets < 1:
            return Response(
                {'error': '扭蛋券不足'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.gacha_tickets -= 1

    # ── 2. 決定稀有度 ──
    rarity = _weighted_rarity()

    # ── 3. 選貓 ──
    pool = list(CatSpecies.objects.filter(rarity=rarity))
    if not pool:
        # Fallback：若該稀有度沒有貓，降一級
        fallback_order = ['legendary', 'epic', 'rare', 'common']
        idx = fallback_order.index(rarity)
        for r in fallback_order[idx + 1:]:
            pool = list(CatSpecies.objects.filter(rarity=r))
            if pool:
                rarity = r
                break
    picked_species = random.choice(pool)

    # ── 4. 重複判斷 ──
    is_duplicate = False
    star_up = False
    coins_bonus = 0

    try:
        user_cat = UserCat.objects.get(user=user, cat_species=picked_species)
        is_duplicate = True
        if user_cat.star_level < 5:
            user_cat.star_level += 1
            user_cat.save(update_fields=['star_level'])
            star_up = True
            coins_bonus = DUPE_STAR_COINS
        else:
            coins_bonus = DUPE_MAX_COINS
        user.coins += coins_bonus
    except UserCat.DoesNotExist:
        # ── 5. 新貓入圖鑑 ──
        user_cat = UserCat.objects.create(
            user=user,
            cat_species=picked_species,
            star_level=1,
        )

    # 記錄歷史
    GachaHistory.objects.create(user=user, cat_species=picked_species)

    # 存使用者資料
    user.save(update_fields=['coins', 'gacha_tickets'])

    from accounts.serializers import UserSerializer
    return Response({
        'cat': CatSpeciesSerializer(picked_species).data,
        'is_duplicate': is_duplicate,
        'star_up': star_up,
        'coins_bonus': coins_bonus,
        'new_star_level': user_cat.star_level,
        'user': UserSerializer(user).data,
    })