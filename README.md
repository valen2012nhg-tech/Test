# Addon: DRGBase Nexbot Cazador

Este repositorio incluye el addon con el formato correcto de Garry's Mod:

```text
drg_cazador_nexbot/
├─ addon.json
└─ lua/
   └─ entities/
      └─ drg_nexbot_cazador/
         ├─ cl_init.lua
         ├─ init.lua
         └─ shared.lua
```

## Instalación correcta
1. Instala DRGBase desde Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=1560118657
2. Descarga este repo (ZIP o `git clone`).
3. Copia **la carpeta `drg_cazador_nexbot`** completa dentro de:
   `Steam/steamapps/common/GarrysMod/garrysmod/addons/`
4. Debe quedar así:
   `garrysmod/addons/drg_cazador_nexbot/lua/entities/drg_nexbot_cazador/...`

## Uso
- Abre Garry's Mod.
- Menú de entidades → categoría `DRGBase Nextbots`.
- Spawnea `DRG Cazador`.

## Entidad
- Clase: `drg_nexbot_cazador`
- Base: `drgbase_nextbot`
- Comportamiento: persigue al jugador humano vivo más cercano y lo ataca al entrar en rango.
