from django.contrib import admin
from django.urls import include, path
from drf_yasg import openapi
from drf_yasg.views import get_schema_view
from rest_framework import permissions
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

schema_view = get_schema_view(
    openapi.Info(
        title="Task Manager API",
        default_version="v1",
        description="API documentation for the Task Manager backend.",
    ),
    public=True,
    permission_classes=[permissions.AllowAny],
)

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/schema/", schema_view.without_ui(cache_timeout=0), name="schema-json"),
    path("api/docs/", schema_view.with_ui("swagger", cache_timeout=0), name="schema-swagger-ui"),
    path("api/redoc/", schema_view.with_ui("redoc", cache_timeout=0), name="schema-redoc"),
    path("api/auth/", include("users.urls")),
    path("api/auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("api/tasks/", include("tasks.urls")),
]
