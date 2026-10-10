Sea ($G=(V,E)$) un grafo plano y sea ($\mu$) un embebimiento lineal a trozos de ($G$) en el plano. Supondremos la codificación usual: los puntos del embebimiento tienen coordenadas enteras de tamaño polinomial. Si son racionales, se multiplican todas por un denominador común.

Queremos construir

$$
\omega:\vec E(G)\rightarrow \mathbb Z
$$

tal que

$$
\omega(u,v)=-\omega(v,u)
$$

y para todo ciclo dirigido simple ($C$),

$$
\sum_{e\in C}\omega(e)\neq 0.
$$

### 1. Definición de los pesos

Sea ($e=(u,v)$) una arista dirigida. Como ($\mu$) es lineal a trozos, su representación es una sucesión

$$
p_0,p_1,\ldots,p_k,
$$

donde

$$
p_0=\mu(u),\qquad p_k=\mu(v),
$$

y

$$
p_i=(x_i,y_i).
$$

Definimos

$$
\boxed{
\omega(u,v)=
\sum_{i=0}^{k-1}
\left(x_i y_{i+1}-x_{i+1}y_i\right)
}.
$$

Como todas las coordenadas son enteras,

$$
\omega(u,v)\in\mathbb Z.
$$

### 2. Antisimetría

Al recorrer la misma arista en dirección contraria, los puntos aparecen como

$$
p_k,p_{k-1},\ldots,p_0.
$$

Por tanto,

$$
\omega(v,u)
=
\sum_{i=0}^{k-1}
\left(x_{i+1}y_i-x_i y_{i+1}\right).
$$

Pero cada término satisface

$$
x_{i+1}y_i-x_i y_{i+1}
=
-\left(x_i y_{i+1}-x_{i+1}y_i\right).
$$

Luego

$$
\boxed{\omega(v,u)=-\omega(u,v)}.
$$

### 3. Circulación de un ciclo

Sea ($C$) un ciclo dirigido simple.

Por el **Teorema de la curva de Jordan**, una curva simple cerrada en el plano separa el plano en una región interior y una exterior.

Como ($G$) está embebido planarmente y ($C$) es simple, ($\mu(C)$) es una curva poligonal simple cerrada y, por tanto, encierra una región ($R_C$) de área estrictamente positiva:

$$
\operatorname{Area}(R_C)>0.
$$

Sean

$$
q_0,q_1,\ldots,q_m=q_0
$$

todos los puntos consecutivos de la curva poligonal que representa ($C$), con

$$
q_i=(x_i,y_i).
$$

Por definición de ($\omega$),

$$
\sum_{e\in C}\omega(e)
=
\sum_{i=0}^{m-1}
(x_i y_{i+1}-x_{i+1}y_i).
$$

Aplicamos ahora la **fórmula de Shoelace (fórmula del área de un polígono)**:

$$
A_{\mathrm{or}}(C)
=
\frac12
\sum_{i=0}^{m-1}
(x_i y_{i+1}-x_{i+1}y_i),
$$

donde ($A_{\mathrm{or}}(C)$) es el área orientada del polígono.

Por tanto,

$$
\sum_{e\in C}\omega(e)
=
2A_{\mathrm{or}}(C).
$$

Si ($C$) se recorre antihorariamente,

$$
A_{\mathrm{or}}(C)=\operatorname{Area}(R_C),
$$

y si se recorre horariamente,

$$
A_{\mathrm{or}}(C)=-\operatorname{Area}(R_C).
$$

Así,

$$
\sum_{e\in C}\omega(e)
=
\pm2\operatorname{Area}(R_C).
$$

Como

$$
\operatorname{Area}(R_C)>0,
$$

se concluye que

$$
\boxed{
\sum_{e\in C}\omega(e)\neq0
}.
$$

### 4. Complejidad espacial

Para calcular ($\omega(u,v)$) no necesitamos almacenar todo el grafo ni buscar sus ciclos.

Procesamos cada segmento de una arista uno a la vez. Para el segmento

$$
(x_i,y_i)\rightarrow(x_{i+1},y_{i+1})
$$

solo necesitamos mantener:

$$
x_i,\ y_i,\ x_{i+1},\ y_{i+1},
$$

un índice y un acumulador para

$$
\sum
(x_i y_{i+1}-x_{i+1}y_i).
$$

Si la entrada tiene tamaño ($n$) y las coordenadas tienen magnitud ($n^{O(1)}$), cada coordenada requiere

$$
O(\log n)
$$

bits. Cada producto tiene también ($O(\log n)$) bits y la suma de una cantidad polinomial de términos continúa teniendo ($O(\log n)$) bits.

Además, suma, resta y multiplicación de enteros de ($O(\log n)$) bits pueden realizarse usando ($O(\log n)$) espacio.

Por tanto, cada peso se puede producir secuencialmente utilizando

$$
\boxed{O(\log n)}
$$

espacio de trabajo.

En consecuencia,

$$
\boxed{
\omega\text{ puede construirse determinísticamente en LOGSPACE}.
}
$$

La construcción satisface simultáneamente

$$
\boxed{\omega(u,v)=-\omega(v,u)}
$$

y

$$
\boxed{
\forall C\text{ ciclo dirigido simple},\quad
\sum_{e\in C}\omega(e)\neq0.
}
$$

Los dos resultados geométricos utilizados son:

1. **Teorema de la curva de Jordan:** todo ciclo simple embebido en el plano encierra una región de área positiva.
2. **Fórmula de Shoelace:** la suma
   $$
   \sum_i(x_i y_{i+1}-x_{i+1}y_i)
   $$
   es dos veces el área orientada del polígono.