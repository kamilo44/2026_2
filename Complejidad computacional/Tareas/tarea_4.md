Queremos demostrar:

$$
SAT \le_p CNF\text{-}SAT
$$

y

$$
SAT \le_p 3\text{-}SAT.
$$

Sea $(\varphi)$ una fórmula booleana arbitraria.

### 1. Demostración de $(SAT \le_p CNF\text{-}SAT)$

Construimos una fórmula CNF $(\psi)$ equisatisfacible con $(\varphi)$.

Para cada subfórmula de $(\varphi)$, introducimos una nueva variable que represente su valor de verdad.

Si una subfórmula es

$$
z \leftrightarrow (x\land y),
$$

la reemplazamos por las cláusulas

$$
(\neg z\vee x)
\land
(\neg z\vee y)
\land
(z\vee\neg x\vee\neg y).
$$

Si es

$$
z\leftrightarrow(x\vee y),
$$

usamos

$$
(z\vee\neg x)
\land
(z\vee\neg y)
\land
(\neg z\vee x\vee y).
$$

Si es

$$
z\leftrightarrow\neg x,
$$

usamos

$$
(z\vee x)\land(\neg z\vee\neg x).
$$

Sea $(z_\varphi)$ la variable que representa toda la fórmula $(\varphi)$. Añadimos además la cláusula

$$
(z_\varphi),
$$

para obligar a que la fórmula original sea verdadera.

La fórmula resultante $(\psi)$ está en CNF.

Por construcción,

$$
\varphi \text{ es satisfacible}
\iff
\psi \text{ es satisfacible}.
$$

En efecto, si una asignación satisface $(\varphi)$, se asigna a cada variable auxiliar el valor de su correspondiente subfórmula y se satisface $(\psi)$. En sentido contrario, las cláusulas de $(\psi)$ obligan a que cada variable auxiliar represente correctamente su subfórmula; como $(z_\varphi=1)$, entonces $(\varphi)$ es verdadera.

Además, por cada operador de $(\varphi)$ se crean solamente una cantidad constante de cláusulas. Si

$$
|\varphi|=n,
$$

entonces

$$
|\psi|=O(n),
$$

y la transformación puede realizarse en tiempo polinomial.

Por tanto,

$$
\boxed{SAT\le_p CNF\text{-}SAT}.
$$

---

### 2. Demostración de $(CNF\text{-}SAT\le_p3\text{-}SAT)$

Sea

$$
\psi=C_1\land C_2\land\cdots\land C_m
$$

una fórmula en CNF.

Consideremos una cláusula con más de tres literales:

$$
C=(l_1\vee l_2\vee\cdots\vee l_k),
\qquad k>3.
$$

Introducimos nuevas variables

$$
y_1,\ldots,y_{k-3}
$$

y reemplazamos $(C)$ por

$$
(l_1\vee l_2\vee y_1)
$$

$$
\land(\neg y_1\vee l_3\vee y_2)
$$

$$
\land\cdots\land
$$

$$
(\neg y_{k-3}\vee l_{k-1}\vee l_k).
$$

Todas las nuevas cláusulas tienen tres literales.

La nueva fórmula es satisfacible si y solo si la cláusula original lo era. Si todos los $(l_i)$ fueran falsos, la primera cláusula obligaría a $(y_1=1)$, la segunda a $(y_2=1)$, y así sucesivamente, hasta que la última cláusula resultaría falsa. Por tanto, al menos uno de los $(l_i)$ debe ser verdadero.

En sentido contrario, si algún $(l_i)$ es verdadero, es posible elegir valores adecuados para las variables auxiliares $(y_i)$ de manera que todas las nuevas cláusulas sean verdaderas.

Para una cláusula de dos literales

$$
(l_1\vee l_2),
$$

podemos reemplazarla por

$$
(l_1\vee l_2\vee y)
\land
(l_1\vee l_2\vee\neg y).
$$

Para una cláusula unitaria $((l))$, si se permiten literales repetidos, podemos escribir

$$
(l\vee l\vee l).
$$

Cada cláusula de tamaño $(k)$ genera $(O(k))$ cláusulas nuevas, por lo que el tamaño total de la fórmula resultante es polinomial respecto al tamaño de la fórmula original.

Así,

$$
\boxed{CNF\text{-}SAT\le_p3\text{-}SAT}.
$$

Finalmente, por transitividad de las reducciones polinomiales,

$$
SAT\le_p CNF\text{-}SAT
$$

y

$$
CNF\text{-}SAT\le_p3\text{-}SAT
$$

implican

$$
\boxed{SAT\le_p3\text{-}SAT}.
$$

Por lo tanto,

$$
\boxed{SAT\le_p CNF\text{-}SAT}
$$

y

$$
\boxed{SAT\le_p3\text{-}SAT}.
$$
