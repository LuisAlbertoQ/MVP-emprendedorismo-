from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from .models import Usuario


class RegisterTests(APITestCase):
    def test_register_success(self):
        data = {'telefono': '999888777', 'nombre': 'Juan', 'password': '123456'}
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Usuario.objects.count(), 1)
        user = Usuario.objects.first()
        self.assertEqual(user.telefono, '999888777')
        self.assertEqual(user.plan, 'gratuito')

    def test_register_duplicate_telefono(self):
        Usuario.objects.create_user(username='999888777', telefono='999888777', password='123456')
        data = {'telefono': '999888777', 'nombre': 'Otro', 'password': 'abcdef'}
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_missing_fields(self):
        response = self.client.post(reverse('register'), {'telefono': '999888777'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_short_password(self):
        data = {'telefono': '999888777', 'nombre': 'Juan', 'password': '123'}
        response = self.client.post(reverse('register'), data)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class LoginTests(APITestCase):
    def setUp(self):
        self.cred = {'telefono': '999888777', 'password': 'secret123'}
        Usuario.objects.create_user(
            username='999888777', telefono='999888777',
            password='secret123', first_name='Juan'
        )

    def test_login_success(self):
        response = self.client.post(reverse('login'), self.cred)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_login_wrong_password(self):
        response = self.client.post(reverse('login'), {
            'telefono': '999888777', 'password': 'wrongpass'
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_nonexistent_user(self):
        response = self.client.post(reverse('login'), {
            'telefono': '000000000', 'password': 'secret123'
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_inactive_user(self):
        Usuario.objects.filter(telefono='999888777').update(is_active=False)
        response = self.client.post(reverse('login'), self.cred)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class PerfilTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777',
            password='123456', first_name='Juan'
        )
        self.client.force_authenticate(user=self.user)

    def test_get_perfil_authenticated(self):
        response = self.client.get(reverse('perfil'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['telefono'], '999888777')
        self.assertEqual(response.data['first_name'], 'Juan')
        self.assertIn('plan', response.data)
        self.assertIn('limite_animales', response.data)
        self.assertIn('animales_count', response.data)
        self.assertIn('generations_allowed', response.data)

    def test_get_perfil_unauthorized(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(reverse('perfil'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class CambioPlanTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('cambiar_plan')

    def test_cambio_a_basico(self):
        response = self.client.post(self.url, {'plan': 'basico'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.plan, 'basico')

    def test_cambio_a_criador(self):
        response = self.client.post(self.url, {'plan': 'criador'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.user.refresh_from_db()
        self.assertEqual(self.user.plan, 'criador')

    def test_cambio_a_gratuito_rechazado(self):
        response = self.client.post(self.url, {'plan': 'gratuito'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cambio_plan_invalido(self):
        response = self.client.post(self.url, {'plan': 'no-existe'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cambio_plan_unauthorized(self):
        self.client.force_authenticate(user=None)
        response = self.client.post(self.url, {'plan': 'basico'})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class WebhookYapeTests(APITestCase):
    def test_webhook_accepts_post(self):
        response = self.client.post(reverse('webhook_yape'),
                                    {'status': 'completed'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data, {'status': 'received'})
