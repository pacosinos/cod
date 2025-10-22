# cod

Script para grabar IQ desde varias KiwiSDR sincronizadas al siguiente minuto UTC.

```bash
./record_kiwi.sh
```

El script comprobará si tienes `kiwirecorder.py` disponible. Si no lo encuentra en
`$HOME/kiwiclient`, intentará clonar automáticamente el repositorio oficial
(`https://github.com/jks-prv/kiwiclient`) y mantenerlo actualizado con `git pull`.

Puedes personalizar las variables exportándolas antes de ejecutar el script:

- `KIWI_DIR`: ruta al cliente `kiwirecorder.py` (por defecto `~/kiwiclient`).
- `KIWICLIENT_REPO`: origen desde el que clonar el cliente si no está instalado.
- `FREQ`: frecuencia a sintonizar, en formato aceptado por kiwirecorder (p. ej. `77.50k`).
- `FS`: tasa de muestreo.
- `DUR`: duración de la grabación en segundos.
- `OUTDIR`: directorio donde guardar las capturas.
- `KIWI_PWD`: contraseña si el receptor la requiere.
- `KIWI_HOSTS`: lista separada por comas con los KiwiSDR a utilizar (formato `host:puerto`).

La lista de KiwiSDR también se puede editar directamente en el script (`HOSTS`).
