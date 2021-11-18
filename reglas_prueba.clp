; NO TENEMOS IMPLEMENTADO LO DE RONDA FINAL?


; ESTO SE ACTIVA DESPUES DE TOMAR_RECURSO_OFERTA?????? POR QUÉ
(defrule DESTAPAR_LOSETA
    ; obtener casilla y que esté oculta.
    ?casilla <- (object (is-a LOSETA) (posicion ?pos) (visibilidad FALSE))
    ; comprobar que hay un jugador en la casilla
    ?posicion_jugador <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos) (nombre_jugador ?))
    =>
    ; hacer casilla visible
    (modify-instance ?casilla (visibilidad TRUE))
    (printout t"=====================================================================================================" crlf)
    (printout t"La loseta con posición : <" ?pos "> queda visible. " crlf)
)

(defrule PAGAR_INTERESES_FRANCOS
    ; obtiene el jugador
    ?jugador <- (object(is-a JUGADOR)(nombre ?nombre)(deudas ?deudas))
    ; obtiene los recursos del jugador
    ?jugador_recursos <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre) (recurso FRANCO) (cantidad ?cantidad_francos))
    ; obtiene la posición del jugador
    ?jugador_loseta <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos) (nombre_jugador ?nombre))
    ; la loseta tiene pago de intereses
    ?loseta <- (object (is-a LOSETA) (posicion ?pos) (visibilidad TRUE) (intereses TRUE))
    ; el jugador tiene deudas 
    (test (> ?deudas 0))
    ; el jugador tiene dinero para pagarlo
    (test (> ?cantidad_francos 0))
    ; fin actividad principal
    (fin_actividad_principal ?nombre)
    (ronda_actual ?ronda)
    (not (jugador_intereses_pagados ?nombre ?ronda))
    =>
    ; restar dinero al jugador
    (modify-instance ?jugador_recursos (cantidad (- ?cantidad_francos 1)))
    (assert (jugador_intereses_pagados ?nombre ?ronda))
    (printout t"=====================================================================================================" crlf)
    (printout t"El jugador <" ?nombre "> ha pagado intereses por sus deudas." crlf)
)

(defrule PAGAR_INTERESES_ENDEUDANDOSE
     ; obtiene el jugador
     ?jugador <- (object(is-a JUGADOR)(nombre ?nombre)(deudas ?deudas))
     ; obtiene los recursos del jugador
     ?jugador_recursos <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre) (recurso FRANCO)(cantidad ?cantidad_francos))
     ; obtiene la posición del jugador
     ?jugador_loseta <- (object (is-a JUGADOR_ESTA_EN_LOSETA)(posicion ?pos)(nombre_jugador ?nombre))
     ; la loseta tiene pago de intereses
     ?loseta <- (object (is-a LOSETA)(posicion ?pos)(visibilidad TRUE)(intereses TRUE))
     ; el jugador tiene al menos una deuda.
     (test (> ?deudas 0))
     ; el jugador NO tiene dinero para pagarlo
     (test (< ?cantidad_francos 1))

    ; fin actividad principal
    (fin_actividad_principal ?nombre)
    (ronda_actual ?ronda)
    (not (jugador_intereses_pagados ?nombre ?ronda))
     =>
     ; aumentar deuda del jugador en 1
     (modify-instance ?jugador (deudas (+ ?deudas 1)))
     ; una deuda otorga 4 francos, pero al necesitarla para pagar 
     (modify-instance ?jugador_recursos (cantidad (+ ?cantidad_francos 3)))
     (assert (jugador_intereses_pagados ?nombre ?ronda))
     (printout t"=====================================================================================================" crlf)
     (printout t"El jugador <" ?nombre "> ha pagado intereses por sus deudas, ¡endeudándose aún más! " crlf)

)
(defrule ACTUALIZAR_MAZO
	?ref <- (actualizar_mazo ?id ?numero_actualizaciones_restante ?pos1)
    ?carta_mazo1 <- (object (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id) (nombre_carta ?nombre_carta) (posicion_en_mazo ?pos1))
	;(not (carta_actualizada ?nombre_carta1 ?id ?pos1))
	(test (> ?numero_actualizaciones_restante 0))
	=>
	(modify-instance ?carta_mazo1(posicion_en_mazo (- ?pos1 1)))
	(retract ?ref)
	(assert (actualizar_mazo ?id (- ?numero_actualizaciones_restante 1) (+ ?pos1 1)))
	;(assert (carta_actualizada ?nombre_carta1 ?id ?pos1))
    (printout t"El mazo <" ?id "> ha actualizado la posición de la carta <" ?nombre_carta ">, ahora se encuentra en la posción <" (- ?pos1 1) ">." crlf)
)

(defrule FIN_ACTUALIZAR_MAZO
	(object (is-a MAZO) (id_mazo ?id) (numero_cartas_en_mazo ?num_cartas_en_mazo))
	?ref <- (actualizar_mazo ?id 0 ?)
	=>
	(retract ?ref)
	(printout t"mazo finalizado" crlf)
)

(defrule COMPRAR_EDIFICIO_AL_AYUNTO
    ; Se puede comprar en la ronda actual. [en todas las rondas excepto la última.]
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Obtener el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; Obtener el edificio del deseo
    ?deseo <- (deseo_comprar_edificio ?nombre_jugador ?nombre_edificio)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; El edificio es del ayuntamiento
    ?ayunto <- (EDIFICIO_AYUNTAMIENTO (nombre_edificio ?nombre_edificio))
    ; Obtiene el coste de comprar el edificio
    (object (is-a CARTA) (nombre ?nombre_edificio) (valor ?valor_edificio))
    ; Obtiene el dinero del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    ; El jugador tiene suficiente dinero
    (test (>= ?cantidad_recurso ?valor_edificio))
    =>
    ; Modificar el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (- ?cantidad_recurso ?valor_edificio)))
    ; Quitar el edificio al ayuntamiento
    (retract ?ayunto)
    ; Asignar el edificio al jugador
    (make-instance of JUGADOR_TIENE_CARTA (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_edificio))
    ; Eliminar el deseo de comprar el edificio
    (retract ?deseo)
    (printout t"El jugador: <" ?nombre_jugador "> ha comprado el edificio: <" ?nombre_edificio "> por <" ?valor_edificio "> francos al ayuntamiento." crlf)
)

;   4-. Comprar barco
(defrule COMPRAR_BARCO
    ; Se puede comprar en la ronda actual. [en todas las rondas excepto la última.]
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; Existe el deseo de comprar el barco
    ?deseo <- (deseo_comprar_barco ?nombre_jugador ?nombre_barco)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; El barco está disponible
    ?disponible <- (BARCO_DISPONIBLE (nombre_barco ?nombre_barco))
    ; El barco es el primero de su mazo
    ?barco_en_mazo <- (object  (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id_mazo) (nombre_carta ?nombre_barco) (posicion_en_mazo 1))
    ; El jugador tiene dinero para comprarlo
    ; Obtiene el coste de comprar el barco
    (object (is-a BARCO) (nombre ?nombre_barco) (coste ?coste_barco) (valor ?)(uds_comida_genera ?uds_comida_genera)(capacidad_envio ?capacidad_envio_barco))
    ; Obtiene el dinero del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    ; El jugador tiene suficiente dinero
    (test (>= ?cantidad_recurso ?coste_barco))
    ; se obtiene al jugador
    ?jugador <- (object (is-a JUGADOR)(nombre ?nombre_jugador)(num_barcos ?num_barcos)(capacidad_envio ?capacidad_envio_jugador)(demanda_comida_cubierta ?demanda_comida_cubierta))
    =>
    ; Modificar el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (- ?cantidad_recurso ?coste_barco)))
    ; Quitar la carta del mazo
    (unmake-instance ?barco_en_mazo)
    ; Asignar el barco al jugador
    (make-instance of JUGADOR_TIENE_CARTA (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_barco))
    ; Actualiza los valores relacionados con el barco en el jugador
    (modify-instance ?jugador (num_barcos (+ ?num_barcos 1)) (capacidad_envio (+ ?capacidad_envio_jugador ?capacidad_envio_barco)) (demanda_comida_cubierta (+ ?demanda_comida_cubierta ?uds_comida_genera)))
    ; Eliminar el deseo de comprar el barco
    (retract ?deseo)
    ; Quitar el barco de disponibles
    (retract ?disponible)
    ; Generar hecho semáforo para actualizar el orden de las cartas del mazo
    (assert (actualizar_mazo ?id_mazo))
)

(defrule COMPRAR_EDIFICIO_AL_MAZO
    ; Se puede comprar en la ronda actual. [en todas las rondas excepto la última.]
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Obtener el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; Obtener el edificio del deseo
    ?deseo <- (deseo_comprar_edificio ?nombre_jugador ?nombre_edificio)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; El edificio es del mazo
    ?carta_en_mazo <- (object (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id_mazo) (nombre_carta ?nombre_edificio) (posicion_en_mazo 1))
    ; Obtiene el coste de comprar el edificio
    (object (is-a CARTA) (nombre ?nombre_edificio) (tipo ?) (valor ?valor_edificio))
    ; Obtiene el dinero del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    ; El jugador tiene suficiente dinero
    (test (>= ?cantidad_recurso ?valor_edificio))
    ; el edificio no es el banco
    (test (neq ?nombre_edificio "BANCO"))
    ; obtener el mazo y actualizarlo.
    ?mazo <- (object (is-a MAZO) (id_mazo ?id_mazo) (numero_cartas_en_mazo ?cartas_en_mazo))
    =>
    ; Modificar el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (- ?cantidad_recurso ?valor_edificio)))
    ; Quitar la carta del mazo y mover todas las cartas 1 posición
    (unmake-instance ?carta_en_mazo)
    ; Asignar el edificio al jugador
    (make-instance of JUGADOR_TIENE_CARTA (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_edificio))
    ; Eliminar el deseo de comprar el edificio
    (retract ?deseo)
    ; Generar hecho semáforo para actualizar el orden de las cartas del mazo
    (assert (actualizar_mazo ?id_mazo))
    ; actualizar 
    (modify-instance ?mazo (numero_cartas_en_mazo (- ?cartas_en_mazo 1)))
    (printout t"El jugador: <" ?nombre_jugador "> ha comprado el edificio: <" ?nombre_edificio "> por <" ?valor_edificio "> francos al mazo." crlf)
)

(defrule COMPRAR_EDIFICIO_BANCO_DEL_MAZO
    ; Se puede comprar en la ronda actual. [en todas las rondas excepto la última.]
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Obtener el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; Obtener el edificio del deseo
    ?deseo <- (deseo_comprar_edificio ?nombre_jugador ?nombre_edificio)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; El edificio es del mazo
    ?carta_en_mazo <- (object (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id_mazo) (nombre_carta ?nombre_edificio) (posicion_en_mazo 1))
    ; Obtiene el coste de comprar el edificio
    (object (is-a CARTA_BANCO) (nombre ?nombre_edificio) (coste ?valor_edificio) (valor ?))
    ; Obtiene el dinero del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    ; El jugador tiene suficiente dinero
    (test (>= ?cantidad_recurso ?valor_edificio))
    ; obtener el mazo y actualizarlo.
    ?mazo <- (object (is-a MAZO) (id_mazo ?id_mazo) (numero_cartas_en_mazo ?cartas_en_mazo))
    =>
    ; Modificar el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (- ?cantidad_recurso ?valor_edificio)))
    ; Quitar la carta del mazo y mover todas las cartas 1 posición
    (unmake-instance ?carta_en_mazo)
    ; Asignar el edificio al jugador
    (make-instance of JUGADOR_TIENE_CARTA (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_edificio))
    ; Eliminar el deseo de comprar el edificio
    (retract ?deseo)
    ; Generar hecho semáforo para actualizar el orden de las cartas del mazo
    (assert (actualizar_mazo ?id_mazo))
    ; actualizar mazo
    (modify-instance ?mazo (numero_cartas_en_mazo (- ?cartas_en_mazo 1)))
    (printout t"El jugador: <" ?nombre_jugador "> ha comprado el edificio: <" ?nombre_edificio "> por <" ?valor_edificio "> francos al mazo." crlf)
)

(defrule VENDER_CARTA
    ; No existe precondición de ronda! 
    ; Existe un deseo de vender un edificio
    ?deseo <- (deseo_vender_carta ?nombre_jugador ?nombre_carta)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; Es el turno del jugador
    (turno ?nombre_jugador)
    ; El jugador tiene la carta. 
    ?edificio_jugador <- (object (is-a JUGADOR_TIENE_CARTA) (nombre_jugador ?nombre_jugador)(nombre_carta ?nombre_carta))
    ; referencia de la carta para obtener su valor. 
    ?carta <- (object (is-a CARTA) (nombre ?nombre_carta) (valor ?valor_carta))
    ; referencia del recurso del jugador.
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    =>
    ; obtener el beneficio de la venta de la carta.
    (bind ?ingreso (/ ?valor_carta 2))
    ; Modificar el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (+ ?cantidad_recurso ?ingreso)))
    ; Asignar edificio al ayuntamiento
    (assert (EDIFICIO_AYUNTAMIENTO (nombre_edificio ?nombre_carta)))
    ; Quitarle el edificio al jugador
    (unmake-instance ?edificio_jugador)
    ; quitar el deseo.
    (retract ?deseo)
    ; print final
    (printout t"El jugador: <" ?nombre_jugador "> ha vendido el edificio: <" ?nombre_carta "> por <" ?ingreso "> francos." crlf)
)

; NO SE AÑADE AL MAZO....
(defrule VENDER_BARCO
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; Existe el deseo de vender el barco
    ?deseo <- (deseo_vender_barco ?nombre_jugador ?nombre_barco)
    ; Ha finalizado su actividad principal dentro de su turno.
    (fin_actividad_principal ?nombre_jugador)
    ; El barco es del jugador
    ?jugador_tiene_barco <- (object (is-a JUGADOR_TIENE_CARTA) (nombre_jugador ?nombre_jugador)(nombre_carta ?nombre_barco))
    ; Obtiene el valor del barco
    ?barco <- (object (is-a BARCO)(nombre ?nombre_barco)(coste ?coste_barco)(valor ?valor_barco)(uds_comida_genera ?uds_comida_genera)(capacidad_envio ?capacidad_envio_barco))
    ; Obtiene el dinero del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_recurso))
    ; se obtiene al jugador
    ?jugador <- (object (is-a JUGADOR)(nombre ?nombre_jugador)(num_barcos ?num_barcos)(capacidad_envio ?capacidad_envio_jugador)(demanda_comida_cubierta ?demanda_comida_cubierta))
    ; Obtener el mazo del barco
    (barco_pertenece_mazo ?nombre_barco ?id_mazo)
    ?mazo_barco <- (object(is-a MAZO)(id_mazo ?id_mazo)(numero_cartas_en_mazo ?num_cartas_mazo))

    =>
    ; Elimina el barco del jugador
    (unmake-instance ?jugador_tiene_barco)
    ; Actualiza los valores relacionados con el barco en el jugador
    (modify-instance ?jugador (num_barcos (- ?num_barcos 1)) (capacidad_envio (- ?capacidad_envio_jugador ?capacidad_envio_barco)) (demanda_comida_cubierta (- ?demanda_comida_cubierta ?uds_comida_genera)))
    ; Actualiza el dinero del jugador
    (modify-instance ?recurso_jugador (cantidad (+ ?cantidad_recurso (/ ?valor_barco 2))))
    ; Insertar el barco en el mazo
    (make-instance of CARTA_PERTENECE_A_MAZO (?nombre_barco)(?id_mazo))
    (modify-instance ?mazo_barco (numero_cartas_en_mazo (+ ?num_cartas_mazo 1)))
    ; Elimina el deseo
    (retract ?deseo)
)


(defrule PAGAR_DEUDA
    ; Para simplificar la ejecución, debe ser el turno del jugador
    (turno ?nombre_jugador)
    ; Además, simplificamos para que haya terminado la actividad principal
    (fin_actividad_principal ?nombre_jugador)
    ; obtiene las deudas del jugador
    ?jugador <- (object (is-a JUGADOR) (nombre ?nombre_jugador) (deudas ?numero_deudas))
    ; deseo de pagar deudas
    ; todo: el jugador en una regla estratégica deberá comprobar cuanta deuda quiere pagar.
    ?deseo <- (deseo_pagar_deuda ?nombre_jugador ?numero_deudas_deseo)
    ; Obtener los francos del jugador
    ?jugador_dinero <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_francos))
    ;(bind cantidad_a_pagar (min (* 5 ?deudas) ?cantidad_deuda))
    (test (> ?cantidad_francos (* 5 ?numero_deudas_deseo)))
    =>
    (modify-instance ?jugador_dinero (cantidad (- ?cantidad_francos (* 5 ?numero_deudas_deseo))))
    (modify-instance ?jugador (deudas (- ?numero_deudas ?numero_deudas_deseo)))
    (retract ?deseo)
    (printout t"El jugador <" ?nombre_jugador "> ha pagado <" ?numero_deudas_deseo "> por un valor de <" (* 5 ?numero_deudas_deseo) ">." crlf)
)

(defrule AÑADIR_CARTA_AYUNTO_FINAL_RONDA
    ; encontrarse en el cambio de ronda.
    (cambiar_ronda TRUE)
    ; ronda actual
    (ronda_actual ?nombre_ronda_actual)
    ; la ronda actual asigna un edificio al ayunto.
    ?asignacion_edificio <- (object (is-a RONDA_ASIGNA_EDIFICIO) (nombre_ronda ?nombre_ronda_actual) (id_mazo ?id_mazo))
    ; el mazo tiene que tener más de 1 carta.
    ?ref_mazo <- (object (is-a MAZO) (id_mazo ?id_mazo) (numero_cartas_en_mazo ?num_cartas_en_mazo))
    (test (> ?num_cartas_en_mazo 0))
    ; seleccionar la primera carta del mazo.
    ?carta_en_mazo <- (object (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id_mazo) (nombre_carta ?nombre_edificio) (posicion_en_mazo 1))
    =>
    ; Eliminar carta mazo.
    (unmake-instance ?carta_en_mazo)
    ; indicar que el edificio se encuentra ahora en el ayunto.
    (assert (EDIFICIO_AYUNTAMIENTO (nombre_edificio ?nombre_edificio)))
    ; actualiza el numero de cartas en el mazo.
    (modify-instance ?ref_mazo (numero_cartas_en_mazo (- ?num_cartas_en_mazo 1)))
    ; Generar hecho semáforo para actualizar el orden de las cartas del mazo
    (assert (actualizar_mazo ?id_mazo (- ?num_cartas_en_mazo 1) 2))
    ; Elimina la instancia de ronda_asigna_edificio
    (unmake-instance ?asignacion_edificio)
    ; semáforo para pasar de ronda 
    (assert (edificio_entregado ?nombre_ronda_actual))
    (printout t"Se ha añadido el edificio: <" ?nombre_edificio "> al Ayuntamiento desde el mazo <" ?id_mazo ">." crlf)
)

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; Si el nº de barcos y satisface la demanda de comida, ninguna regla de pagar demanda se inicializa
; posible crear una regla que solo indique ese caso específico para hacer un log por completitud!

(defrule PAGAR_DEMANDA_COMIDA
    ; Si el jugador no tuviese recursos suficientes, tomará automáticamente una deuda.
    ; semáforo cambiar ronda
    (cambiar_ronda TRUE)
    ; obtener los datos del jugador.
    (object (is-a JUGADOR) (nombre ?nombre_jugador))
    ; obtener los datos de la ronda.
    (ronda_actual ?ronda)
    (object (is-a RONDA) (nombre_ronda ?ronda) (coste_comida ?coste_ronda))
    ; deseo de pagar la demanda de la ronda con los recursos del jugador.
    ?deseo <- (deseo_pagar_demanda ?nombre_jugador ?deseo_pagar_pescado ?deseo_pagar_pescado_ahumado ?deseo_pagar_pan ?deseo_pagar_carne ?deseo_pagar_francos)
    ; obtener los recursos del jugador.
    ?jugador_pescado <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PESCADO) (cantidad ?cantidad_pescado))
    ?jugador_pescado_ahumado <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PESCADO_AHUMADO) (cantidad ?cantidad_pescado_ahumado))
    ?jugador_pan <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PAN) (cantidad ?cantidad_pan))
    ?jugador_carne <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARNE) (cantidad ?cantidad_carne))
    ?jugador_francos <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_francos))
    ; obtener contador de pagar comida.
    ?comida_restante <- (cantidad_comida_demandada ?nombre_jugador ?ronda ?cantidad_queda_por_pagar)
    ; queda por pagar una cantidad distinta de 0.
    (test (> ?cantidad_queda_por_pagar 0))     
    =>
    (bind ?total_recursos_para_pagar (+ (* ?cantidad_pescado 1) (* ?cantidad_pescado_ahumado 2)  (* ?cantidad_pan 3) (* ?cantidad_carne 3) (* ?cantidad_francos 1) ))
    (modify-instance ?jugador_pescado (cantidad (- ?cantidad_pescado ?deseo_pagar_pescado)))
    (modify-instance ?jugador_pescado_ahumado (cantidad (- ?cantidad_pescado_ahumado ?deseo_pagar_pescado_ahumado)))
    (modify-instance ?jugador_pan (cantidad (- ?cantidad_pan ?deseo_pagar_pan)))
    (modify-instance ?jugador_carne (cantidad (- ?cantidad_carne ?deseo_pagar_carne)))
    (modify-instance ?jugador_francos (cantidad (- ?cantidad_francos ?deseo_pagar_francos)))

    ; restar a comida por pagar la cantidad que el jugador pueda pagar con sus propios recursos
    (retract ?comida_restante )
    ; AÑADIDO MÁXIMO  Y DEJO DESEO PARA EJECUTAR TODAS LAS RONDA ======================================================================================================================
    (assert (cantidad_comida_demandada ?nombre_jugador ?ronda (max 0 (- ?cantidad_queda_por_pagar ?total_recursos_para_pagar)) ))
    ; eliminar deseo.
    ;(retract ?deseo)
    (printout t"Coste de ronda: <" ?coste_ronda "> y recursos disponibles jugador: <" ?total_recursos_para_pagar">." crlf)
    (printout t"El jugador <" ?nombre_jugador "> ha pagado la demanda de comida de la ronda <" ?ronda ">. Le queda por pagar <" (- ?cantidad_queda_por_pagar ?total_recursos_para_pagar)"> unidad(es)." crlf)
)

; comprobar
(defrule PAGAR_COMIDA_ENDEUDANDOSE
    ; se está en medio de un cambio de ronda.
    (cambiar_ronda TRUE)
    ; obtener los datos del jugador.
    ?jugador <- (object (is-a JUGADOR) (nombre ?nombre_jugador)(deudas ?deudas))
    ; obtener los datos de la ronda.
    (ronda_actual ?ronda)
    ; obtener los recursos del jugador.
    ?jugador_pescado <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso PESCADO) (cantidad 0))
    ?jugador_pescado_ahumado <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso PESCADO_AHUMADO) (cantidad 0))
    ?jugador_pan <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso PAN) (cantidad 0))
    ?jugador_carne <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso CARNE) (cantidad 0))
    ?jugador_francos <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad 0))
    
    ; obtener contador de pagar comida.
    ?comida_restante <- (cantidad_comida_demandada ?nombre_jugador ?ronda ?cantidad_queda_por_pagar)
     ; queda por pagar una cantidad distinta de 0.
    (test (> ?cantidad_queda_por_pagar 0))
    =>
    ; Calcular cuántos préstamos hay que tomar para poder pagar toda la comida
    ; IMPLEMENTA LA FUNCIÓN CEIL: c = comida a pagar, v = valor deuda :
    ;       préstamos a tomar = (c / v)+(1-((c mod v) / v))
    (bind ?deudas_a_obtener (+ (/ ?cantidad_queda_por_pagar 4) (- 1 (/ (mod ?cantidad_queda_por_pagar 4) 4))))

    (modify-instance ?jugador (deudas (+ ?deudas ?deudas_a_obtener)))
    (modify-instance ?jugador_francos (cantidad (- (* ?deudas_a_obtener 4) ?cantidad_queda_por_pagar)))
    ; actualizar hecho de cantidad comida demandada.
    (retract ?comida_restante)
    (assert (cantidad_comida_demandada ?nombre_jugador ?ronda 0))

    (printout t"<"?nombre_jugador"> ha tomado <"?deudas_a_obtener"> deuda(s) para poder pagar <"?cantidad_queda_por_pagar"> unidad(es) de comida demandada restante(s)." crlf)
)

(defrule AÑADIR_GANADO_POR_COSECHA
    (ronda_actual ?nombre_ronda_actual)
    ; precondiciones de ejecución: se ejecutará por cada jugador que se le añada algo.
    (object (is-a RONDA) (nombre_ronda ?nombre_ronda_actual) (hay_cosecha TRUE))
    ; cuando ambos jugadores hayan pagado su demanda, se añadirá la cosecha
    (object (is-a JUGADOR) (nombre ?nombre_jugador1) )
    (object (is-a JUGADOR) (nombre ?nombre_jugador2) )
    (test (neq ?nombre_jugador1 ?nombre_jugador2))
    
    ; iniciar contadores para llevar registro de la comida que falta por pagar.
    (cantidad_comida_demandada ?nombre_jugador1 ?nombre_ronda_actual ?cantidad_pendiente_jugador1)
    (cantidad_comida_demandada ?nombre_jugador2 ?nombre_ronda_actual ?cantidad_pendiente_jugador2)
    
    (test (<= ?cantidad_pendiente_jugador1 0))
    (test (<= ?cantidad_pendiente_jugador2 0))

    ; no haya pillado cosecha
    (not (cosechado ?nombre_jugador1 ?nombre_ronda_actual GANADO))
    ; recursos jugador.  
    ?ganado_jugador1 <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador1) (recurso GANADO) (cantidad ?cantidad_ganado))
    ; comprobar cantidades.
    (test (> ?cantidad_ganado 1))
    =>
    (modify-instance ?ganado_jugador1 (cantidad (+ ?cantidad_ganado 1)))
    ; bloquear que se ejecute varias veces.
    (assert (cosechado ?nombre_jugador1 ?nombre_ronda_actual GANADO))
    (printout t"El jugador <" ?nombre_jugador1 "> ha recibido de la cosecha +1 GANADO." crlf)
)

(defrule AÑADIR_GRANO_POR_COSECHA
    (ronda_actual ?nombre_ronda_actual)
    ; precondiciones de ejecución: se ejecutará por cada jugador que se le añada algo.
    (object (is-a RONDA) (nombre_ronda ?nombre_ronda_actual) (hay_cosecha TRUE))
    ; cuando ambos jugadores hayan pagado su demanda, se añadirá la cosecha
    (object (is-a JUGADOR) (nombre ?nombre_jugador1) )
    (object (is-a JUGADOR) (nombre ?nombre_jugador2) )
    ; ambos jugadores han pagado.
    (cantidad_comida_demandada ?nombre_jugador1 ?nombre_ronda_actual ?cantidad_pendiente_jugador1)
    (cantidad_comida_demandada ?nombre_jugador2 ?nombre_ronda_actual ?cantidad_pendiente_jugador2)  
    (test (<= ?cantidad_pendiente_jugador1 0))
    (test (<= ?cantidad_pendiente_jugador2 0))
    ; jugadores distintos.
    (test (neq ?nombre_jugador1 ?nombre_jugador2))
    ; no haya pillado cosecha
    (not (cosechado ?nombre_jugador1 ?nombre_ronda_actual GRANO))
    ; recursos jugador.  
    ?grano_jugador1 <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador1) (recurso GRANO) (cantidad ?cantidad_grano))
    ; comprobar cantidades.
    (test (> ?cantidad_grano 0))
    =>
    (modify-instance ?grano_jugador1 (cantidad (+ ?cantidad_grano 1)))
    (assert (cosechado ?nombre_jugador1 ?nombre_ronda_actual GRANO))
    
    (printout t"El jugador <" ?nombre_jugador1 "> ha recibido de la cosecha +1 GRANO." crlf)
)


(defrule PASAR_TURNO_AL_FINAL_DE_LA_RONDA
    ; para cambiar de ronda se tiene que dar la siguiente situación
    ;1| |1| |1|2|1|   y turno de 2
    ;0|1|2|3|4|5|6|0
    ?jugador1 <- (object (is-a JUGADOR) (nombre ?nombre_jugador1)(demanda_comida_cubierta ?demanda_comida_cubierta_jugador1))
    ?posicion_jugador1 <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador1) (nombre_jugador ?nombre_jugador1))
    ?jugador2 <- (object (is-a JUGADOR) (nombre ?nombre_jugador2)(demanda_comida_cubierta ?demanda_comida_cubierta_jugador2))
    ?posicion_jugador2 <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador2) (nombre_jugador ?nombre_jugador2))
    (test (eq ?pos_jugador1 6))
    (test (eq ?pos_jugador2 5))
    (test (neq ?jugador1 ?jugador2))
    
    ; Ha finalizado su actividad principal dentro de su turno.
    ?turno_finalizado <- (fin_actividad_principal ?nombre_jugador1)
    ?turno_j1 <- (turno ?nombre_jugador1)
    ; obtener de la ronda, la demanda de comida.
    (ronda_actual ?nombre_ronda_actual)
    (object (is-a RONDA) (nombre_ronda ?nombre_ronda_actual) (coste_comida ?coste_comida))

    ; eliminar el semaforo de la restriccion de añadir recurso a la oferta.
    ?semaforo <- (recursos_añadidos_loseta ?)
    =>
    (bind ?nueva_posicion (+ ?pos_jugador2 2))
    ; deshace el hecho semaforo del turno.
    (retract ?turno_finalizado)
    ; eliminar turno jugador 1
    (retract ?turno_j1)
    ; generar hecho turno j2.
    (assert (turno ?nombre_jugador2))
    ; modifica la posición del jugador 2
    (modify-instance ?posicion_jugador2 (posicion (mod ?nueva_posicion 7)))
    ; eliminar semaforo
    (retract ?semaforo)
    ; añadir semaforo
    (assert (cambiar_ronda TRUE))

    ; iniciar contadores para llevar registro de la comida que falta por pagar.
    (assert (cantidad_comida_demandada ?nombre_jugador1 ?nombre_ronda_actual (- ?coste_comida ?demanda_comida_cubierta_jugador1)))
    (assert (cantidad_comida_demandada ?nombre_jugador2 ?nombre_ronda_actual (- ?coste_comida ?demanda_comida_cubierta_jugador2)))
    
    (printout t"=====================================================================================================" crlf)
    (printout t"El jugador: <" ?nombre_jugador1 "> ha finalizado su turno. " crlf)
    (printout t"El jugador: <" ?nombre_jugador2 "> ha empezado su turno en la posicion <" (mod ?nueva_posicion 7) ">. " crlf)

    (printout t"Produciendose el Cambio de Ronda..." crlf)
    ;(printout t"Cambiando de Ronda: <"?nombre_ronda_actual "> a Ronda: <"?nombre_ronda_siguiente">..." crlf)
)


(defrule PASAR_TURNO
    ; pensar si debería haber alguna precondición o si simplemente por estar 
    ; en la posición que está la regla ya se asegura que sólo se instancia
    ; cuando el jugador no puede hacer nada más
    ?jugador1 <- (object (is-a JUGADOR) (nombre ?nombre_jugador1))
    ?jugador2 <- (object (is-a JUGADOR) (nombre ?nombre_jugador2))
    ?posicion_jugador1 <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador1) (nombre_jugador ?nombre_jugador1))
    ?posicion_jugador2 <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador2) (nombre_jugador ?nombre_jugador2))
    (test (neq ?jugador1 ?jugador2))
    (test (neq ?pos_jugador1 6))
    ; Ha finalizado su actividad principal dentro de su turno.
    ?turno_finalizado <- (fin_actividad_principal ?nombre_jugador1)
    ?turno_j1 <- (turno ?nombre_jugador1)
    ; Generalización: mueve al otro jugador
    ?posicion_actual_jugador2 <- (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador2) (nombre_jugador ?nombre_jugador2))
    ; eliminar el semaforo de la restriccion de añadir recurso a la oferta.
    ?semaforo <- (recursos_añadidos_loseta ?)
    ; No existen actualizaciones de mazo.
    (not (actualizar_mazo ? ? ?))
    =>
    (bind ?nueva_posicion (+ ?pos_jugador2 2))
    ; deshace el hecho semaforo del turno.
    (retract ?turno_finalizado)
    ; eliminar turno jugador 1
    (retract ?turno_j1)
    ; generar hecho turno j2.
    (assert (turno ?nombre_jugador2))
    ; modifica la posición del jugador 2
    (modify-instance ?posicion_actual_jugador2 (posicion (mod ?nueva_posicion 7)))
    ; eliminar semaforo
    (retract ?semaforo)osicion_en_mazo
    (printout t"=====================================================================================================" crlf)
    (printout t"El jugador: <" ?nombre_jugador1 "> ha finalizado su turno. " crlf)
    (printout t"El jugador: <" ?nombre_jugador2 "> ha empezado su turno en la posicion <" (mod ?nueva_posicion 7) ">. " crlf)


)


(defrule AÑADIR_RECURSOS_OFERTA
    ; Esperar a que termine el proceso de ejecución de cambio de ronda.
    (not (cambiar_ronda TRUE))
    ; la ronda actual no puede ser la ronda final
    (not (ronda_actual RONDA_EXTRA_FINAL))
    ; no añadir dos veces 
    (not (recursos_añadidos_loseta ?pos))
    ; obtiene la loseta con visibilidad TRUE
    ?loseta <- (object (is-a LOSETA) (posicion ?pos) (visibilidad TRUE))
    ; el jugador está en la loseta
    (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos) (nombre_jugador ?nombre_jugador))
    ; y turno jugador
    (turno ?nombre_jugador)
    ; Obtiene la oferta
    ?oferta_recurso1 <- (OFERTA_RECURSO (recurso ?recurso1) (cantidad ?cantidad_oferta1))
    ?oferta_recurso2 <- (OFERTA_RECURSO (recurso ?recurso2) (cantidad ?cantidad_oferta2))
    ; Por cada recurso de la loseta...
    ?ref_recurso1 <- (object (is-a LOSETA_TIENE_RECURSO) (posicion ?pos) (recurso ?recurso1) (cantidad ?cantidad_recurso1))
    ?ref_recurso2 <- (object (is-a LOSETA_TIENE_RECURSO) (posicion ?pos) (recurso ?recurso2) (cantidad ?cantidad_recurso2))
    (test (neq ?ref_recurso1 ?ref_recurso2))
    => 
    ; añadir a la oferta.
    (modify ?oferta_recurso1 (cantidad (+ ?cantidad_oferta1 ?cantidad_recurso1)))
    (modify ?oferta_recurso2 (cantidad (+ ?cantidad_oferta2 ?cantidad_recurso2)))
    (assert (recursos_añadidos_loseta ?pos))
    (assert (permitir_realizar_accion ?nombre_jugador))
    (printout t"=====================================================================================================" crlf)
    (printout t"Se han añadido a la OFERTA los recursos de la loseta con posición: <" ?pos ">" crlf)
    (printout t"  La cantidad <" ?cantidad_recurso1 "> de recurso <" ?recurso1 ">." crlf)
    (printout t"  La cantidad <" ?cantidad_recurso2 "> de recurso <" ?recurso2 ">." crlf)
)

(defrule TOMAR_RECURSO_OFERTA
    ; si loseta oculta no se puede tomar recurso de la oferta.
    (object (is-a LOSETA) (posicion ?pos_jugador) (visibilidad TRUE))
    (object (is-a JUGADOR_ESTA_EN_LOSETA) (posicion ?pos_jugador) (nombre_jugador ?nombre_jugador))
    ; El jugador q esté en la loseta tiene que tener su turno.
    (turno ?nombre_jugador)
    ; debe haberse activado la autorización de realizar acción
    ?permiso <- (permitir_realizar_accion ?nombre_jugador)
    ; Obtiene los datos del recurso del jugador
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?recurso_deseado) (cantidad ?cantidad_recurso))
    ; Obtiene el recurso de la oferta que se va a tomar
    ?recurso_oferta <- (OFERTA_RECURSO (recurso ?recurso_deseado) (cantidad ?cantidad_oferta))
    ; Comprueba que el recurso de la oferta se pueda obtener
    (test (> ?cantidad_oferta 0))
    ; Hecho estratégico que implique coger recurso de la oferta
    ?deseo <- (deseo_coger_recurso ?nombre_jugador ?recurso_deseado)
    =>
    ; eliminar deseo
    (retract ?deseo)
    (retract ?permiso)
    ; Actualizar la cantidad de la oferta
    (modify ?recurso_oferta (cantidad 0))
    ; Actualizar los recursos del jugador
    (modify-instance ?recurso_jugador (cantidad (+ ?cantidad_recurso ?cantidad_oferta)))
    ; fin actividad principal
    (assert (fin_actividad_principal ?nombre_jugador))
    (printout t"=====================================================================================================" crlf)
    (printout t"El jugador: <" ?nombre_jugador "> ha tomado de la oferta: <" ?cantidad_oferta "> de <" ?recurso_deseado ">. " crlf)
)

; OK :)
(defrule ENTRAR_EDIFICIO_GRATIS_RONDAS

    ; Se puede entrar de uno en uno en el resto de las rondas.
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Existe un deseo de entrar a un edificio, este tiene el tipo de recurso que quiere usar para pagar y su nombre
    ?deseo <- (deseo_entrar_edificio ?nombre_jugador ?nombre_edificio)
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; se le permite realizar una acción
    ?permiso <- (permitir_realizar_accion ?nombre_jugador)
    ; no existe un jugador en ese edificio.
    (not (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio)(nombre_jugador ?)))
    ; obtiene la posición del jugador
    ?pos_jugador <- (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?edificio_actual) (nombre_jugador ?nombre_jugador))
    ; (test (neq ?nombre_jugador ?otro_jugador))
    ;(test (neq ?edificio_actual ?nombre_edificio))
    ; Comprobar que alguien (ya sea el ayuntamiento o un jugador) posee el edificio.
    (not (object (is-a CARTA_PERTENECE_A_MAZO)(nombre_carta ?nombre_edificio)(id_mazo ?)(posicion_en_mazo ?)))

    ; No tiene coste de entrada y pertence a otro jugador o pertenece al jugador y entra gratis. 
    (or
       (not (object (is-a COSTE_ENTRADA_CARTA) (nombre_carta ?nombre_edificio) (tipo ?) (cantidad ?))) 
       (object (is-a JUGADOR_TIENE_CARTA) (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_edificio))
    )
    
    =>
    ; indicar que el jugador está en el edificio.
    (modify-instance ?pos_jugador (nombre_edificio ?nombre_edificio))
    ; quitar el deseo.
    (retract ?deseo)
    (retract ?permiso)
    ; Acción principal terminada
    ; MODIFICACIÓN: CREO QUE ESTO DEBERÍA IR DESPUÉS DE USAR EL EDIFICIO
    ;(assert (fin_actividad_principal ?nombre_jugador))
    
    (printout t"El jugador: <" ?nombre_jugador "> ha entrado al edificio: <" ?nombre_edificio "> sin coste de entrada o porque le pertenece." crlf)
)

; OK :)
(defrule ENTRAR_EDIFICIO_CON_COSTE_ENTRADA_RONDAS
    ; Se puede entrar de uno en uno en el resto de las rondas.
    (ronda_actual ?nombre_ronda)
    (test (neq ?nombre_ronda RONDA_EXTRA_FINAL))
    ; Existe un deseo de entrar a un edificio, este tiene el tipo de recurso que quiere usar para pagar y su nombre
    ?deseo <- (deseo_entrar_edificio ?nombre_jugador ?nombre_edificio ?tipo_recurso ?nombre_recurso)
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; se le permite realizar una acción
    ?permiso <- (permitir_realizar_accion ?nombre_jugador)
    ; no exista un jugador en ese edificio.
     (not (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio)(nombre_jugador ?)))
    ; obtiene la posición del jugador
    ?pos_jugador <- (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?edificio_actual) (nombre_jugador ?nombre_jugador))
    (test (neq ?edificio_actual ?nombre_edificio))
    ; Comprobar que alguien (ya sea el ayuntamiento o un jugador) posee el edificio.
    (not (object (is-a CARTA_PERTENECE_A_MAZO)(nombre_carta ?nombre_edificio)(id_mazo ?)(posicion_en_mazo ?)))
    
    ; Tiene coste de entrada.
    (object (is-a COSTE_ENTRADA_CARTA) (nombre_carta ?nombre_edificio) (tipo ?tipo_recurso) (cantidad ?coste_entrada))
    ; comprobar que tenga recursos suficientes para entrar.
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?nombre_recurso) (cantidad ?cantidad_recurso))
    (test (>= ?cantidad_recurso ?coste_entrada))
    =>
    ; Modificar el recurso del jugador
    (modify-instance ?recurso_jugador (cantidad (- ?cantidad_recurso ?coste_entrada) ))
    ; indicar que el jugador está en el edificio.
    (modify-instance ?pos_jugador (nombre_edificio ?nombre_edificio))

    (assert (jugador_entra_edificio ?nombre_jugador ?nombre_edificio))
    ; quitar el deseo.
    (retract ?deseo)
    (retract ?permiso)
    ; Print final
    (printout t"El jugador: <" ?nombre_jugador "> ha entrado al edificio: <" ?nombre_edificio "> por <" ?coste_entrada "> " ?tipo_recurso "." crlf)
)

; falta : no comprobado que vaya.
(defrule ENTRAR_EDIFICIO_GRATIS_RONDA_FINAL
; Se puede entrar de uno en uno en el resto de las rondas.
    (ronda_actual RONDA_EXTRA_FINAL)
    ; Existe un deseo de entrar a un edificio, este tiene el tipo de recurso que quiere usar para pagar y su nombre
    ?deseo <- (deseo_entrar_edificio ?nombre_jugador ?nombre_edificio)
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; obtener nombre de la carta. 
    (object (is-a CARTA) (nombre ?nombre_carta) (valor ?))
    ; comprobar que el jugador no se encuentre ya en el edificio. 
    ?pos_jugador <- (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?edificio_actual) (nombre_jugador ?nombre_jugador))
    (test (neq ?edificio_actual ?nombre_carta))

    

    (object (is-a JUGADOR)(nombre ?otro_jugador))
    (test (neq ?nombre_jugador ?otro_jugador))

    ; No tiene coste de entrada y pertence a otro jugador o pertenece al jugador y entra gratis. 
    (or
        (and
            (not (object (is-a COSTE_ENTRADA_CARTA) (nombre_carta ?nombre_carta) (tipo ?) (cantidad ?))) 
                 
            (object (is-a JUGADOR_TIENE_CARTA)(nombre_jugador ?otro_jugador) (nombre_carta ?nombre_carta))
        ) 
         
        (object (is-a JUGADOR_TIENE_CARTA) (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_carta))
    )

    =>
    ; indicar que el jugador está en el edificio.
    (modify-instance ?pos_jugador (nombre_edificio ?nombre_carta))

    ; quitar el deseo.
    (retract ?deseo)
    (printout t"El jugador: <" ?nombre_jugador "> ha entrado al edificio: <" ?nombre_carta "> sin coste de entrada en la ronda final." crlf)


)

;OK
(defrule UTILIZAR_EDIFICIO_CONSTRUCTOR
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))

    ; deseo construir edificio
    ?deseo <- (deseo_construccion ?nombre_jugador ?nombre_carta)

    ; el edificio puede construir. 
    (or 
        (test (eq ?nombre_edificio "CONSTRUCTORA1"))
        (test (eq ?nombre_edificio "CONSTRUCTORA2"))
        (test (eq ?nombre_edificio "CONSTRUCTORA3"))
    )
    
    ; comprobar que se encuentra en la parte superior del mazo.
    ?pertenencia_mazo <- (object (is-a CARTA_PERTENECE_A_MAZO) (id_mazo ?id_mazo) (nombre_carta ?nombre_carta) (posicion_en_mazo 1))
    (object (is-a MAZO)(id_mazo ?id_mazo)(numero_cartas_en_mazo ?num_cartas_mazo))
    ; obtener el coste de la carta
    ?coste_carta <- (object (is-a COSTE_CONSTRUCCION_CARTA) (nombre_carta ?nombre_carta) (cantidad_madera ?coste_madera) (cantidad_arcilla ?coste_arcilla) (cantidad_ladrillo ?coste_ladrillos) (cantidad_hierro ?coste_hierro) (cantidad_acero ?coste_acero))
    ; comprobar que el jugador tiene suficientes recursos para construirla.
    ?recurso_jugador_madera <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso MADERA) (cantidad ?cantidad_madera))
    ?recurso_jugador_arcilla <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ARCILLA) (cantidad ?cantidad_arcilla))
    ?recurso_jugador_ladrillos <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso LADRILLOS) (cantidad ?cantidad_ladrillos))
    ?recurso_jugador_hierro <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso HIERRO) (cantidad ?cantidad_hierro))
    ?recurso_jugador_acero <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ACERO) (cantidad ?cantidad_acero))
    
    (test (>= ?cantidad_madera ?coste_madera))
    (test (>= ?cantidad_arcilla ?coste_arcilla))
    (test (>= ?cantidad_ladrillos ?coste_ladrillos))
    (test (>= ?cantidad_hierro ?coste_hierro))
    (test (>= ?cantidad_acero ?coste_acero))
    =>
    ; modificar cantidad de materiales del jugador
    (modify-instance ?recurso_jugador_madera (cantidad (- ?cantidad_madera ?coste_madera)))
    (modify-instance ?recurso_jugador_arcilla (cantidad (- ?cantidad_arcilla ?coste_arcilla)))
    (modify-instance ?recurso_jugador_ladrillos (cantidad (- ?cantidad_ladrillos ?coste_ladrillos)))
    (modify-instance ?recurso_jugador_hierro (cantidad (- ?cantidad_hierro ?coste_hierro)))
    (modify-instance ?recurso_jugador_acero (cantidad (- ?cantidad_acero ?coste_acero)))
    ; quitar carta del mazo
    (unmake-instance ?pertenencia_mazo)
    ; eliminar deseo
    (retract ?deseo)
    ; asignar la carta al jugador
    (make-instance of JUGADOR_TIENE_CARTA (nombre_jugador ?nombre_jugador) (nombre_carta ?nombre_carta))
    ;generar hecho semáforo para reordenar el mazo
    (assert (actualizar_mazo ?id_mazo (- ?num_cartas_mazo 1) 2))
    ; semaforo final actividad principal.
    (assert(fin_actividad_principal ?nombre_jugador)) 
    ; relación para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))

    (printout t "El jugador <"?nombre_jugador"> ha usado el edificio <"?nombre_edificio"> para construir la carta <"?nombre_carta"> empleando <"?coste_madera"> madera, <"?coste_arcilla"> arcilla, <"?coste_ladrillos"> ladrillos, <"?coste_hierro"> hierro y <"?coste_acero"> acero." crlf)
)

(defrule EDIFICIO_GENERA_RECURSO_SIN_INPUTS_UN_OUTPUT_SI_BONUS_NO_ENERGIA
    ;   INPUTS          OUTPUT          BONUS   ENERGIA     EDIFICIOS
    ;      0               1              1        0        (piscifactoria, arcilla, colliery [* máximo 1 ud con bonuses])
    ; no hay caso de 0 inputs y 1 output sin bonus. 
    
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 1))
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))

    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; el edificio no tiene coste energético
    (not (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario ?) (cantidad ?) ))
    ; caso donde unicamente genera output.
    (not (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?) (cantidad_maxima ?)))
    ; tiene output.
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso) (cantidad_min_generada_por_unidad ?cantidad_output))
    ; obtener el tipo de bonus de output de la carta
    (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio)(bonus ?tipo_bonus) (cantidad_maxima_permitida ?cantidad_max_permitida))
    ; Caso donde la carta tiene bonus aplicables. 
    (object (is-a JUGADOR_TIENE_BONUS) (nombre_jugador ?nombre_jugador) (tipo ?tipo_bonus) (cantidad ?cantidad_bonus))
    ; obtener los recursos del jugador que otorga el edificio
    ?recurso_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador)(recurso ?recurso) (cantidad ?cantidad_recurso))
    
    =>
    ; cantidad proporciona al jugador de output por bonus.
    (bind ?cantidad_proporciona_bonus (min ?cantidad_bonus ?cantidad_max_permitida))
    ; añadir recursos al jugador 
    (modify-instance ?recurso_jugador (cantidad (+ ?cantidad_recurso (+ ?cantidad_output ?cantidad_proporciona_bonus))))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    ; log
    (printout t"El jugador: <" ?nombre_jugador "> ha generado en el edificio: <" ?nombre_edificio "> un total de <" (+ ?cantidad_output ?cantidad_proporciona_bonus) "> recursos de <" ?recurso ">. Los cuales <" ?cantidad_output "> son por entrar y <" ?cantidad_proporciona_bonus "> por los bonus que tiene." crlf)
)

; FUNCIONA
(defrule EDIFICIO_GENERA_RECURSO_UN_INPUT_UN_OUTPUT_NO_BONUS_NO_ENERGIA
    ;   INPUTS          OUTPUT          BONUS   ENERGIA     EDIFICIOS
    ;      1               1              0        0        (Carbon vegetal, ironworks)

    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 1))
    ; El edificio tiene sólo 1 input como recurso.
    (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_entrada) (cantidad_maxima ?cantidad_maxima))
    ; el eficio tiene 1 sólo output como recurso.  
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida) (cantidad_min_generada_por_unidad ?cantidad_unitaria))
    ; el edificio no genera recursos adicionales por bonus.
    (not (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio) (bonus ?) (cantidad_maxima_permitida ?)))
    ; el edificio no tiene coste energético
    (not (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario ?) (cantidad ?) ))
    ; referencia los recursos del jugador
    ?recurso_jugador_entrada <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?recurso_entrada) (cantidad ?cantidad_recurso_entrada_jugador))
    ?recurso_jugador_salida <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?recurso_salida) (cantidad ?cantidad_recurso_salida_jugador))
    ; el jugador tiene el deseo de generar X recursos outputs empleando Y recursos inputs.
    ?deseo <- (deseo_generar_con_recurso ?nombre_jugador ?nombre_edificio ?recurso_entrada ?cantidad_a_transformar)
    ; comprobar que tenga los recursos necesarios.
    (test (>= ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar))
    
    =>
    ; obtener la cantidad que ha transformado del recurso de salida.
    (bind ?cantidad_transformada (integer (* ?cantidad_a_transformar ?cantidad_unitaria)))
    (modify-instance ?recurso_jugador_entrada (cantidad (- ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar)))
    (modify-instance ?recurso_jugador_salida (cantidad (+ ?cantidad_recurso_salida_jugador ?cantidad_transformada)))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; elimina el deseo
    (retract ?deseo)
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    (printout t"El jugador: <" ?nombre_jugador "> ha transformado en el edificio: <" ?nombre_edificio "> <" ?cantidad_a_transformar "> recursos de <" ?recurso_entrada "> en <" ?cantidad_transformada "> recursos de <" ?recurso_salida ">." crlf)
)

; TODO: FUNCIONA!
(defrule EDIFICIO_GENERA_RECURSO_UN_INPUT_UN_OUTPUT_NO_BONUS_SI_ENERGIA_Y_ES_UNITARIA
    ;   INPUTS          OUTPUT          BONUS   ENERGIA     EDIFICIOS
    ;      1               1              0        1        (steel mill 5 energia por cada output.)
    ; ENERGIA UNITARIO, es decir, es variable

    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO) (nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 1))
    ; El edificio tiene sólo 1 input como recurso.
    (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_entrada) (cantidad_maxima ?cantidad_maxima))
    ; el eficio tiene 1 sólo output como recurso.  
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida) (cantidad_min_generada_por_unidad ?cantidad_unitaria))
    ; el edificio no genera recursos adicionales por bonus.
    (not (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio) (bonus ?) (cantidad_maxima_permitida ?)))
    ; obtiene el coste energético del edificio
    (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario TRUE) (cantidad ?coste_energia))
    ; referencia los recursos del jugador
    ?recurso_jugador_entrada <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?recurso_entrada) (cantidad ?cantidad_recurso_entrada_jugador))
    ?recurso_jugador_salida <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ?recurso_salida) (cantidad ?cantidad_recurso_salida_jugador))
    ; el jugador tiene el deseo de generar X recursos outputs empleando Y recursos inputs.
    ?deseo_generar <- (deseo_generar_con_recurso ?nombre_jugador ?nombre_edificio ?recurso_entrada ?cantidad_a_transformar)
    ; y tiene el deseo de pagar con X de energía. 
    ?deseo_pago_energia <- (deseo_emplear_energia ?nombre_jugador ?nombre_edificio ?cantidad_madera ?cantidad_carbon_vegetal ?cantidad_carbon ?cantidad_coque)
    ; obtener los recursos de energia del jugador.
    ?madera_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso MADERA) (cantidad ?cantidad_madera_jugador))
    ?carbon_vegetal_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON_VEGETAL) (cantidad ?cantidad_carbon_vegetal_jugador))
    ?carbon_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON) (cantidad ?cantidad_cabon_jugador))
    ?coque_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso COQUE) (cantidad ?cantidad_coque_jugador))
    ; comprobar que tenga los recursos necesarios.
    (test (>= ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar))
    (test (>= (+ (* ?cantidad_madera 1) (* ?cantidad_carbon_vegetal 3) (* ?cantidad_carbon 3) (* ?cantidad_coque 10)) (* ?cantidad_a_transformar ?coste_energia) ))
    
    =>
    ; calcula la cantidad generada y de energía empleada
    (bind ?cantidad_transformada (integer (* ?cantidad_unitaria ?cantidad_a_transformar)))
    (bind ?cantidad_energia_empleada (* ?cantidad_a_transformar ?coste_energia))

    ; modifica los recursos de entrada/salida del jugador
    (modify-instance ?recurso_jugador_entrada (cantidad (- ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar)))
    (modify-instance ?recurso_jugador_salida (cantidad (+ ?cantidad_recurso_salida_jugador ?cantidad_transformada)))
    ; modifica los recursos energéticos del jugador.
    (modify-instance ?madera_jugador (cantidad (- ?cantidad_madera_jugador ?cantidad_madera)))
    (modify-instance ?carbon_vegetal_jugador (cantidad (- ?cantidad_carbon_vegetal_jugador ?cantidad_carbon_vegetal)))
    (modify-instance ?carbon_jugador (cantidad (- ?cantidad_cabon_jugador ?cantidad_carbon)))
    (modify-instance ?coque_jugador (cantidad (- ?cantidad_coque_jugador ?cantidad_coque)))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; eliminar deseos
    (retract ?deseo_generar)
    (retract ?deseo_pago_energia)
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    (printout t"El jugador: <" ?nombre_jugador "> ha transformado en el edificio: <" ?nombre_edificio "> <" ?cantidad_a_transformar "> recursos de <" ?recurso_entrada "> en <" ?cantidad_transformada "> recursos de <" ?recurso_salida "> empleando <" ?cantidad_energia_empleada "> de energía." crlf)
)

; TODO: COMPROBAR
(defrule EDIFICIO_GENERA_RECURSO_UN_INPUT_DOS_OUTPUT_NO_BONUS_NO_ENERGIA
;   INPUTS          OUTPUT          BONUS   ENERGIA     EDIFICIOS
;      1               2              0        0        (matadero, peleteria y coqueria)

    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 2))    
    ; el jugador tiene el deseo de usar el edificio empleando X recursos de entrada
    ?deseo <- (deseo_generar_con_recurso ?nombre_jugador ?nombre_edificio ?recurso_entrada ?cantidad_a_transformar)
    ; obtiene el input del edificio 
    (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_entrada) (cantidad_maxima ?cantidad_maxima))
    ; Se obtienen los outputs del edificio.
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida1) (cantidad_min_generada_por_unidad ?cantidad_unitaria1))
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida2) (cantidad_min_generada_por_unidad ?cantidad_unitaria2))
    (test (neq ?recurso_salida1 ?recurso_salida2))
    ; el edificio no tiene bonus
    (not (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio) (bonus ?)))
    ; el edificio no tiene coste energético
    (not (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario ?) (cantidad ?) ))
    ; obtiene los recursos del jugador del mismo tipo que el input y output
    ?recurso_jugador_entrada <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_entrada) (cantidad ?cantidad_recurso_entrada_jugador))
    ?recurso_jugador_salida1 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida1) (cantidad ?cantidad_recurso_salida1_jugador))
    ?recurso_jugador_salida2 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida2) (cantidad ?cantidad_recurso_salida2_jugador))
    ; comprueba que el jugador tiene suficiente input
    (test (>= ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar))
    =>
    ; calcula la cantidad a transformar
    (bind ?cantidad_transformada_recurso_salida1 (integer (min (* ?cantidad_maxima ?cantidad_unitaria1) (* ?cantidad_a_transformar ?cantidad_unitaria1))))
    (bind ?cantidad_transformada_recurso_salida2 (integer (min (* ?cantidad_maxima ?cantidad_unitaria2) (* ?cantidad_a_transformar ?cantidad_unitaria2))))
    ; modifica el recurso input del jugador
    (modify-instance ?recurso_jugador_entrada (cantidad (- ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar)))
    ; modifica el primer output del jugador
    (modify-instance ?recurso_jugador_salida1 (cantidad (+ ?cantidad_recurso_salida1_jugador ?cantidad_transformada_recurso_salida1)))
    ; modifica el segundo output del jugador
    (modify-instance ?recurso_jugador_salida2 (cantidad (+ ?cantidad_recurso_salida2_jugador ?cantidad_transformada_recurso_salida2)))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    ; eliminar deseo
    (retract ?deseo)
    (printout t"El jugador: <" ?nombre_jugador "> ha transformado en el edificio: <" ?nombre_edificio "> <" ?cantidad_a_transformar "> recursos de <" ?recurso_entrada "> en <" ?cantidad_transformada_recurso_salida1 "> recursos de <" ?recurso_salida1 "> y <" ?cantidad_transformada_recurso_salida2"> recursos de <" ?recurso_salida2 ">." crlf)
)

; TODO: funciona!
(defrule EDIFICIO_GENERA_RECURSO_UN_INPUT_DOS_OUTPUT_NO_BONUS_SI_ENERGIA_Y_UNITARIA
    ;   INPUTS          OUTPUT          BONUS   ENERGIA     edificios
    ;      1               2              0        1        (ahumador (1 total), ladrillos (por ud), panaderia (por ud))
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 2))    
    ; obtiene el input del edificio 
    (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_entrada) (cantidad_maxima ?cantidad_maxima))
    ; Se obtienen los outputs del edificio.
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida1) (cantidad_min_generada_por_unidad ?cantidad_unitaria1))
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida2) (cantidad_min_generada_por_unidad ?cantidad_unitaria2))
    (test (neq ?recurso_salida1 ?recurso_salida2))
    ; el edificio no tiene bonus
    (not (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio) (bonus ?)))
    ; obtiene los recursos del jugador del mismo tipo que el input y output
    ?recurso_jugador_entrada <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_entrada) (cantidad ?cantidad_recurso_entrada_jugador))
    ?recurso_jugador_salida1 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida1) (cantidad ?cantidad_recurso_salida1_jugador))
    ?recurso_jugador_salida2 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida2) (cantidad ?cantidad_recurso_salida2_jugador))
    ; obtiene el coste energético del edificio
    (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario TRUE) (cantidad ?coste_energia))
    ; el jugador tiene el deseo de generar X recursos outputs empleando Y recursos inputs.
    ?deseo_generar <- (deseo_generar_con_recurso ?nombre_jugador ?nombre_edificio ?recurso_entrada ?cantidad_a_transformar)
    ; y tiene el deseo de pagar con X de energía. 
    ?deseo_pago_energia <- (deseo_emplear_energia ?nombre_jugador ?nombre_edificio ?cantidad_madera ?cantidad_carbon_vegetal ?cantidad_carbon ?cantidad_coque)
    ; obtener los recursos de energia del jugador.
    ?madera_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso MADERA) (cantidad ?cantidad_madera_jugador))
    ?carbon_vegetal_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON_VEGETAL) (cantidad ?cantidad_carbon_vegetal_jugador))
    ?carbon_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON) (cantidad ?cantidad_cabon_jugador))
    ?coque_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso COQUE) (cantidad ?cantidad_coque_jugador))
    ; comprobar que tenga los recursos necesarios.
    (test (>= ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar))
    (test (>= (+ (* ?cantidad_madera 1) (* ?cantidad_carbon_vegetal 3) (* ?cantidad_carbon 3) (* ?cantidad_coque 10)) (* ?cantidad_a_transformar ?coste_energia) ))
    =>
    ; calcula la cantidad a transformar
    (bind ?cantidad_transformada_recurso_salida1 (integer (min (* ?cantidad_maxima ?cantidad_unitaria1) (* ?cantidad_a_transformar ?cantidad_unitaria1))))
    (bind ?cantidad_transformada_recurso_salida2 (integer (min (* ?cantidad_maxima ?cantidad_unitaria2) (* ?cantidad_a_transformar ?cantidad_unitaria2))))
    (bind ?cantidad_energia_empleada (* ?cantidad_a_transformar ?coste_energia))
    ; modifica el recurso I/O del jugador
    (modify-instance ?recurso_jugador_entrada (cantidad (- ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar)))
    (modify-instance ?recurso_jugador_salida1 (cantidad (+ ?cantidad_recurso_salida1_jugador ?cantidad_transformada_recurso_salida1)))
    (modify-instance ?recurso_jugador_salida2 (cantidad (+ ?cantidad_recurso_salida2_jugador ?cantidad_transformada_recurso_salida2)))
    ; modifica los recursos energéticos del jugador.
    (modify-instance ?madera_jugador (cantidad (- ?cantidad_madera_jugador ?cantidad_madera)))
    (modify-instance ?carbon_vegetal_jugador (cantidad (- ?cantidad_carbon_vegetal_jugador ?cantidad_carbon_vegetal)))
    (modify-instance ?carbon_jugador (cantidad (- ?cantidad_cabon_jugador ?cantidad_carbon)))
    (modify-instance ?coque_jugador (cantidad (- ?cantidad_coque_jugador ?cantidad_coque)))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; eliminar deseos
    (retract ?deseo_generar)
    (retract ?deseo_pago_energia)
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    (printout t"El jugador: <" ?nombre_jugador "> ha transformado en el edificio: <" ?nombre_edificio "> <" ?cantidad_a_transformar "> recursos de <" ?recurso_entrada "> en <" ?cantidad_transformada_recurso_salida1 "> recursos de <" ?recurso_salida1 "> y <" ?cantidad_transformada_recurso_salida2"> recursos de <" ?recurso_salida2 ">." crlf)
    (printout t" Empleando la siguiente energía:" crlf)
    (printout t" Madera: <" ?cantidad_madera ">" crlf)
    (printout t" Carbón Vegetal: <" ?cantidad_carbon_vegetal_jugador ">" crlf)
    (printout t" Carbón: <" ?cantidad_carbon ">" crlf)
    (printout t" Coque: <" ?cantidad_coque ">" crlf)
)

; TODO: FUNCIONA
(defrule EDIFICIO_GENERA_RECURSO_UN_INPUT_DOS_OUTPUT_NO_BONUS_SI_ENERGIA_Y_FIJA

    ;   INPUTS          OUTPUT          BONUS   ENERGIA     edificios
    ;      1               2              0        1        (ahumador (1 total), ladrillos (por ud), panaderia (por ud))
    
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio ?nombre_edificio) (nombre_jugador ?nombre_jugador))
    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq ?nombre_edificio ?ed))
    ; la carta solo puede tener un output
    (object (is-a CARTA_EDIFICIO_GENERADOR) (nombre ?nombre_edificio)(numero_recursos_salida 2))    
    ; obtiene el input del edificio 
    (object (is-a EDIFICIO_INPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_entrada) (cantidad_maxima ?cantidad_maxima))
    ; Se obtienen los outputs del edificio.
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida1) (cantidad_min_generada_por_unidad ?cantidad_unitaria1))
    (object (is-a EDIFICIO_OUTPUT) (nombre_carta ?nombre_edificio) (recurso ?recurso_salida2) (cantidad_min_generada_por_unidad ?cantidad_unitaria2))
    (test (neq ?recurso_salida1 ?recurso_salida2))
    ; el edificio no tiene bonus
    (not (object (is-a CARTA_OUTPUT_BONUS) (nombre_carta ?nombre_edificio) (bonus ?)))
    ; obtiene los recursos del jugador del mismo tipo que el input y output
    ?recurso_jugador_entrada <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_entrada) (cantidad ?cantidad_recurso_entrada_jugador))
    ?recurso_jugador_salida1 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida1) (cantidad ?cantidad_recurso_salida1_jugador))
    ?recurso_jugador_salida2 <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador) (recurso ?recurso_salida2) (cantidad ?cantidad_recurso_salida2_jugador))
    ; obtiene el coste energético del edificio
    (object (is-a COSTE_ENERGIA) (nombre_carta ?nombre_edificio) (coste_unitario FALSE) (cantidad ?coste_energia))
    ; el jugador tiene el deseo de generar X recursos outputs empleando Y recursos inputs.
    ?deseo_generar <- (deseo_generar_con_recurso ?nombre_jugador ?nombre_edificio ?recurso_entrada ?cantidad_a_transformar)
    ; y tiene el deseo de pagar con X de energía. 
    ?deseo_pago_energia <- (deseo_emplear_energia ?nombre_jugador ?nombre_edificio ?cantidad_madera ?cantidad_carbon_vegetal ?cantidad_carbon ?cantidad_coque)
    ; obtener los recursos de energia del jugador.
    ?madera_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso MADERA) (cantidad ?cantidad_madera_jugador))
    ?carbon_vegetal_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON_VEGETAL) (cantidad ?cantidad_carbon_vegetal_jugador))
    ?carbon_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON) (cantidad ?cantidad_cabon_jugador))
    ?coque_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso COQUE) (cantidad ?cantidad_coque_jugador))
    ; comprobar que tenga los recursos necesarios.
    (test (>= ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar))
    (test (>= (+ (* ?cantidad_madera 1) (* ?cantidad_carbon_vegetal 3) (* ?cantidad_carbon 3) (* ?cantidad_coque 10)) ?coste_energia ))

    =>
    ; calcula la cantidad a transformar
    (bind ?cantidad_transformada_recurso_salida1 (integer (min (* ?cantidad_maxima ?cantidad_unitaria1) (* ?cantidad_a_transformar ?cantidad_unitaria1))))
    (bind ?cantidad_transformada_recurso_salida2 (integer (min (* ?cantidad_maxima ?cantidad_unitaria2) (* ?cantidad_a_transformar ?cantidad_unitaria2))))
    
    ; modifica el recurso I/O del jugador
    (modify-instance ?recurso_jugador_entrada (cantidad (- ?cantidad_recurso_entrada_jugador ?cantidad_a_transformar)))
    (modify-instance ?recurso_jugador_salida1 (cantidad (+ ?cantidad_recurso_salida1_jugador ?cantidad_transformada_recurso_salida1)))
    (modify-instance ?recurso_jugador_salida2 (cantidad (+ ?cantidad_recurso_salida2_jugador ?cantidad_transformada_recurso_salida2)))
    ; modifica los recursos energéticos del jugador.
    (modify-instance ?madera_jugador (cantidad (- ?cantidad_madera_jugador ?cantidad_madera)))
    (modify-instance ?carbon_vegetal_jugador (cantidad (- ?cantidad_carbon_vegetal_jugador ?cantidad_carbon_vegetal)))
    (modify-instance ?carbon_jugador (cantidad (- ?cantidad_cabon_jugador ?cantidad_carbon)))
    (modify-instance ?coque_jugador (cantidad (- ?cantidad_coque_jugador ?cantidad_coque)))
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; eliminar deseos
    (retract ?deseo_generar)
    (retract ?deseo_pago_energia)
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio ?nombre_edificio))
    (printout t"El jugador: <" ?nombre_jugador "> ha transformado en el edificio: <" ?nombre_edificio "> <" ?cantidad_a_transformar "> recursos de <" ?recurso_entrada "> en <" ?cantidad_transformada_recurso_salida1 "> recursos de <" ?recurso_salida1 "> y <" ?cantidad_transformada_recurso_salida2"> recursos de <" ?recurso_salida2 ">," crlf
     "empleando <"?coste_energia"> unidades de energía, pagadas con <"?cantidad_madera"> unidades de madera, <"?cantidad_carbon_vegetal"> unidades de carbón vegetal, <"?cantidad_carbon"> unidades de carbón y <"?cantidad_coque"> unidades de coque." crlf)
)

; OK
(defrule COMERCIAR_MERCADO
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio "MERCADO") (nombre_jugador ?nombre_jugador))

    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq "MERCADO" ?ed))
    ; SOLO PUEDE TOMAR UNA UNIDAD DE CADA RECURSO QUE HAY EN EL MERCADO (POR CADA VEZ).
    ?deseo <- (deseo_usar_mercado ?nombre_jugador ?cantidad_pescado ?cantidad_madera ?cantidad_arcilla ?cantidad_hierro ?cantidad_grano ?cantidad_ganado ?cantidad_carbon ?cantidad_piel)
    (test (<= ?cantidad_pescado 1))
    (test (<= ?cantidad_madera 1))
    (test (<= ?cantidad_arcilla 1))
    (test (<= ?cantidad_hierro 1))
    (test (<= ?cantidad_grano 1))
    (test (<= ?cantidad_ganado 1))
    (test (<= ?cantidad_carbon 1))
    (test (<= ?cantidad_piel 1))
    ; la suma no puede ser superior a 5
    (test (<= 5 (+ ?cantidad_pescado ?cantidad_madera ?cantidad_arcilla ?cantidad_hierro ?cantidad_grano ?cantidad_ganado ?cantidad_carbon ?cantidad_piel)))
    ; UN MINIMO DE 2 VECES Y UN MÁXIMO DE 8
    ; rECURSOS: 1 de pescado, madera, arcilla, hierro, grano, ganado, carbon, piel

    ; PROBLEMA ECONTRADO: COMO RECORRER LOS EDIFICIOS DEL JUGADOR PARA OBTENER EL Nº DE EDIFICOS BASICOS.
    ; ==> De momento simplificamos el juego y puede tomar siempre 5 recursos

    ; Obtiene los recursos del jugador
    ?jugador_pescado <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso PESCADO)(cantidad ?cantidad_jugador_pescado))
    ?jugador_madera <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso MADERA)(cantidad ?cantidad_jugador_madera))
    ?jugador_arcilla <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso ARCILLA)(cantidad ?cantidad_jugador_arcilla))
    ?jugador_hierro <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso HIERRO)(cantidad ?cantidad_jugador_hierro))
    ?jugador_grano <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso GRANO)(cantidad ?cantidad_jugador_grano))
    ?jugador_ganado <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso GANADO)(cantidad ?cantidad_jugador_ganado))
    ?jugador_carbon <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso CARBON)(cantidad ?cantidad_jugador_carbon))
    ?jugador_piel <- (object (is-a JUGADOR_TIENE_RECURSO)(nombre_jugador ?nombre_jugador)(recurso PIEL)(cantidad ?cantidad_jugador_piel))
     =>
    ; actualiza los recursos del jugador
    (modify-instance ?jugador_pescado (cantidad (+ ?cantidad_jugador_pescado ?cantidad_pescado)))
    (modify-instance ?jugador_madera (cantidad (+ ?cantidad_jugador_madera ?cantidad_madera)))
    (modify-instance ?jugador_arcilla (cantidad (+ ?cantidad_jugador_arcilla ?cantidad_arcilla)))
    (modify-instance ?jugador_hierro (cantidad (+ ?cantidad_jugador_hierro ?cantidad_hierro)))
    (modify-instance ?jugador_grano (cantidad (+ ?cantidad_jugador_grano ?cantidad_grano)))
    (modify-instance ?jugador_ganado (cantidad (+ ?cantidad_jugador_ganado ?cantidad_ganado)))
    (modify-instance ?jugador_carbon (cantidad (+ ?cantidad_jugador_carbon ?cantidad_carbon)))
    (modify-instance ?jugador_piel (cantidad (+ ?cantidad_jugador_piel ?cantidad_piel)))

    (retract ?deseo)
    ; Ha finalizado su actividad principal dentro de su turno.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio "MERCADO"))
    
    (printout t"El jugado <"?nombre_jugador"> ha comprado en el mercado los siguientes recursos: " crlf)
    (printout t"<"?cantidad_pescado"> unidades de pescado." crlf)
    (printout t"<"?cantidad_madera"> unidades de madera." crlf)
    (printout t"<"?cantidad_arcilla"> unidades de arcilla." crlf)
    (printout t"<"?cantidad_hierro"> unidades de hierro." crlf)
    (printout t"<"?cantidad_grano"> unidades de grano." crlf)
    (printout t"<"?cantidad_ganado"> unidades de ganado." crlf)
    (printout t"<"?cantidad_carbon"> unidades de carbon." crlf)
    (printout t"<"?cantidad_piel"> unidades de piel." crlf)
)

(defrule COMERCIAR_EN_COMPAÑIA_NAVIERA
    ; Es el turno del jugador
    ?turno <- (turno ?nombre_jugador)
    ; El jugador debe estar en el edificio.
    (object (is-a JUGADOR_ESTA_EDIFICIO) (nombre_edificio "COMPAÑIA NAVIERA") (nombre_jugador ?nombre_jugador))

    ; el jugador no ha usado anteriormente el edificio sin haber entrado a otro antes
    ?edificio_usado <- (object (is-a JUGADOR_HA_USADO_EDIFICIO)(nombre_edificio ?ed)(nombre_jugador ?nombre_jugador))
    (test (neq "COMPAÑIA NAVIERA" ?ed))
    ; existe el deseo de usar la compañía naviera (contiene qué objetos vender)
    ?deseo <- (deseo_usar_compañia_naviera ?nombre_jugador ?pescado ?madera ?arcilla ?hierro ?grano ?ganado ?carbon ?piel ?pescado_ahumado ?carbon_vegetal ?ladrillos ?acero ?pan ?carne ?coque ?cuero)
    ; obtiene los datos del jugador.
    ?jugador <- (object (is-a JUGADOR)(nombre ?nombre_jugador)(deudas ?)(num_barcos ?)(capacidad_envio ?capacidad_envio)(demanda_comida_cubierta ?))
    ; comprobar que la suma no excede la capacidad de los barcos
    (test (<= (+ ?pescado ?madera ?arcilla ?hierro ?grano ?ganado ?carbon ?piel ?pescado_ahumado ?carbon_vegetal ?ladrillos ?acero ?pan ?carne ?coque ?cuero) ?capacidad_envio))
    ; obtencion numero de recursos del jugador.
    ?pescado_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PESCADO) (cantidad ?cantidad_pescado))
    ?madera_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso MADERA) (cantidad ?cantidad_madera))
    ?arcilla_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ARCILLA) (cantidad ?cantidad_arcilla))
    ?hierro_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso HIERRO) (cantidad ?cantidad_hierro))
    ?grano_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso GRANO) (cantidad ?cantidad_grano))
    ?ganado_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso GANADO) (cantidad ?cantidad_ganado))
    ?carbon_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON) (cantidad ?cantidad_carbon))
    ?piel_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PIEL) (cantidad ?cantidad_piel))
    ?pescado_ahumado_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PESCADO_AHUMADO) (cantidad ?cantidad_pescado_ahumado))
    ?carbon_vegetal_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARBON_VEGETAL) (cantidad ?cantidad_carbon_vegetal))
    ?ladrillos_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso LADRILLOS) (cantidad ?cantidad_ladrillos))
    ?acero_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso ACERO) (cantidad ?cantidad_acero))
    ?pan_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso PAN) (cantidad ?cantidad_pan))
    ?carne_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CARNE) (cantidad ?cantidad_carne))
    ?coque_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso COQUE) (cantidad ?cantidad_coque))
    ?cuero_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso CUERO) (cantidad ?cantidad_cuero))
    ; las cantidades quedan comprobadas en el deseo.
    ; obtener la referencia de los francos para el jugador.
    ?francos_jugador <- (object (is-a JUGADOR_TIENE_RECURSO) (nombre_jugador ?nombre_jugador) (recurso FRANCO) (cantidad ?cantidad_francos))
    ; obtener la cantidad generada por el deseo.
    ;(bind ?ingresos_comercio =(+ (* ?pescado 1) (* ?madera 1) (* ?arcilla 1) (* ?hierro 2) (* ?grano 1) (* ?ganado 3) (* ?carbon 3) (* ?piel 2)
    ;                            (* ?pescado_ahumado 2) (* ?carbon_vegetal 2) (* ?ladrillos 2) (* ?acero 8)
    ;                           (* ?pan 3) (* ?carne 2) (* ?coque 5) (* ?cuero 4) ))
    =>
    ; restar cantidades vendidas
    (modify-instance ?pescado_jugador (cantidad (- ?cantidad_pescado ?pescado)))
    (modify-instance ?madera_jugador (cantidad (- ?cantidad_madera ?madera)))
    (modify-instance ?arcilla_jugador (cantidad (- ?cantidad_arcilla ?arcilla)))
    (modify-instance ?hierro_jugador (cantidad (- ?cantidad_hierro ?hierro)))
    (modify-instance ?grano_jugador (cantidad (- ?cantidad_grano ?grano)))
    (modify-instance ?ganado_jugador (cantidad (- ?cantidad_ganado ?ganado)))
    (modify-instance ?carbon_jugador (cantidad (- ?cantidad_carbon ?carbon)))
    (modify-instance ?piel_jugador (cantidad (- ?cantidad_piel ?piel)))
    (modify-instance ?pescado_ahumado_jugador (cantidad (- ?cantidad_pescado_ahumado ?pescado_ahumado)))
    (modify-instance ?carbon_vegetal_jugador (cantidad (- ?cantidad_carbon_vegetal ?carbon_vegetal)))
    (modify-instance ?ladrillos_jugador (cantidad (- ?cantidad_ladrillos ?ladrillos)))
    (modify-instance ?acero_jugador (cantidad (- ?cantidad_acero ?acero)))
    (modify-instance ?pan_jugador (cantidad (- ?cantidad_pan ?pan)))
    (modify-instance ?carne_jugador (cantidad (- ?cantidad_carne ?carne)))
    (modify-instance ?coque_jugador (cantidad (- ?cantidad_coque ?coque)))
    (modify-instance ?cuero_jugador (cantidad (- ?cantidad_cuero ?cuero)))

    ; añadir francos al jugador
    (modify-instance ?francos_jugador (cantidad (+ ?cantidad_francos (+ (* ?pescado 1) (* ?madera 1) (* ?arcilla 1) (* ?hierro 2) (* ?grano 1) (* ?ganado 3) (* ?carbon 3) (* ?piel 2)(* ?pescado_ahumado 2) (* ?carbon_vegetal 2) (* ?ladrillos 2) (* ?acero 8) (* ?pan 3) (* ?carne 2) (* ?coque 5) (* ?cuero 4) ))))
    ; eliminar deseo
    (retract ?deseo)
    ; semaforo final actividad principal.
    (assert (fin_actividad_principal ?nombre_jugador))
    ; flag para no permitir usar el mismo edificio dos veces.
    (modify-instance ?edificio_usado (nombre_edificio "COMPAÑIA NAVIERA"))
    ; log
    (printout t"El jugador <" ?nombre_jugador "> ha obtenido <" (+ (* ?pescado 1) (* ?madera 1) (* ?arcilla 1) (* ?hierro 2) (* ?grano 1) (* ?ganado 3) (* ?carbon 3) (* ?piel 2)(* ?pescado_ahumado 2) (* ?carbon_vegetal 2) (* ?ladrillos 2) (* ?acero 8)(* ?pan 3) (* ?carne 2) (* ?coque 5) (* ?cuero 4) )"> francos comerciando con sus barcos tras comerciar con: " crlf)
    (printout t"<"?pescado"> unidades de pescado." crlf)
    (printout t"<"?madera"> unidades de madera." crlf)
    (printout t"<"?arcilla"> unidades de arcilla." crlf)
    (printout t"<"?hierro"> unidades de hierro." crlf)
    (printout t"<"?grano"> unidades de grano." crlf)
    (printout t"<"?ganado"> unidades de ganado." crlf)
    (printout t"<"?carbon"> unidades de carbon." crlf)
    (printout t"<"?piel"> unidades de piel." crlf)
    (printout t"<"?pescado_ahumado"> unidades de pescado ahumado." crlf)
    (printout t"<"?carbon_vegetal"> unidades de carbón vegetal." crlf)
    (printout t"<"?ladrillos"> unidades de ladrillos." crlf)
    (printout t"<"?acero"> unidades de acero." crlf)
    (printout t"<"?pan"> unidades de pan." crlf)
    (printout t"<"?carne"> unidades de carne." crlf)
    (printout t"<"?coque"> unidades de coque." crlf)
    (printout t"<"?cuero"> unidades de cuero." crlf)
)

(defrule PASAR_RONDA 
    ; Semáforo pasar ronda.
    ?cambiar <- (cambiar_ronda TRUE)

    ; selección de siguiente ronda
    ?ronda_actual <- (ronda_actual ?nombre_ronda_actual)

    ; ambos jugadores han pagado la comida.
    (object (is-a JUGADOR) (nombre ?nombre_jugador1))
    (object (is-a JUGADOR) (nombre ?nombre_jugador2))
    (test (neq ?nombre_jugador1 ?nombre_jugador2))
    ?cantidad_restante_j1 <- (cantidad_comida_demandada ?nombre_jugador1 ?nombre_ronda_actual ?cantidad_pendiente_jugador1)
    ?cantidad_restante_j2 <- (cantidad_comida_demandada ?nombre_jugador2 ?nombre_ronda_actual ?cantidad_pendiente_jugador2)
    (test (<= ?cantidad_pendiente_jugador1 0))
    (test (<= ?cantidad_pendiente_jugador2 0))
    
    ?ronda_siguiente <- (object (is-a RONDA) (nombre_ronda ?nombre_ronda_siguiente))
    (siguiente_ronda ?nombre_ronda_actual ?nombre_ronda_siguiente)
    ; introducir barco
    ?introduce_barco <- (object (is-a RONDA_INTRODUCE_BARCO) (nombre_ronda ?nombre_ronda_actual) (nombre_carta ?nombre_barco))
    ; semáforo para que en las rondas impares asigne el edificio al ayuntamiento antes de pasar de ronda
    
    (or (test (eq ?nombre_ronda_actual RONDA_2))
        (test (eq ?nombre_ronda_actual RONDA_4))
        (test (eq ?nombre_ronda_actual RONDA_6))
        (test (eq ?nombre_ronda_actual RONDA_8))
        (edificio_entregado ?nombre_ronda_actual)
    )
    
    ; evita que se pase de ronda antes de actualizar el mazo cuando se entrega un edificio al ayuntamiento
    (not (actualizar_mazo ? ? ?))
     =>
     
    (retract ?ronda_actual)
    (assert (ronda_actual ?nombre_ronda_siguiente))
    (retract ?cambiar)

    (assert (BARCO_DISPONIBLE (nombre_barco ?nombre_barco)))
    (unmake-instance ?introduce_barco)

    (retract ?cantidad_restante_j1)
    (retract ?cantidad_restante_j2)

    (printout t"Nuevo Barco disponible para la nueva ronda: <" ?nombre_barco ">." crlf)
    (printout t"Se ha cambiado de Ronda: <"?nombre_ronda_actual "> a Ronda: <"?nombre_ronda_siguiente">." crlf)
)

(defrule RONDA_EXTRA_FINAL
    ; lanzar los flags para recorrer en bucles las relaciones y obtener los valores de las cartas?
    ; o hacer contadores en los jugadores q te digan cuanto valor acumulado tienen los jugadores y obtenerlo de ahí?
    ; esta segunda opción puede ser más sencilla pero requiere que se modifiquen los valores de las reglas de comprar
    ; y vender cartas ... 
    ; también puede reducir el nº de reglas totales...
    (ronda_actual RONDA_EXTRA_FINAL)
    =>
    (printout t"RONDA FINAL ALCANZADA!" crlf)

)

 (defrule GENERAR_DESEO
     ; Esperar a que termine el proceso de ejecución de cambio de ronda.
     (not (cambiar_ronda TRUE))
     (not (ronda_actual RONDA_EXTRA_FINAL))
     (turno ?jugador)
     (not (deseo_coger_recurso ?jugador ?recurso))
     (OFERTA_RECURSO (recurso ?recurso) (cantidad ?cantidad_oferta))
     (test (> ?cantidad_oferta 0))
     =>
     (assert (deseo_coger_recurso ?jugador ?recurso))
     (printout t"DESEO GENERADO" crlf)
 )

(defrule CALCULAR_RIQUEZA_JUGADOR
    (ronda_actual RONDA_EXTRA_FINAL)
    ; OBTENER TODOS LOS INGRESOS Y GASTOS DE CADA JUGADOR Y determinar la riqueza de cada jugador.
    ?ref <- (calcular_valor_edificios ?nombre_jugador)

    =>
    (assert (riqueza ?nombre_jugador ?beneficios))
)

; DETERMINAR EL GANADOR DE LA PARTIDA.
(defrule MOSTRAR_RESULTADOS_PARTIDA
    (ronda_actual RONDA_EXTRA_FINAL)
    (object (is-a JUGADOR) (nombre ?nombre_jugador1))
    (object (is-a JUGADOR) (nombre ?nombre_jugador2))
    (test (neq ?nombre_jugador1 ?nombre_jugador2))
    (riqueza ?nombre_jugador1 ?riqueza_j1)
    (riqueza ?nombre_jugador2 ?riqueza_j2)
    =>
    (printout t"Resultados partida para 2 jugadores Le Havre:" crlf)
    (printout t"El Jugador: <" ?nombre_jugador1 "> ha obtenido una riqueza de: <" ?riqueza_j1 "> francos. " crlf)
    (printout t"El Jugador: <" ?nombre_jugador1 "> ha obtenido una riqueza de: <" ?riqueza_j1 "> francos. " crlf)

)