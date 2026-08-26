from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Task


class TaskApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username="alice", email="alice@example.com", password="secure-password"
        )
        self.client.force_authenticate(self.user)

    def test_user_can_create_and_list_only_their_tasks(self):
        Task.objects.create(owner=self.user, title="My task")
        other_user = get_user_model().objects.create_user(
            username="bob", email="bob@example.com", password="secure-password"
        )
        Task.objects.create(owner=other_user, title="Someone else's task")

        response = self.client.post("/api/tasks/", {"title": "New task"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.get("/api/tasks/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual({task["title"] for task in response.data}, {"My task", "New task"})
