# backend/accounts/views.py
from django.contrib.auth import get_user_model, authenticate
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError

from .serializers import RegisterSerializer, UserSerializer, TokenResponseSerializer

User = get_user_model()


def _token_response(user):
    """共用：產生含 user 資訊的 JWT 回應"""
    tokens = TokenResponseSerializer.get_tokens_for_user(user)
    return {
        **tokens,
        'user': UserSerializer(user).data,
    }


@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """POST /api/auth/register/"""
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response(_token_response(user), status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """POST /api/auth/login/"""
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': '請輸入帳號和密碼'}, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=username, password=password)
    if not user:
        return Response({'error': '帳號或密碼錯誤'}, status=status.HTTP_401_UNAUTHORIZED)

    return Response(_token_response(user))


@api_view(['POST'])
@permission_classes([AllowAny])
def token_refresh(request):
    """POST /api/auth/refresh/"""
    refresh_token = request.data.get('refresh')
    if not refresh_token:
        return Response({'error': '缺少 refresh token'}, status=status.HTTP_400_BAD_REQUEST)
    try:
        refresh = RefreshToken(refresh_token)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        })
    except TokenError as e:
        return Response({'error': str(e)}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    """GET /api/auth/me/"""
    return Response(UserSerializer(request.user).data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """POST /api/auth/logout/ - 將 refresh token 加入黑名單"""
    try:
        refresh_token = request.data.get('refresh')
        token = RefreshToken(refresh_token)
        token.blacklist()
        return Response({'message': '已登出'})
    except Exception:
        return Response({'message': '已登出'})