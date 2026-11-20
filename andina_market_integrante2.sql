SELECT P.pago_id, P.tipo_pago, P.monto, T.marca_tarjeta, Y.plataforma, C.monto_recibido
FROM Pago P
LEFT JOIN Pago_Tarjeta T ON P.pago_id = T.pago_id
LEFT JOIN Pago_YapePlin Y ON P.pago_id = Y.pago_id
LEFT JOIN Pago_Contraentrega C ON P.pago_id = C.pago_id;