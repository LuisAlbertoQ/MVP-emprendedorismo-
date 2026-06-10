from datetime import date


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
