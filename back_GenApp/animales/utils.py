from datetime import date, timedelta


def _edad_en_meses(fecha_nacimiento):
    hoy = date.today()
    meses = (hoy.year - fecha_nacimiento.year) * 12 + (hoy.month - fecha_nacimiento.month)
    if hoy.day < fecha_nacimiento.day:
        meses -= 1
    return meses


def calcular_categoria_edad(especie, fecha_nacimiento):
    if not fecha_nacimiento:
        return None
    hoy = date.today()
    if fecha_nacimiento > hoy:
        return None
    edad_meses = _edad_en_meses(fecha_nacimiento)
    if especie in ('alpaca', 'llama'):
        if edad_meses < 8:
            return 'cría'
        elif edad_meses < 12:
            return 'tui_menor'
        elif edad_meses < 24:
            return 'tui_mayor'
        else:
            return 'adulto'
    elif especie == 'ovino':
        if edad_meses < 4:
            return 'cría'
        elif edad_meses < 18:
            return 'borrego'
        else:
            return 'adulto'
    return None


PERIODO_GESTACION = {
    'alpaca': 345,
    'llama': 345,
    'ovino': 150,
}


def _ancestors_map(animal, depth=0):
    if animal is None or depth > 10:
        return {}
    result = {animal.uid: depth}
    if animal.padre:
        for uid, d in _ancestors_map(animal.padre, depth + 1).items():
            if uid not in result or d < result[uid]:
                result[uid] = d
    if animal.madre:
        for uid, d in _ancestors_map(animal.madre, depth + 1).items():
            if uid not in result or d < result[uid]:
                result[uid] = d
    return result


def calcular_coeficiente_consanguinidad(animal):
    padre, madre = animal.padre, animal.madre
    if not padre or not madre:
        return 0.0

    ancestros_padre = _ancestors_map(padre, 0)
    ancestros_madre = _ancestors_map(madre, 0)

    comunes = set(ancestros_padre.keys()) & set(ancestros_madre.keys())

    fx = 0.0
    for uid_ant in comunes:
        falta = _coeficiente_antepasado_por_uid(uid_ant, animal)
        n1 = ancestros_padre[uid_ant]
        n2 = ancestros_madre[uid_ant]
        fx += (0.5 ** (n1 + n2 + 1)) * (1 + falta)
    return round(fx, 6)


def _coeficiente_antepasado_por_uid(uid, animal_original):
    from .models import Animal
    try:
        ant = Animal.objects.get(uid=uid)
    except Animal.DoesNotExist:
        return 0.0
    if ant.padre and ant.madre and ant.uid != animal_original.padre.uid and ant.uid != animal_original.madre.uid:
        return calcular_coeficiente_consanguinidad(ant)
    return 0.0


def calcular_fecha_probable_parto(especie, fecha_empadre):
    if not fecha_empadre:
        return None
    dias = PERIODO_GESTACION.get(especie)
    if not dias:
        return None
    return fecha_empadre + timedelta(days=dias)
