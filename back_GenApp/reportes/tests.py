import uuid
from decimal import Decimal
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from usuarios.models import Usuario
from animales.models import Animal, Produccion, Empadre, Parto, Costo, VentaFibra


class ReporteAnimalesTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='ra1', telefono='ra1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_animales')

    def test_free_plan_denied(self):
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def _allow(self):
        self.user.plan = 'basico'
        self.user.save()

    def test_csv_basico_allowed(self):
        self._allow()
        Animal.objects.create(arete='A-01', especie='alpaca', sexo='macho',
                              fecha_nacimiento='2023-01-01', usuario=self.user)
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_criador_allowed(self):
        self.user.plan = 'criador'
        self.user.save()
        Animal.objects.create(arete='A-01', especie='alpaca', sexo='macho',
                              fecha_nacimiento='2023-01-01', usuario=self.user)
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_contains_new_columns(self):
        self._allow()
        Animal.objects.create(arete='A-01', especie='alpaca', sexo='macho',
                              raza='Huacaya', peso_nacimiento_kg=Decimal('7.5'),
                              fecha_nacimiento='2023-01-01', usuario=self.user)
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('Raza', content)
        self.assertIn('Peso Nac.', content)
        self.assertIn('Costo Total', content)
        self.assertIn('Huacaya', content)


class ReporteEsquilasTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='re1', telefono='re1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_esquilas')
        self.user.plan = 'basico'
        self.user.save()
        self.animal = Animal.objects.create(
            arete='E-01', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )

    def test_csv_ok(self):
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_contains_fiber_columns(self):
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_sucio_kg=Decimal('3.50'),
            diametro_fibra_micras=Decimal('22.5'),
            factor_confort=Decimal('95.0'),
            medulacion_pct=Decimal('1.2'),
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('Diámetro', content)
        self.assertIn('Confort', content)
        self.assertIn('Medulación', content)
        self.assertIn('22.5', content)

    def test_free_plan_denied(self):
        self.user.plan = 'free'
        self.user.save()
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class ReporteEmpadresTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='remp1', telefono='remp1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_empadres')
        self.user.plan = 'basico'
        self.user.save()
        self.hembra = Animal.objects.create(
            arete='EMP-H', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )
        self.macho = Animal.objects.create(
            arete='EMP-M', especie='alpaca', sexo='macho',
            fecha_nacimiento='2021-01-01', usuario=self.user
        )

    def test_csv_ok(self):
        Empadre.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, macho=self.macho,
            usuario=self.user, fecha_empadre='2024-01-15'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        Empadre.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, macho=self.macho,
            usuario=self.user, fecha_empadre='2024-01-15'
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_contains_resultado(self):
        Empadre.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, macho=self.macho,
            usuario=self.user, fecha_empadre='2024-01-15',
            resultado='positivo'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('Resultado', content)
        self.assertIn('Positivo', content)


class ReportePartosTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='rparto1', telefono='rparto1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_partos')
        self.user.plan = 'basico'
        self.user.save()
        self.hembra = Animal.objects.create(
            arete='P-H', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2021-01-01', usuario=self.user
        )

    def test_csv_ok(self):
        Parto.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, usuario=self.user,
            fecha_parto='2024-06-01', numero_crias=1
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        Parto.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, usuario=self.user,
            fecha_parto='2024-06-01', numero_crias=2,
            incidencias='Distocia'
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_shows_incidencias(self):
        Parto.objects.create(
            uid=uuid.uuid4(), hembra=self.hembra, usuario=self.user,
            fecha_parto='2024-06-01', numero_crias=1,
            incidencias='Aborto'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('Aborto', content)


class ReporteCostosTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='rc1', telefono='rc1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_costos')
        self.user.plan = 'basico'
        self.user.save()
        self.animal = Animal.objects.create(
            arete='C-A', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )

    def test_csv_ok(self):
        Costo.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            tipo='alimentacion', monto=Decimal('150.00'), fecha='2024-06-01'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        Costo.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            tipo='sanidad', monto=Decimal('80.00'), fecha='2024-06-01'
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_shows_tipo_monto(self):
        Costo.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            tipo='alimentacion', monto=Decimal('150.00'), fecha='2024-06-01'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('Alimentación', content)
        self.assertIn('150.00', content)


class ReporteVentasFibraTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='rvf1', telefono='rvf1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_ventas_fibra')
        self.user.plan = 'basico'
        self.user.save()
        self.animal = Animal.objects.create(
            arete='VF-A', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )

    def test_csv_ok(self):
        VentaFibra.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            kg_vendidos=Decimal('3.50'), precio_kg=Decimal('45.00'),
            fecha_venta='2024-06-15'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        VentaFibra.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            kg_vendidos=Decimal('2.00'), precio_kg=Decimal('50.00'),
            fecha_venta='2024-06-01', comprador='Juan Perez'
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_csv_shows_ingreso_total(self):
        VentaFibra.objects.create(
            uid=uuid.uuid4(), animal=self.animal, usuario=self.user,
            kg_vendidos=Decimal('3.50'), precio_kg=Decimal('45.00'),
            fecha_venta='2024-06-15'
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('157.50', content)


class ReporteRankingFibraTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='rrf1', telefono='rrf1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_ranking_fibra')
        self.user.plan = 'basico'
        self.user.save()
        self.animal = Animal.objects.create(
            arete='RF-A', especie='alpaca', sexo='macho',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )

    def test_csv_returns_empty_without_produccion(self):
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_csv_ok_with_data(self):
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_sucio_kg=Decimal('3.50'),
            diametro_fibra_micras=Decimal('22.5'),
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'text/csv')

    def test_pdf_ok(self):
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_sucio_kg=Decimal('3.50'),
            diametro_fibra_micras=Decimal('22.5'),
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')

    def test_ranking_ordered_by_diametro(self):
        a2 = Animal.objects.create(
            arete='RF-B', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2022-01-01', usuario=self.user
        )
        Produccion.objects.create(
            animal=self.animal, fecha_esquila='2024-06-15',
            peso_vellon_sucio_kg=Decimal('3.50'),
            diametro_fibra_micras=Decimal('25.0'),
        )
        Produccion.objects.create(
            animal=a2, fecha_esquila='2024-07-01',
            peso_vellon_sucio_kg=Decimal('3.00'),
            diametro_fibra_micras=Decimal('20.0'),
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        rf_a_pos = content.index('RF-A')
        rf_b_pos = content.index('RF-B')
        self.assertLess(rf_b_pos, rf_a_pos, 'Menor diámetro debe aparecer primero')


class ReporteConsanguinidadTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='rcons1', telefono='rcons1', password='123456'
        )
        self.client.force_authenticate(user=self.user)
        self.url = reverse('reporte_consanguinidad')
        self.user.plan = 'basico'
        self.user.save()

    def test_csv_empty_without_parents(self):
        Animal.objects.create(
            arete='NO-PARENTS', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user
        )
        response = self.client.get(self.url, {'format': 'csv'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertNotIn('NO-PARENTS', response.content.decode('utf-8'))

    def test_csv_shows_coeficiente(self):
        padre = Animal.objects.create(
            uid=uuid.uuid4(), arete='PADRE', especie='alpaca', sexo='macho',
            fecha_nacimiento='2021-01-01', usuario=self.user
        )
        madre = Animal.objects.create(
            uid=uuid.uuid4(), arete='MADRE', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2021-06-01', usuario=self.user
        )
        hijo = Animal.objects.create(
            uid=uuid.uuid4(), arete='HIJO', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user,
            padre=padre, madre=madre
        )
        response = self.client.get(self.url, {'format': 'csv'})
        content = response.content.decode('utf-8')
        self.assertIn('HIJO', content)
        self.assertIn('PADRE', content)
        self.assertIn('MADRE', content)
        self.assertIn('Coeficiente', content)

    def test_pdf_ok(self):
        padre = Animal.objects.create(
            uid=uuid.uuid4(), arete='P-PDF', especie='alpaca', sexo='macho',
            fecha_nacimiento='2021-01-01', usuario=self.user
        )
        madre = Animal.objects.create(
            uid=uuid.uuid4(), arete='M-PDF', especie='alpaca', sexo='hembra',
            fecha_nacimiento='2021-06-01', usuario=self.user
        )
        Animal.objects.create(
            uid=uuid.uuid4(), arete='H-PDF', especie='alpaca', sexo='macho',
            fecha_nacimiento='2023-01-01', usuario=self.user,
            padre=padre, madre=madre
        )
        response = self.client.get(self.url, {'format': 'pdf'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')


class ReporteFreePlanDeniedTests(APITestCase):
    def setUp(self):
        self.user = Usuario.objects.create_user(
            username='free_rep', telefono='free_rep', password='123456'
        )
        self.client.force_authenticate(user=self.user)

    def test_all_reportes_denied_for_free(self):
        for name in ['reporte_animales', 'reporte_esquilas', 'reporte_empadres',
                      'reporte_partos', 'reporte_costos', 'reporte_ventas_fibra',
                      'reporte_ranking_fibra', 'reporte_consanguinidad']:
            url = reverse(name)
            response = self.client.get(url, {'format': 'csv'})
            self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN,
                             f'{name} debe denegarse para plan free')
