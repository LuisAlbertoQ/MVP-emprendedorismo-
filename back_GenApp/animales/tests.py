import uuid
from datetime import date, timedelta
from decimal import Decimal
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from django.core.exceptions import ValidationError
from usuarios.models import Usuario
from .models import Animal, Especie, Sexo, SyncStatus, Produccion
from .utils import calcular_categoria_edad


class AnimalModelTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777',
            password='123456', first_name='Juan'
        )

    def _make_animal(self, **kwargs):
        defaults = dict(arete='A-001', especie='alpaca', sexo='macho',
                        fecha_nacimiento='2023-01-01', usuario=self.user)
        defaults.update(kwargs)
        return Animal.objects.create(**defaults)

    def test_create_animal_minimal(self):
        animal = self._make_animal()
        self.assertEqual(animal.arete, 'A-001')
        self.assertTrue(animal.activo)
        self.assertEqual(animal.sync_status, SyncStatus.SIC)
        self.assertIsNotNone(animal.uid)

    def test_str_representation(self):
        animal = self._make_animal(nombre='Tormenta')
        self.assertIn('A-001', str(animal))

    def test_unique_together_usuario_arete(self):
        self._make_animal()
        with self.assertRaises(Exception):
            self._make_animal()

    def test_self_parent_validation(self):
        animal = self._make_animal()
        animal.padre = animal
        with self.assertRaises(ValidationError):
            animal.full_clean()

    def test_self_mother_validation(self):
        animal = self._make_animal()
        animal.madre = animal
        with self.assertRaises(ValidationError):
            animal.full_clean()

    def test_verificar_padres_mismo_usuario(self):
        otro_user = Usuario.objects.create_user(
            username='111222333', telefono='111222333', password='123456'
        )
        padre = self._make_animal(arete='PADRE-01')
        padre.usuario = otro_user
        padre.save()
        animal = self._make_animal(arete='HIJO-01')
        animal.padre = padre
        with self.assertRaises(ValidationError):
            animal.full_clean()

    def test_padre_arete_property(self):
        padre = self._make_animal(arete='PADRE-01')
        hijo = self._make_animal(arete='HIJO-01', padre=padre)
        self.assertEqual(hijo.padre_arete, 'PADRE-01')
        self.assertIsNone(hijo.madre_arete)

    def test_limites_plan(self):
        self.assertEqual(self.user.limite_animales, 20)
        self.assertEqual(self.user.generations_allowed, 2)

    def test_limites_plan_basico(self):
        self.user.plan = 'basico'
        self.assertEqual(self.user.limite_animales, 150)
        self.assertEqual(self.user.generations_allowed, 3)

    def test_limites_plan_criador(self):
        self.user.plan = 'criador'
        self.assertEqual(self.user.limite_animales, 500)
        self.assertEqual(self.user.generations_allowed, 3)


class AnimalCRUDTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777',
            password='123456', first_name='Juan'
        )
        self.client.force_authenticate(user=self.user)
        self.list_url = reverse('animal-list')

    def _create_animal(self, **overrides):
        data = dict(arete='A-001', especie='alpaca', sexo='macho',
                    fecha_nacimiento='2023-01-01')
        data.update(overrides)
        return self.client.post(self.list_url, data, format='json')

    def test_create_animal_success(self):
        response = self._create_animal()
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('uid', response.data)

    def test_create_animal_duplicate_arete(self):
        self._create_animal()
        response = self._create_animal()
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_animal_exceeds_limit(self):
        for i in range(20):
            self._create_animal(arete=f'A-{i:03d}')
        response = self._create_animal(arete='EXTRA-01')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_with_parents(self):
        padre_resp = self._create_animal(arete='PADRE-01')
        madre_resp = self._create_animal(arete='MADRE-01', sexo='hembra')
        uid_padre = padre_resp.data['uid']
        uid_madre = madre_resp.data['uid']
        response = self.client.post(self.list_url, {
            'arete': 'HIJO-01', 'especie': 'alpaca', 'sexo': 'macho',
            'fecha_nacimiento': '2024-01-01',
            'padre': uid_padre, 'madre': uid_madre
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data.get('padre'), 'PADRE-01')
        self.assertEqual(response.data.get('madre'), 'MADRE-01')
        self.assertEqual(response.data.get('padre_uid'), uid_padre)
        self.assertEqual(response.data.get('madre_uid'), uid_madre)

    def test_list_animals(self):
        self._create_animal()
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)

    def test_list_filter_by_especie(self):
        self._create_animal(arete='A-001')
        self._create_animal(arete='A-002', especie='llama')
        response = self.client.get(self.list_url, {'especie': 'alpaca'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        results = response.data['results']
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0]['especie'], 'alpaca')

    def test_list_filter_by_sexo(self):
        self._create_animal(arete='A-001')
        self._create_animal(arete='A-002', sexo='hembra')
        response = self.client.get(self.list_url, {'sexo': 'hembra'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['results']), 1)

    def test_get_animal_detail(self):
        create_resp = self._create_animal()
        uid = create_resp.data['uid']
        response = self.client.get(reverse('animal-detail', kwargs={'pk': uid}))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['uid'], uid)

    def test_update_animal(self):
        create_resp = self._create_animal()
        uid = create_resp.data['uid']
        response = self.client.patch(
            reverse('animal-detail', kwargs={'pk': uid}),
            {'nombre': 'Nuevo Nombre'}, format='json'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get('nombre'), 'Nuevo Nombre')

    def test_delete_animal_soft_delete(self):
        create_resp = self._create_animal()
        uid = create_resp.data['uid']
        url = reverse('animal-detail', kwargs={'pk': uid})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        animal = Animal.objects.get(uid=uid)
        self.assertFalse(animal.activo)
        self.assertIsNotNone(animal.deleted_at)

    def test_unauthorized_access(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_cannot_see_other_user_animals(self):
        otro = Usuario.objects.create_user(
            username='111222333', telefono='111222333', password='123456'
        )
        Animal.objects.create(
            arete='OTRO-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=otro
        )
        response = self.client.get(self.list_url)
        self.assertEqual(len(response.data['results']), 0)


class ArbolTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777', password='123456'
        )
        self.client.force_authenticate(user=self.user)

    def _create(self, **kw):
        defaults = dict(especie='alpaca', sexo='macho',
                        fecha_nacimiento='2023-01-01')
        defaults.update(kw)
        data = {'usuario': self.user}
        data.update(defaults)
        return Animal.objects.create(**data)

    def test_arbol_simple(self):
        a = self._create(arete='A-001')
        response = self.client.get(
            reverse('animal-arbol', kwargs={'pk': a.uid})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['arete'], 'A-001')

    def test_arbol_with_parents(self):
        padre = self._create(arete='PADRE', sexo='macho')
        madre = self._create(arete='MADRE', sexo='hembra')
        hijo = self._create(arete='HIJO', sexo='macho', padre=padre, madre=madre)
        response = self.client.get(
            reverse('animal-arbol', kwargs={'pk': hijo.uid})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['padre'])
        self.assertIsNotNone(response.data['madre'])
        self.assertEqual(response.data['padre']['arete'], 'PADRE')
        self.assertEqual(response.data['madre']['arete'], 'MADRE')

    def test_arbol_limited_by_plan(self):
        abuelo = self._create(arete='ABUELO', sexo='macho')
        padre = self._create(arete='PADRE', sexo='macho', padre=abuelo)
        hijo = self._create(arete='HIJO', sexo='macho', padre=padre)
        self.assertEqual(self.user.generations_allowed, 2)
        response = self.client.get(
            reverse('animal-arbol', kwargs={'pk': hijo.uid})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNotNone(response.data['padre'])
        self.assertIsNotNone(response.data['padre']['padre'])
        self.assertNotIn('padre', response.data['padre']['padre'])


class SyncTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('sync')

    def test_sync_create_animal(self):
        uid = str(uuid.uuid4())
        response = self.client.post(self.url, {
            'changes': [{
                'uid': uid, 'arete': 'SYNC-01', 'especie': 'alpaca',
                'sexo': 'macho', 'fecha_nacimiento': '2024-01-01',
                'action': 'create'
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn(str(uid), response.data['processed'])
        self.assertTrue(Animal.objects.filter(uid=uid).exists())

    def test_sync_update_animal(self):
        animal = Animal.objects.create(
            uid=uuid.uuid4(), arete='ORIG-01', especie='alpaca',
            sexo='macho', fecha_nacimiento='2023-01-01', usuario=self.user
        )
        uid_str = str(animal.uid)
        response = self.client.post(self.url, {
            'changes': [{
                'uid': uid_str, 'arete': 'ORIG-01', 'especie': 'llama',
                'sexo': 'macho', 'fecha_nacimiento': '2023-01-01',
                'action': 'update'
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        animal.refresh_from_db()
        self.assertEqual(animal.especie, 'llama')

    def test_sync_delete_animal(self):
        animal = Animal.objects.create(
            uid=uuid.uuid4(), arete='DEL-01', especie='alpaca',
            sexo='macho', fecha_nacimiento='2023-01-01', usuario=self.user
        )
        uid_str = str(animal.uid)
        response = self.client.post(self.url, {
            'changes': [{
                'uid': uid_str, 'arete': 'DEL-01', 'especie': 'alpaca',
                'sexo': 'macho', 'fecha_nacimiento': '2023-01-01',
                'action': 'delete'
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        animal.refresh_from_db()
        self.assertFalse(animal.activo)
        self.assertIsNotNone(animal.deleted_at)

    def test_sync_returns_server_changes(self):
        response = self.client.post(self.url, {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('server_changes', response.data)
        self.assertIn('sync_timestamp', response.data)

    def test_sync_with_parent_references(self):
        padre = Animal.objects.create(
            uid=uuid.uuid4(), arete='SYNC-P', especie='alpaca',
            sexo='macho', fecha_nacimiento='2022-01-01', usuario=self.user
        )
        hijo_uid = str(uuid.uuid4())
        response = self.client.post(self.url, {
            'changes': [{
                'uid': hijo_uid, 'arete': 'SYNC-H', 'especie': 'alpaca',
                'sexo': 'hembra', 'fecha_nacimiento': '2024-01-01',
                'action': 'create', 'padre_uid': str(padre.uid)
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        hijo = Animal.objects.get(uid=hijo_uid)
        self.assertEqual(hijo.padre, padre)


class ReporteTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888777', telefono='999888777', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_animales')

    def test_reporte_csv_free_plan_denied(self):
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_reporte_csv_basico_allowed(self):
        self.user.plan = 'basico'
        self.user.save()
        Animal.objects.create(
            arete='RPT-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_reporte_pdf_criador_allowed(self):
        self.user.plan = 'criador'
        self.user.save()
        Animal.objects.create(
            arete='RPT-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_reporte_respects_filters(self):
        self.user.plan = 'criador'
        self.user.save()
        Animal.objects.create(
            arete='A-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user
        )
        Animal.objects.create(
            arete='A-02', especie='llama', sexo='hembra',
            fecha_nacimiento='2023-01-01', usuario=self.user
        )
        response = self.client.get(self.url, {'format': 'csv', 'especie': 'llama'})
        content = response.content.decode('utf-8')
        self.assertIn('A-02', content)
        self.assertNotIn('A-01', content)


class CategoriaEdadTests(APITestCase):
    def test_camelido_cria(self):
        result = calcular_categoria_edad('alpaca', date.today() - timedelta(days=120))
        self.assertEqual(result, 'cría')

    def test_camelido_tui_menor(self):
        result = calcular_categoria_edad('alpaca', date.today() - timedelta(days=300))
        self.assertEqual(result, 'tui_menor')

    def test_camelido_tui_mayor(self):
        result = calcular_categoria_edad('llama', date.today() - timedelta(days=540))
        self.assertEqual(result, 'tui_mayor')

    def test_camelido_adulto(self):
        result = calcular_categoria_edad('alpaca', date.today() - timedelta(days=1095))
        self.assertEqual(result, 'adulto')

    def test_ovino_cria(self):
        result = calcular_categoria_edad('ovino', date.today() - timedelta(days=60))
        self.assertEqual(result, 'cría')

    def test_ovino_borrego(self):
        result = calcular_categoria_edad('ovino', date.today() - timedelta(days=300))
        self.assertEqual(result, 'borrego')

    def test_ovino_adulto(self):
        result = calcular_categoria_edad('ovino', date.today() - timedelta(days=730))
        self.assertEqual(result, 'adulto')

    def test_none_on_future_date(self):
        result = calcular_categoria_edad('alpaca', date.today() + timedelta(days=1))
        self.assertIsNone(result)

    def test_none_on_empty_fecha(self):
        result = calcular_categoria_edad('alpaca', None)
        self.assertIsNone(result)

    def test_categoria_included_in_detail_response(self):
        Usuario.objects.create_user(
            username='999888778', telefono='999888778', password='123456'
        )
        self.client.force_authenticate(user=Usuario.objects.get(telefono='999888778'))
        animal = Animal.objects.create(
            arete='CAT-01', especie='alpaca', sexo='macho',
            fecha_nacimiento=date.today() - timedelta(days=1095),
            usuario=Usuario.objects.get(telefono='999888778')
        )
        response = self.client.get(reverse('animal-detail', kwargs={'pk': animal.uid}))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('categoria_edad', response.data)
        self.assertEqual(response.data['categoria_edad'], 'adulto')

    def test_categoria_included_in_list_response(self):
        Usuario.objects.create_user(
            username='999888779', telefono='999888779', password='123456'
        )
        self.client.force_authenticate(user=Usuario.objects.get(telefono='999888779'))
        Animal.objects.create(
            arete='CAT-L-01', especie='ovino', sexo='hembra',
            fecha_nacimiento=date.today() - timedelta(days=60),
            usuario=Usuario.objects.get(telefono='999888779')
        )
        response = self.client.get(reverse('animal-list'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('categoria_edad', response.data['results'][0])
        self.assertEqual(response.data['results'][0]['categoria_edad'], 'cría')


class ProduccionModelTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888780', telefono='999888780',
            password='123456', first_name='Prod'
        )
        self.animal = Animal.objects.create(
            arete='PRD-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )

    def test_create_produccion(self):
        p = Produccion.objects.create(
            animal=self.animal,
            fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('3.50'),
            rendimiento_pct=Decimal('78.5'),
            observaciones='Buena calidad'
        )
        self.assertIsNotNone(p.uid)
        self.assertEqual(p.peso_vellon_kg, Decimal('3.50'))
        self.assertEqual(p.rendimiento_pct, Decimal('78.5'))
        self.assertEqual(p.animal, self.animal)

    def test_produccion_defaults(self):
        p = Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('2.00')
        )
        self.assertIsNone(p.rendimiento_pct)
        self.assertEqual(p.observaciones, '')
        self.assertEqual(p.sync_status, SyncStatus.SIC)

    def test_animal_producciones_relation(self):
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-01-10',
            peso_vellon_kg=Decimal('3.00')
        )
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-20',
            peso_vellon_kg=Decimal('3.50')
        )
        self.assertEqual(self.animal.producciones.count(), 2)


class ProduccionAPITests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888781', telefono='999888781',
            password='123456', first_name='ProdAPI'
        )
        self.animal = Animal.objects.create(
            arete='PAPI-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )
        self.client.force_authenticate(user=self.user)
        self.nested_url = reverse('animal-producciones', kwargs={'pk': self.animal.uid})

    def _create_produccion(self, **kwargs):
        data = dict(
            fecha_esquila='2024-06-15',
            peso_vellon_kg='3.50',
            rendimiento_pct='78.5',
            observaciones='Test'
        )
        data.update(kwargs)
        return data

    def test_nested_list_producciones(self):
        Produccion.objects.create(
            uid=uuid.uuid4(), animal=self.animal,
            fecha_esquila='2024-06-15', peso_vellon_kg=Decimal('3.50')
        )
        response = self.client.get(self.nested_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_nested_create_produccion(self):
        data = self._create_produccion()
        response = self.client.post(self.nested_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('animal_uid', response.data)
        self.assertEqual(response.data['animal_uid'], str(self.animal.uid))
        self.assertEqual(Produccion.objects.count(), 1)

    def test_nested_create_rendimiento_null(self):
        data = self._create_produccion(rendimiento_pct=None)
        response = self.client.post(self.nested_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNone(response.data['rendimiento_pct'])

    def test_nested_create_future_date_fails(self):
        future = date.today() + timedelta(days=1)
        data = self._create_produccion(fecha_esquila=future.isoformat())
        response = self.client.post(self.nested_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_nested_create_zero_weight_fails(self):
        data = self._create_produccion(peso_vellon_kg='0')
        response = self.client.post(self.nested_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_standalone_get_produccion(self):
        p = Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('3.50')
        )
        url = reverse('produccion-detail', kwargs={'pk': p.uid})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('animal_uid', response.data)

    def test_standalone_update_produccion(self):
        p = Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('3.50')
        )
        url = reverse('produccion-detail', kwargs={'pk': p.uid})
        response = self.client.patch(url, {'peso_vellon_kg': '4.00'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        p.refresh_from_db()
        self.assertEqual(p.peso_vellon_kg, Decimal('4.00'))

    def test_standalone_delete_produccion(self):
        p = Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('3.50')
        )
        url = reverse('produccion-detail', kwargs={'pk': p.uid})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Produccion.objects.count(), 0)

    def test_standalone_post_disabled(self):
        url = reverse('produccion-list')
        response = self.client.post(url, {'fecha_esquila': '2024-06-15'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

    def test_other_user_cannot_access(self):
        other = Usuario.objects.create_user(
            username='999888782', telefono='999888782', password='123456'
        )
        other_animal = Animal.objects.create(
            arete='OTRO-01', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2022-01-01', usuario=other
        )
        p = Produccion.objects.create(
            animal=other_animal, fecha_esquila='2024-06-15',
            peso_vellon_kg=Decimal('3.50')
        )
        url = reverse('produccion-detail', kwargs={'pk': p.uid})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class ProduccionSyncTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='999888783', telefono='999888783',
            password='123456', first_name='SyncP'
        )
        self.animal = Animal.objects.create(
            arete='SYNCP-01', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )
        self.client.force_authenticate(user=self.user)

    def test_sync_with_produccion_create(self):
        prod_uid = uuid.uuid4()
        response = self.client.post(reverse('sync'), {
            'produccion_changes': [{
                'uid': str(prod_uid),
                'animal_uid': str(self.animal.uid),
                'fecha_esquila': '2024-06-15',
                'peso_vellon_kg': '3.50',
                'action': 'create',
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(Produccion.objects.filter(uid=prod_uid).exists())

    def test_sync_with_produccion_update(self):
        p = Produccion.objects.create(
            uid=uuid.uuid4(), animal=self.animal,
            fecha_esquila='2024-06-15', peso_vellon_kg=Decimal('3.00')
        )
        response = self.client.post(reverse('sync'), {
            'produccion_changes': [{
                'uid': str(p.uid),
                'animal_uid': str(self.animal.uid),
                'fecha_esquila': '2024-06-15',
                'peso_vellon_kg': '4.00',
                'action': 'update',
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        p.refresh_from_db()
        self.assertEqual(p.peso_vellon_kg, Decimal('4.00'))

    def test_sync_with_produccion_delete(self):
        p = Produccion.objects.create(
            uid=uuid.uuid4(), animal=self.animal,
            fecha_esquila='2024-06-15', peso_vellon_kg=Decimal('3.00')
        )
        response = self.client.post(reverse('sync'), {
            'produccion_changes': [{
                'uid': str(p.uid),
                'animal_uid': str(self.animal.uid),
                'fecha_esquila': '2024-06-15',
                'peso_vellon_kg': '3.00',
                'action': 'delete',
            }]
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(Produccion.objects.filter(uid=p.uid).exists())
