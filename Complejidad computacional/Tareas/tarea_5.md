**Teorema.**  
$$
\text{GROUP-ISOMORPHISM}\in NP[(\log n)^4].
$$

**Demostración.**  
Sean ($G$) y ($H$) dos grupos finitos dados mediante sus tablas de multiplicación. Debemos decidir si existe un isomorfismo

$$
\varphi:G\to H.
$$

Si ($|G|\neq |H|$), entonces claramente ($G\not\cong H$), así que rechazamos. Supongamos entonces

$$
|G|=|H|=m.
$$

Usaremos el siguiente hecho.

**Lema (consecuencia del Teorema de Lagrange).** Todo grupo finito ($G$) de orden ($m$) posee un conjunto generador de tamaño a lo sumo

$$
\lceil\log_2 m\rceil.
$$

En efecto, comenzamos con ($G_0=\{e\}$). Si ($G_i\neq G$), escogemos ($g_{i+1}\notin G_i$) y definimos

$$
G_{i+1}=\langle G_i,g_{i+1}\rangle.
$$

Como ($G_i$) es un subgrupo propio de ($G_{i+1}$), por el **Teorema de Lagrange**,

$$
[G_{i+1}:G_i]\ge 2,
$$

y por tanto

$$
|G_{i+1}|\ge 2|G_i|.
$$

Después de ($k$) generadores tenemos

$$
|G_k|\ge 2^k.
$$

Como ($G_k\subseteq G$),

$$
2^k\le m,
$$

de donde

$$
k\le \log_2 m.
$$

Ahora construimos una máquina no determinista de tiempo polinomial.

La máquina adivina un conjunto

$$
S=\{g_1,\ldots,g_k\}\subseteq G,
\qquad k\le \lceil\log_2m\rceil,
$$

y elementos

$$
h_1,\ldots,h_k\in H,
$$

interpretando

$$
\varphi(g_i)=h_i.
$$

Cada elemento de ($G$) o ($H$) puede identificarse usando

$$
O(\log m)
$$

bits. Como se adivinan a lo sumo ($2k$) elementos,

$$
2k\log m
\le
2(\log m)^2.
$$

Por tanto, se utilizan

$$
O((\log m)^2)
$$

bits nondeterministas.

Después, determinísticamente, la máquina verifica que

$$
\langle g_1,\ldots,g_k\rangle=G.
$$

Como los ($g_i$) generan ($G$), sus imágenes ($h_i$) determinan cualquier posible homomorfismo. Usando las tablas de multiplicación se construye la función candidata

$$
\varphi:G\to H.
$$

Finalmente se verifica, en tiempo polinomial, que:

$$
\varphi
$$

es biyectiva y que para todo ($x,y\in G$),

$$
\varphi(xy)=\varphi(x)\varphi(y).
$$

Si ambas propiedades se cumplen, ($\varphi$) es, por definición, un isomorfismo y la máquina acepta.

La máquina es correcta porque:

- Si ($G\cong H$), existe un conjunto generador de tamaño ($\le\log m$), y alguna rama puede adivinar esos generadores y sus imágenes bajo un isomorfismo real.
- Si una rama acepta, ha construido una biyección que preserva la operación, por lo que ($G\cong H$).

Sea ahora ($n$) la longitud total de la entrada. Como las tablas de multiplicación representan grupos de ($m$) elementos,

$$
\log m=O(\log n).
$$

Entonces la máquina usa

$$
O((\log n)^2)
$$

bits nondeterministas.

Por tanto,

$$
\text{GROUP-ISOMORPHISM}
\in NP[(\log n)^2].
$$

Finalmente, puesto que

$$
(\log n)^2=O((\log n)^4),
$$

se tiene

$$
NP[(\log n)^2]\subseteq NP[(\log n)^4].
$$

Luego,

$$
\boxed{\text{GROUP-ISOMORPHISM}\in NP[(\log n)^4].}
$$

($\square$)