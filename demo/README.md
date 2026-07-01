# Smart Edge Demo

Demo web estatica para validar acceso a un nodo Smart Edge/IaaS provincial.

La imagen incluye:

- Landing HTML servida con Nginx.
- Logo SVG de Telefonica.
- Region/nodo configurable con `EDGE_REGION`.
- Endpoint `/edge-config.json` para exponer la region configurada.
- Endpoint `/client-info.json` para mostrar la IP que ve Nginx.
- Test de latencia HTTP navegador -> nodo web.

## Construccion local

```bash
docker build -t smartedge-demo:1.0 .
```

## Ejecucion local

```bash
docker run -d \
  --name smartedge-demo \
  -p 80:80 \
  -e EDGE_REGION=Bilbao \
  smartedge-demo:1.0
```

Para cambiar el nodo no hace falta reconstruir la imagen:

```bash
docker run -d \
  --name smartedge-demo-madrid \
  -p 8080:80 \
  -e EDGE_REGION=Madrid \
  smartedge-demo:1.0
```

## Subida a GitHub

Crear el repositorio en GitHub, por ejemplo `smartedge-demo`, y despues:

```bash
cd /home/miguel/sf_docsOpenClaw/Smartedge/demo
git init
git add .
git commit -m "Add Smart Edge demo container"
git branch -M main
git remote add origin git@github.com:<usuario-o-organizacion>/smartedge-demo.git
git push -u origin main
```

Si el remoto usa HTTPS:

```bash
git remote add origin https://github.com/<usuario-o-organizacion>/smartedge-demo.git
```

## Publicacion como imagen reutilizable

Ejemplo con GitHub Container Registry:

```bash
docker login ghcr.io
docker build -t ghcr.io/<usuario-o-organizacion>/smartedge-demo:1.0 .
docker push ghcr.io/<usuario-o-organizacion>/smartedge-demo:1.0
```

Ejecucion desde registry:

```bash
docker run -d \
  --name smartedge-demo \
  -p 80:80 \
  -e EDGE_REGION=Bilbao \
  ghcr.io/<usuario-o-organizacion>/smartedge-demo:1.0
```

## OpenStack User Data

Usa `openstack-user-data.yaml` como script de arranque cloud-init. Antes de pegarlo al crear la instancia, cambia:

- `IMAGE_REF`: referencia de la imagen publicada.
- `EDGE_REGION`: nombre del nodo o region que quieras mostrar.

El script esta preparado para imagenes Ubuntu/Debian con `apt`. Si publicas la imagen en GHCR como privada, rellena tambien `REGISTRY_HOST`, `REGISTRY_USER` y `REGISTRY_TOKEN` en el bloque de entorno del User Data, o el `docker pull` fallara.

El workflow de GitHub Actions publica `ghcr.io/<usuario-o-organizacion>/smartedge-demo:latest` al hacer push a `main`. Si quieres una version fija, crea un tag Git como `v1.0`; el workflow publicara tambien esa etiqueta.

## Uso con Application Endpoint Discovery

En Operator Platform, el parametro de endpoint path debe apuntar a una ruta HTTP que esta imagen sirva correctamente. Para esta demo puedes usar:

- Protocolo: `http`
- Path: `/`

Si prefieres diferenciar la version MPLS/AED de la version publica, tambien puedes configurar un path como `/smartedge-demo`. Nginx sirve igualmente la landing en cualquier ruta no existente gracias a `try_files ... /index.html`, y los recursos de la pagina usan rutas absolutas para seguir funcionando desde paths no raiz.

AED no llama a una API dentro de este contenedor. La aplicacion inteligente llama a la API AED de Operator Platform, obtiene el endpoint recomendado y despues abre la URL devuelta. Por eso el requisito del servidor es que la ruta configurada responda correctamente por HTTP desde la red privada/MPLS.

En una version puramente MPLS, la geolocalizacion por `ipwho.is` puede no funcionar si el cliente no tiene salida a Internet o si la IP es privada. La demo lo degrada mostrando la IP vista por Nginx y marcando la ubicacion/operador como no disponible si no puede resolverlo.

## Limitaciones

- La latencia medida es HTTP navegador -> nodo web. No es ping ICMP.
- La IP mostrada es la que ve Nginx. Si hay proxy o balanceador delante, configura cabeceras de IP real en Nginx y rangos de confianza.
- La geolocalizacion/operador depende de un servicio externo llamado desde el navegador: `ipwho.is`.
