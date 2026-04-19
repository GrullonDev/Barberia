# tool/

Scripts de mantenimiento que **NO** forman parte del bundle final de la app.

Se mantienen fuera de `lib/` para no incluirlos en producción ni contaminar
el árbol de imports. Ejecútalos manualmente cuando los necesites.

## Uso

```bash
# Listar todos los usuarios en Firestore (solo debug)
dart run tool/list_users_script.dart

# Listar solo clientes
dart run tool/list_clients_script.dart
```

Ambos scripts están protegidos por `kDebugMode`: se niegan a correr en release.
