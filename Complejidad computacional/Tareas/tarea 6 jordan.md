Sea ($G=(V,E)$) un grafo plano y sea ($\mu$) un embebimiento lineal a trozos de ($G$) en el plano. Supondremos que las coordenadas de los puntos del embebimiento son enteras y están acotadas polinomialmente.

Queremos construir una función

$$
\omega:\vec E(G)\to \mathbb Z
$$

tal que

$$
\omega(u,v)=-\omega(v,u)
$$

y, para todo ciclo dirigido simple ($C$),

$$
\sum_{e\in C}\omega(e)\neq 0.
$$

Sea una arista dirigida ($e=(u,v)$). Como ($\mu$) es lineal a trozos, podemos escribirla como una sucesión de puntos

$$
p_0,p_1,\ldots,p_k,
$$

donde

$$
p_i=(x_i,y_i),\qquad
p_0=\mu(u),\qquad
p_k=\mu(v).
$$

Definimos

$$
\boxed{
\omega(u,v)
=
\sum_{i=0}^{k-1}
\left(
x_i y_{i+1}-x_{i+1}y_i
\right)
}.
$$

Como las coordenadas son enteras,

$$
\omega(u,v)\in\mathbb Z.
$$

Ahora probamos la antisimetría. Al recorrer la arista en sentido contrario, cada segmento

$$
p_i\to p_{i+1}
$$

se convierte en

$$
p_{i+1}\to p_i.
$$

Su contribución cambia de

$$
x_i y_{i+1}-x_{i+1}y_i
$$

a

$$
x_{i+1}y_i-x_i y_{i+1}
=
-\left(
x_i y_{i+1}-x_{i+1}y_i
\right).
$$

Por tanto,

$$
\boxed{
\omega(v,u)=-\omega(u,v)
}.
$$

Sea ahora ($C$) un ciclo dirigido simple.

Como ($G$) está planarmente embebido y ($C$) es simple, ($\mu(C)$) es una curva poligonal simple cerrada.

Por el **Teorema de la curva de Jordan**, toda curva simple cerrada en el plano separa el plano en una región interior y una región exterior. En particular, ($C$) encierra una región ($R_C$) con

$$
\operatorname{Area}(R_C)>0.
$$

Sean

$$
q_0,q_1,\ldots,q_m=q_0
$$

los puntos consecutivos que forman la representación poligonal de ($C$), donde

$$
q_i=(x_i,y_i).
$$

Al sumar los pesos de todas las aristas de ($C$), las contribuciones de todos sus segmentos son

$$
\sum_{e\in C}\omega(e)
=
\sum_{i=0}^{m-1}
\left(
x_i y_{i+1}-x_{i+1}y_i
\right).
$$

Aplicamos ahora la **fórmula de Shoelace**.

Para un polígono simple con vértices

$$
(x_0,y_0),\ldots,(x_{m-1},y_{m-1}),
$$

su área orientada es

$$
A_{\mathrm{or}}(C)
=
\frac12
\sum_{i=0}^{m-1}
\left(
x_i y_{i+1}-x_{i+1}y_i
\right).
$$

Luego

$$
\sum_{e\in C}\omega(e)
=
2A_{\mathrm{or}}(C).
$$

Si el ciclo se recorre en sentido antihorario,

$$
A_{\mathrm{or}}(C)
=
\operatorname{Area}(R_C),
$$

y si se recorre en sentido horario,

$$
A_{\mathrm{or}}(C)
=
-\operatorname{Area}(R_C).
$$

Por tanto,

$$
\boxed{
\sum_{e\in C}\omega(e)
=
\pm 2\operatorname{Area}(R_C)
}.
$$

Por el Teorema de Jordan,

$$
\operatorname{Area}(R_C)>0.
$$

Entonces

$$
\boxed{
\sum_{e\in C}\omega(e)\neq0
}.
$$

Finalmente, veamos la complejidad espacial.

Para calcular ($\omega(u,v)$), procesamos los segmentos de la arista uno por uno. Solo debemos almacenar en cada momento

$$
x_i,\ y_i,\ x_{i+1},\ y_{i+1},
$$

un contador y una suma parcial.

Si la entrada tiene tamaño ($n$) y las coordenadas están acotadas por ($n^{O(1)}$), cada coordenada requiere

$$
O(\log n)
$$

bits.

Los productos

$$
x_i y_{i+1}
$$

y

$$
x_{i+1}y_i
$$

también tienen ($O(\log n)$) bits, y una suma de una cantidad polinomial de estos términos sigue requiriendo ($O(\log n)$) bits.

Por tanto,

$$
\boxed{
\omega
\text{ puede calcularse usando }
O(\log n)
\text{ espacio}.
}
$$

Así obtenemos una función computable en LOGSPACE que satisface

$$
\boxed{
\omega(u,v)=-\omega(v,u)
}
$$

y

$$
\boxed{
\forall C\text{ ciclo dirigido simple},
\quad
\sum_{e\in C}\omega(e)\neq0.
}
$$

Los únicos resultados geométricos usados son el **Teorema de la curva de Jordan** y la **fórmula de Shoelace**.