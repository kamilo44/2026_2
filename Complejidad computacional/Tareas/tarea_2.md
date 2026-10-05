**Proposición.** Sea

$$
PAL=\{w\in\{0,1\}^*:w=w^R\}.
$$

Entonces

$$
PAL\notin DCFL.
$$

**Demostración.** Procedemos por contradicción. Supongamos que

$$
PAL\in DCFL.
$$

Sea

$$
E=\{w\in\{0,1\}^*: |w|>0\text{ y }|w|\text{ es par}\}.
$$

El lenguaje ($E$) es regular. Como los lenguajes deterministas libres de contexto son cerrados bajo intersección con lenguajes regulares, tendríamos

$$
P=PAL\cap E\in DCFL.
$$

Pero ($P$) es precisamente el lenguaje de los palíndromos de longitud par no vacíos:

$$
P=\{ww^R:w\in\{0,1\}^+\}.
$$

Definimos ahora

$$
\operatorname{Min}(P)
=
\{x\in P:\text{ ningún prefijo propio de }x\text{ pertenece a }P\}.
$$

Usamos la propiedad de que, si ($L$) es un DCFL y ($\epsilon\notin L$), entonces ($\operatorname{Min}(L)$) también es un DCFL. Como ($\epsilon\notin P$),

$$
\operatorname{Min}(P)\in DCFL.
$$

Consideremos además el lenguaje regular

$$
R=(01)^+(10)^+(01)^+(10)^+.
$$

Por clausura bajo intersección con lenguajes regulares,

$$
L_0=\operatorname{Min}(P)\cap R
$$

también tendría que ser un DCFL y, por tanto, un CFL.

Veamos cuál es la forma de ($L_0$). Todo elemento de ($R$) tiene la forma

$$
(01)^i(10)^j(01)^k(10)^\ell,
\qquad i,j,k,\ell>0.
$$

Para que esta palabra sea un palíndromo debe cumplirse

$$
i=\ell
\qquad\text{y}\qquad
j=k.
$$

Por tanto, los palíndromos de ($R$) tienen la forma

$$
(01)^i(10)^j(01)^j(10)^i.
$$

Además, si ($i\le j$), la palabra posee como prefijo propio el palíndromo

$$
(01)^i(10)^i,
$$

de modo que no pertenece a ($\operatorname{Min}(P)$). En cambio, si ($i>j$), ningún prefijo propio es un palíndromo par. Por consiguiente,

$$
L_0=
\left\{
(01)^i(10)^j(01)^j(10)^i:
i>j>0
\right\}.
$$

Definamos el homomorfismo

$$
h:\{a,b\}^*\longrightarrow\{0,1\}^*
$$

mediante

$$
h(a)=01,\qquad h(b)=10.
$$

Los CFL son cerrados bajo homomorfismo inverso. Por tanto, si ($L_0$) fuera CFL, también tendría que ser CFL

$$
h^{-1}(L_0)
=
\{a^ib^ja^jb^i:i>j>0\}.
$$

Denotemos este lenguaje por

$$
K=\{a^ib^ja^jb^i:i>j>0\}.
$$

Demostraremos mediante el lema de bombeo para CFL que ($K$) no es libre de contexto.

Supongamos que ($K$) es CFL y sea ($p$) su longitud de bombeo. Consideremos

$$
z=a^{p+1}b^pa^pb^{p+1}.
$$

Como ($p+1>p>0$),

$$
z\in K.
$$

Por el lema de bombeo, ($z$) puede escribirse como

$$
z=uvxyz
$$

de modo que

$$
|vxy|\le p,
\qquad
|vy|>0,
$$

y

$$
uv^txy^tz\in K
$$

para todo ($t\ge0$).

Sin embargo, ($z$) está formada por cuatro bloques:

$$
\underbrace{a^{p+1}}_1
\underbrace{b^p}_2
\underbrace{a^p}_3
\underbrace{b^{p+1}}_4.
$$

Como

$$
|vxy|\le p,
$$

la subcadena ($vxy$) puede estar contenida en un solo bloque o puede atravesar, como máximo, la frontera entre dos bloques consecutivos.

En particular, ($v$) e ($y$) no pueden afectar simultáneamente los bloques ($1$) y ($4$), ni pueden afectar simultáneamente los bloques ($2$) y ($3$) de manera que se conserven las dos igualdades exigidas por ($K$).

Al bombear con ($t=0$) o ($t=2$), al menos uno de los cuatro bloques cambia de longitud, pues

$$
|vy|>0,
$$

mientras que su bloque correspondiente no cambia. Por tanto se destruye al menos una de las condiciones

$$
|{\rm bloque}_1|=|{\rm bloque}_4|
$$

o

$$
|{\rm bloque}_2|=|{\rm bloque}_3|.
$$

Si ($v$) o ($y$) atraviesa una frontera entre bloques, al bombear con ($t=2$) también puede destruirse directamente la forma

$$
a^+b^+a^+b^+.
$$

En cualquier caso existe ($t\ge0$) tal que

$$
uv^txy^tz\notin K,
$$

contradiciendo el lema de bombeo para lenguajes libres de contexto.

Por lo tanto,

$$
K\notin CFL.
$$

Esto implica que ($L_0\notin CFL$), contradiciendo que ($L_0$) debía ser un DCFL.

La contradicción proviene de haber supuesto que

$$
PAL\in DCFL.
$$

Por consiguiente,

$$
\boxed{PAL\notin DCFL}.
$$

Como, además, ($PAL$) sí es libre de contexto, por ejemplo mediante la gramática

$$
S\to 0S0\mid1S1\mid0\mid1\mid\epsilon,
$$

concluimos finalmente que

$$
\boxed{PAL\in CFL\setminus DCFL}.
$$

($\square$)