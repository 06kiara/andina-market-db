# Política de protección de datos personales y de pago – Andina Market

## 1. Objetivo y marco
Andina Market protege los datos personales de sus clientes y los datos de sus pagos. Esta política se basa en la **Ley N.º 29733, Ley de Protección de Datos Personales del Perú**, y en las buenas prácticas **PCI DSS** para datos de tarjetas. Los detalles legales finales deben validarse con asesoría legal.

## 2. Datos que se recopilan y cómo se tratan

| Dato | Dónde está | Sensibilidad | Tratamiento |
|---|---|---|---|
| Nombre, apellido, correo, teléfono | `Cliente` | Personal | Solo atención y la app; en análisis se ve enmascarado (`vista_clientes_enmascarada`) |
| Dirección de envío | `Direccion` | Personal | Solo atención y la app; se anonimiza al cancelar la cuenta |
| Titular, últimos 4 dígitos, marca, token de tarjeta | `Pago_Tarjeta` | Alta (pago) | Solo el rol de pagos; atención y análisis ven únicamente marca y últimos 4 dígitos |
| Teléfono y código de operación Yape/Plin | `Pago_YapePlin` | Alta (pago) | Solo el rol de pagos |
| Banco, número de operación, cuenta destino | `Pago_Transferencia` | Alta (pago) | Solo el rol de pagos |
| Pedidos, montos, reseñas | `Pedido`, `Pago`, `Resena` | Comercial | Acceso según rol; el análisis usa vistas agregadas |

## 3. Datos de pago
- **Nunca se guarda** el número completo de la tarjeta ni el código de seguridad (CVV).
- De la tarjeta solo se guardan los **últimos 4 dígitos**, la marca y un **token** entregado por el procesador de pagos.
- Los pagos de Yape/Plin y transferencia guardan únicamente lo necesario para conciliar la operación.

## 4. Finalidad y consentimiento
- Los datos se usan solo para vender, cobrar, enviar pedidos y atender reclamos.
- El cliente debe aceptar esta política al registrarse. Cualquier otro uso (por ejemplo, publicidad) requiere un consentimiento aparte.
- Se recopilan solo los datos necesarios para esas finalidades.

## 5. Control de acceso (mínimo privilegio)
Implementado en `proteccion_datos.sql`:

| Rol | Puede hacer |
|---|---|
| `rol_admin_bd` | Administrar la base; ejecuta la anonimización de clientes |
| `rol_atencion` | Ver clientes, pedidos y envíos; actualizar envíos; no ve datos de pago sensibles |
| `rol_analista` | Solo vistas sin datos identificables (ventas, catálogo, clientes y pagos enmascarados) |
| `rol_pagos` | Único rol con acceso a las tablas de pago |
| `rol_app_tienda` | Lo que necesita la tienda web; sin `DELETE` y sin acceso a pagos |

Cada persona usa su propio usuario con contraseña robusta; no se comparten cuentas.

## 6. Medidas de seguridad
- Conexiones a la base de datos cifradas (TLS/SSL).
- Contraseñas de usuarios de la base distintas y cambiadas periódicamente; las claves de ejemplo del script deben reemplazarse.
- Cifrado en reposo del servidor o disco donde está la base de datos.
- Copias de seguridad cifradas y con acceso restringido.
- Auditoría de cambios y eliminaciones en `Cliente` (`Auditoria_Datos`), sin guardar los valores modificados.

## 7. Conservación
- Los datos se conservan mientras el cliente tenga cuenta activa y mientras la ley exija guardar registros de ventas.
- El plazo exacto de conservación de comprobantes debe definirse con asesoría contable y legal.

## 8. Derechos del cliente (ARCO)
El cliente puede solicitar **acceso, rectificación, cancelación y oposición** sobre sus datos.
- **Cancelación:** se ejecuta `CALL sp_anonimizar_cliente(<id>)`. Se reemplazan nombre, correo, teléfono, dirección y datos del titular de pago; los pedidos y montos se mantienen sin identificar a la persona.
- Las solicitudes se responden por el canal de contacto indicado en la tienda.

## 9. Incidentes de seguridad
Si ocurre una filtración o acceso indebido: contener el incidente, revisar `Auditoria_Datos`, cambiar credenciales afectadas, avisar a los clientes afectados y a la autoridad cuando la ley lo exija.

## 10. Responsabilidades
- **Administrador de la base de datos:** mantiene roles, copias de seguridad y cifrado.
- **Equipo de la tienda:** usa solo los accesos de su rol y reporta cualquier incidente.
