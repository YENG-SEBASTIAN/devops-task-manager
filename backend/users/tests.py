from rest_framework import status
from rest_framework.test import APITestCase


class AuthenticationApiTests(APITestCase):
    def test_user_can_register_and_obtain_tokens(self):
        registration = self.client.post(
            "/api/auth/register/",
            {"username": "alice", "email": "alice@example.com", "password": "secure-password"},
            format="json",
        )
        self.assertEqual(registration.status_code, status.HTTP_201_CREATED)
        self.assertNotIn("password", registration.data)

        tokens = self.client.post(
            "/api/auth/token/", {"username": "alice", "password": "secure-password"}, format="json"
        )
        self.assertEqual(tokens.status_code, status.HTTP_200_OK)
        self.assertIn("access", tokens.data)
        self.assertIn("refresh", tokens.data)
