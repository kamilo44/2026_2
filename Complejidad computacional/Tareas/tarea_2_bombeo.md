Queremos demostrar que

$$
L_0=
\left\{
(01)^i(10)^j(01)^j(10)^i:
i>j>0
\right\}
$$

no es un lenguaje libre de contexto.

Procedemos por contradicción.

Supongamos que

$$
L_0\in CFL.
$$

Entonces, por el lema de bombeo para lenguajes libres de contexto, existe una constante de bombeo

$$
p\geq1
$$

tal que toda palabra ($s\in L_0$), con

$$
|s|\geq p,
$$

puede escribirse como

$$
s=uvxyz
$$

satisfaciendo

$$
|vxy|\leq p,
$$

$$
|vy|>0,
$$

y

$$
uv^txy^tz\in L_0
\qquad
\text{para todo }t\geq0.
$$

Escogemos la palabra

$$
s=
(01)^{p+1}
(10)^p
(01)^p
(10)^{p+1}.
$$

Esta palabra pertenece a ($L_0$), pues tomando

$$
i=p+1,
\qquad
j=p,
$$

tenemos

$$
i>j>0.
$$

Dividamos visualmente la palabra en cuatro bloques:

$$
s=
\underbrace{(01)^{p+1}}_{B_1}
\underbrace{(10)^p}_{B_2}
\underbrace{(01)^p}_{B_3}
\underbrace{(10)^{p+1}}_{B_4}.
$$

Las longitudes de estos bloques son

$$
|B_1|=2p+2,
$$

$$
|B_2|=2p,
$$

$$
|B_3|=2p,
$$

$$
|B_4|=2p+2.
$$

Como

$$
|vxy|\leq p,
$$

la subcadena ($vxy$) no puede abarcar dos fronteras entre bloques, ya que cada bloque tiene longitud al menos ($2p$).

Por tanto, ($v$) e ($y$) pueden afectar únicamente:

1. un solo bloque, o
2. dos bloques consecutivos.

Analizamos los casos.

### Caso 1: ($v$) e ($y$) afectan un solo bloque

Supongamos, por ejemplo, que solamente afectan ($B_1$).

Al bombear con

$$
t=0
$$

o con

$$
t=2,
$$

se modifica ($B_1$), mientras que ($B_4$) permanece exactamente igual.

Pero para que una palabra pertenezca a ($L_0$), el número de repeticiones del primer y del cuarto bloque debe ser el mismo:

$$
(01)^i
\qquad\text{y}\qquad
(10)^i.
$$

Por tanto, después del bombeo se rompe la igualdad entre los exponentes de ($B_1$) y ($B_4$).

Si el bombeo destruye además la estructura alternante ($01\,01\cdots$), entonces la palabra claramente tampoco pertenece a ($L_0$).

En cualquier caso,

$$
uv^txy^tz\notin L_0
$$

para algún ($t$).

El mismo argumento se aplica si el bombeo afecta únicamente ($B_2$), ($B_3$) o ($B_4$):

- si cambia ($B_2$) pero no ($B_3$), se rompe la igualdad de los exponentes ($j$);
- si cambia ($B_3$) pero no ($B_2$), ocurre lo mismo;
- si cambia ($B_4$) pero no ($B_1$), se rompe la igualdad de los exponentes ($i$).

Por tanto, ninguna descomposición de este tipo puede satisfacer el lema de bombeo.

### Caso 2: ($vxy$) atraviesa la frontera entre ($B_1$) y ($B_2$)

El bombeo solamente puede modificar los bloques

$$
B_1
\quad\text{y}\quad
B_2.
$$

Los bloques

$$
B_3=(01)^p
$$

y

$$
B_4=(10)^{p+1}
$$

permanecen intactos.

Para que la palabra bombeada siguiera perteneciendo a ($L_0$), necesariamente tendríamos que conservar

$$
\text{exponente de }B_1=p+1
$$

porque ($B_4$) continúa teniendo exponente ($p+1$), y también

$$
\text{exponente de }B_2=p
$$

porque ($B_3$) continúa teniendo exponente ($p$).

Pero como

$$
|vy|>0,
$$

al bombear con ($t=0$) o ($t=2$) se modifica una cantidad positiva de símbolos en la región ($B_1B_2$).

Por tanto, ambos exponentes no pueden permanecer simultáneamente iguales a sus valores originales.

Así,

$$
uv^txy^tz\notin L_0
$$

para algún ($t$).

### Caso 3: ($vxy$) atraviesa la frontera entre ($B_3$) y ($B_4$)

Este caso es simétrico al anterior.

Los bloques

$$
B_1
\quad\text{y}\quad
B_2
$$

permanecen intactos.

Para pertenecer a ($L_0$), los bloques ($B_3$) y ($B_4$) deberían conservar respectivamente los exponentes

$$
p
\quad\text{y}\quad
p+1.
$$

Pero el bombeo modifica una cantidad no nula de símbolos en esa región.

Por tanto, para algún valor de ($t$),

$$
uv^txy^tz\notin L_0.
$$

### Caso 4: ($vxy$) atraviesa la frontera entre los dos bloques centrales ($B_2$) y ($B_3$)

Este es el caso más importante.

La palabra tiene la forma

$$
\underbrace{(01)^{p+1}}_{B_1}
\underbrace{(10)^p(01)^p}_{B_2B_3}
\underbrace{(10)^{p+1}}_{B_4}.
$$

El bombeo solamente afecta los dos bloques centrales.

Los bloques exteriores permanecen exactamente iguales:

$$
B_1=(01)^{p+1}
$$

y

$$
B_4=(10)^{p+1}.
$$

Por tanto, si una palabra bombeada todavía perteneciera a ($L_0$), necesariamente su parámetro exterior seguiría siendo

$$
i=p+1.
$$

Ahora existen dos posibilidades.

Si el bombeo modifica de manera diferente los bloques ($B_2$) y ($B_3$), entonces sus exponentes dejan de ser iguales y obtenemos inmediatamente una palabra que no pertenece a ($L_0$).

Es decir, tendríamos algo de la forma

$$
(01)^{p+1}
(10)^{j_1}
(01)^{j_2}
(10)^{p+1}
$$

con

$$
j_1\neq j_2.
$$

Por tanto,

$$
uv^txy^tz\notin L_0.
$$

La única posibilidad restante sería que el bombeo aumentara ambos bloques centrales de forma compatible, conservando

$$
j_1=j_2.
$$

Pero, como

$$
|vy|>0,
$$

al repetir ($v$) e ($y$) suficientemente muchas veces podemos hacer que los bloques centrales crezcan arbitrariamente.

Por tanto existe algún ($t$) suficientemente grande para el cual el nuevo exponente central ($j'$) satisface

$$
j'\geq p+1.
$$

Sin embargo, el exponente exterior continúa siendo

$$
i=p+1.
$$

Así,

$$
i\leq j',
$$

lo cual contradice la condición necesaria para pertenecer a ($L_0$):

$$
i>j.
$$

Por tanto, también en este caso existe algún ($t\geq0$) tal que

$$
uv^txy^tz\notin L_0.
$$

Hemos demostrado que para cualquier descomposición

$$
s=uvxyz
$$

que satisfaga

$$
|vxy|\leq p
$$

y

$$
|vy|>0,
$$

existe algún valor ($t\geq0$) para el cual

$$
uv^txy^tz\notin L_0.
$$

Esto contradice el lema de bombeo para lenguajes libres de contexto.

Por lo tanto, nuestra suposición inicial era falsa.

Concluimos que

$$
\boxed{
L_0\notin CFL.
}
$$

($\square$)

____________________________________________

Sea

$$
L_0=
\left\{
(01)^i(10)^j(01)^j(10)^i
:
i>j>0
\right\}.
$$

Supongamos, por contradicción, que

$$
L_0\in CFL.
$$

Sea ($p$) la longitud de bombeo. Elegimos

$$
w=(01)^{p+1}(10)^p(01)^p(10)^{p+1}.
$$

Como ($p+1>p>0$),

$$
w\in L_0.
$$

Por el lema de bombeo para CFL, existe una descomposición

$$
w=uvxyz
$$

tal que

$$
|vxy|\leq p,
\qquad
|vy|>0,
$$

y debería cumplirse

$$
uv^txy^tz\in L_0
$$

para todo ($t\geq0$).

Dividimos ($w$) en cuatro bloques:

$$
\underbrace{(01)^{p+1}}_{B_1}
\underbrace{(10)^p}_{B_2}
\underbrace{(01)^p}_{B_3}
\underbrace{(10)^{p+1}}_{B_4}.
$$

Cada bloque tiene longitud al menos ($2p$). Como

$$
|vxy|\leq p,
$$

la subcadena ($vxy$) puede encontrarse dentro de un solo bloque o atravesar, como máximo, una frontera entre dos bloques consecutivos.

Si ($v$) e ($y$) afectan solamente un bloque, al bombear con ($t=0$) o ($t=2$) ocurre una de dos cosas: se rompe la estructura alternante ($01$) o ($10$), en cuyo caso la palabra no pertenece a ($L_0$); o se conserva dicha estructura, pero cambia el exponente de ese bloque mientras su bloque correspondiente permanece igual. Por ejemplo, si cambia ($B_1$) pero no ($B_4$), dejan de tener el mismo exponente ($i$). Análogamente, si cambia ($B_2$) pero no ($B_3$), se pierde la igualdad de los exponentes ($j$). En ambos casos,

$$
uv^txy^tz\notin L_0
$$

para algún ($t$).

Si ($vxy$) atraviesa la frontera entre ($B_1$) y ($B_2$), bombeamos con ($t=0$). Los bloques ($B_3$) y ($B_4$) permanecen intactos y, por tanto, obligan a que los exponentes sigan siendo

$$
j=p,\qquad i=p+1.
$$

Sin embargo, como ($|vy|>0$), al eliminar ($v$) e ($y$) disminuye la longitud de ($B_1B_2$). Por tanto, no pueden conservarse simultáneamente esos dos exponentes. Luego la palabra bombeada no pertenece a ($L_0$).

El mismo argumento se aplica si ($vxy$) atraviesa la frontera entre ($B_3$) y ($B_4$).

Finalmente, supongamos que ($vxy$) atraviesa la frontera central

$$
B_2|B_3.
$$

Los bloques exteriores ($B_1$) y ($B_4$) no cambian, por lo que necesariamente

$$
i=p+1.
$$

Si el bombeo rompe la forma

$$
(10)^{j'}(01)^{j'},
$$

la palabra queda inmediatamente fuera de ($L_0$).

Si conserva esta forma, bombeamos suficientemente muchas veces. Como

$$
|vy|>0,
$$

los bloques centrales aumentan de longitud mientras los exteriores permanecen fijos. Por ejemplo, tomando ($t$) suficientemente grande obtenemos un nuevo exponente ($j'$) tal que

$$
j'\geq p+1.
$$

Pero

$$
i=p+1,
$$

por lo que

$$
j'\geq i,
$$

contradiciendo la condición requerida

$$
i>j'.
$$

Por tanto, en todos los posibles casos existe algún ($t\geq0$) para el cual

$$
uv^txy^tz\notin L_0.
$$

Esto contradice el lema de bombeo para lenguajes libres de contexto.

En consecuencia,

$$
\boxed{L_0\notin CFL}.
$$

($\square$)