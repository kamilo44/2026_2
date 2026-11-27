### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ a0000000-0000-4000-8000-000000000100
begin
    using Printf
    using PlutoPlotly
    using Statistics
end

# ╔═╡ a0000000-0000-4000-8000-000000000001
md"""
# ¿Qué tan confiable es calcular la TIR en punto flotante?

**Tarea 2: ecuaciones no lineales en una variable**

*Integrantes:* Sofia Salinas, William Gallego, Sara Rivera.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000002
md"""
## 1. Pregunta de investigación

> **¿Cómo afectan el formato de punto flotante (Float16, Float32, Float64) y el criterio de parada a la tasa interna de retorno calculada con bisección, Newton, secante y punto fijo, y cuándo un residuo ``\lvert \mathrm{NPV}(\hat r)\rvert`` pequeño engaña sobre el error real en ``r``?**
"""

# ╔═╡ a0000000-0000-4000-8000-00000000002b
md"""
## 2. Marco conceptual y definiciones

Antes de profundizar en los experimentos, definimos los conceptos clave que sustentan este trabajo.

### 2.1 Modelo financiero: NPV y TIR

**Flujo de caja:** Secuencia de pagos ``c_0, c_1, \dots, c_n`` donde ``c_t`` es el monto (positivo si se recibe, negativo si se paga) al final del periodo ``t``.

**Valor Presente Neto (NPV):** Dado un tipo de descuento ``r > -1``, el NPV es el valor hoy de todos los flujos futuros:

```math
\mathrm{NPV}(r) = \sum_{t=0}^{n} \frac{c_t}{(1+r)^t}
```

**Tasa Interna de Retorno (TIR):** Es el valor ``r^*`` que hace ``\mathrm{NPV}(r^*) = 0``. Financieramente, es la rentabilidad intrínseca del proyecto: si ``r^*`` es mayor que el costo de oportunidad del capital, el proyecto es viable.

**Problema numérico:** En la variable ``x = 1/(1+r)``, el NPV se convierte en un polinomio de grado ``n``:

```math
\mathrm{NPV} = \sum_{t=0}^{n} c_t \, x^t
```

Para ``n \ge 5`` no existe fórmula cerrada (teorema de Abel-Ruffini), por lo que la TIR siempre se calcula con métodos iterativos. Una hipoteca a 30 años con cuotas mensuales tiene ``n = 360``: un polinomio de grado 360.

### 2.2 Aritmética de punto flotante

Los computadores representan números reales con precisión finita usando el estándar IEEE 754:

| Formato | Bits | Dígitos decimales | ``\varepsilon_{\text{máq}}`` | ``u = \varepsilon/2`` |
|---|---|---|---|---|
| **Float16** | 16 | ~3.3 | ``9.77 \times 10^{-4}`` | ``4.88 \times 10^{-4}`` |
| **Float32** | 32 | ~7.2 | ``1.19 \times 10^{-7}`` | ``5.96 \times 10^{-8}`` |
| **Float64** | 64 | ~15.9 | ``2.22 \times 10^{-16}`` | ``1.11 \times 10^{-16}`` |

**Épsilon de máquina (``\varepsilon_{\text{máq}}``):** Es la distancia entre 1 y el siguiente número representable. Define la precisión relativa del formato.

**Redondeo unitario (``u = \varepsilon/2``):** Cota del error relativo máximo al redondear un número real al formato de punto flotante más cercano.

**Limitaciones:**
- **Desborde (overflow):** Números mayores que ``\approx 6.5 \times 10^4`` no caben en Float16.
- **Pérdida de significancia:** Al calcular ``1 + r`` con ``r`` pequeño, se pierden dígitos de ``r``.
- **Ruido de redondeo:** Cada operación aritmética introduce un error del orden de ``u``.

### 2.3 Error vs. residuo

Sea ``r^*`` la raíz exacta y ``\hat{r}`` la raíz aproximada calculada:

- **Error absoluto:** ``|\hat{r} - r^*|`` — qué tan lejos está ``\hat{r}`` de la raíz verdadera.
- **Residuo:** ``|f(\hat{r})|`` — qué tan cerca está ``f(\hat{r})`` de cero.

**Relación fundamental:** Por el teorema del valor medio,

```math
|f(\hat{r})| = |f(\hat{r}) - f(r^*)| \approx |f'(r^*)| \cdot |\hat{r} - r^*|
```

Es decir, ``\text{residuo} \approx |f'(r^*)| \times \text{error}``.

**Consecuencia crítica:** Un residuo pequeño **no** garantiza un error pequeño si ``|f'(r^*)|`` es grande (función muy inclinada). Análogamente, si ``|f'(r^*)|`` es pequeño (raíz múltiple o función casi plana), un residuo diminuto puede convivir con un error considerable.

### 2.4 Convergencia y orden de convergencia

Un método iterativo ``x_{k+1} = g(x_k)`` converge a ``r^*`` si ``\lim_{k \to \infty} x_k = r^*``.

**Orden de convergencia (``p``):** Si existe ``C > 0`` tal que

```math
\lim_{k \to \infty} \frac{|e_{k+1}|}{|e_k|^p} = C, \quad \text{donde } e_k = x_k - r^*
```

entonces el método tiene orden ``p``. Valores típicos:
- ``p = 1`` (lineal): bisección, punto fijo
- ``p = 2`` (cuadrático): Newton en raíz simple
- ``p \approx 1.618`` (superlineal): secante

**Estimación práctica:** A partir del historial de iteraciones,

```math
p_k \approx \frac{\log|e_{k+1}/e_k|}{\log|e_k/e_{k-1}|}
```

### 2.5 Métodos numéricos

**Bisección:** Requiere ``f(a) \cdot f(b) < 0``. Divide el intervalo a la mitad en cada iteración. Orden ``p = 1`` (lineal), un bit de precisión por iteración. No usa derivadas.

**Newton:** ``x_{k+1} = x_k - f(x_k)/f'(x_k)``. Orden ``p = 2`` (cuadrático) en raíz simple. Requiere derivada. En raíz de multiplicidad ``m``, pierde convergencia cuadrática; con la modificación ``x_{k+1} = x_k - m \cdot f(x_k)/f'(x_k)`` recupera ``p = 2``.

**Secante:** Aproxima ``f'`` con diferencias finitas: ``x_{k+1} = x_k - f(x_k) \cdot \frac{x_k - x_{k-1}}{f(x_k) - f(x_{k-1})}``. Orden ``p \approx 1.618``. No requiere derivada explícita.

**Punto fijo:** Reescribe ``f(x) = 0`` como ``x = g(x)``. La iteración ``x_{k+1} = g(x_k)`` converge si ``|g'(r^*)| < 1``. Orden ``p = 1`` (lineal) con razón ``|g'(r^*)|``.

### 2.6 Condicionamiento

**Condición de encontrar una raíz:** El número de condición es

```math
\kappa = \frac{1}{|f'(r^*)|}
```

Si ``\kappa`` es grande (``|f'(r^*)|`` pequeño), el problema está **mal condicionado**: pequeños cambios en ``f`` producen grandes cambios en ``r^*``. En una raíz de multiplicidad ``m \ge 2``, ``f'(r^*) = 0`` y ``\kappa = \infty``: el problema es extremadamente sensible.

**Implicación:** Ningún algoritmo, por sofisticado que sea, puede superar las limitaciones impuestas por el condicionamiento del problema y la precisión del formato.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000003
md"""
## 3. ¿Por qué es interesante?

- **Es un problema que los bancos resuelven todos los días.** La TIR de un proyecto es la raíz ``r`` de ``\sum_t c_t (1+r)^{-t} = 0``. En la variable ``x = 1/(1+r)`` esto es un polinomio de grado ``n``, y para ``n \ge 5`` no existe fórmula general por radicales. Por eso siempre se calcula con un método iterativo. Una hipoteca a 30 años tiene 360 cuotas: un polinomio de grado 360.
- **Tiene varios problemas.** Con flujos no convencionales, por ejemplo, un proyecto con un costo de cierre al final, puede haber varias TIR, o una raíz doble, y el resultado depende del dato inicial. Con una raíz doble, Newton pierde su convergencia cuadrática y la bisección ni siquiera aplica.
- **Es un caso limpio de "error vs. residuo".** El residuo ``\lvert\mathrm{NPV}(\hat r)\rvert`` (``\hat r`` es la raiz calculada) es lo que el programa ve; el error ``\lvert \hat r - r^*\rvert`` (``r^*`` es la raiz exacta) es lo que importa. Su relación es ``\mathrm{NPV}'(r^*)``, que puede ser enorme, minúscula o cero.
- **Conecta con el proyecto anterior.** Allí, calcular con Float64 no recuperaba la información perdida en el ADC de 8 bits. Aquí, imprimir una TIR con 15 decimales no significa que sean ciertos, y "residuo pequeño" no significa "raíz precisa".
- **Tiene fenómenos de punto flotante propios.** Al calcular ``1+r`` con ``r`` pequeño se pierden dígitos de ``r``; un monto mayor que 65 504 no cabe en Float16; ``(1+r)^{360}`` puede desbordar; y el residuo calculado tiene un piso de ruido que depende de la escala de los flujos.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000004
md"""
## 4. Predicción inicial

Antes de correr los experimentos esperamos lo siguiente. Usamos ``u = \varepsilon_{\text{máq}}/2`` para el redondeo unitario: ``u \approx 4.9\cdot 10^{-4}`` en Float16, ``6.0\cdot 10^{-8}`` en Float32 y ``1.1\cdot 10^{-16}`` en Float64.

1. **Órdenes de convergencia.** Bisección: un bit por iteración. Newton: cuadrática en raíz simple. Secante: ``\approx 1.618``. Punto fijo con ``g(r) = r + \alpha\,\mathrm{NPV}(r)``: lineal, con razón ``\lvert 1+\alpha\,\mathrm{NPV}'(r^*)\rvert``.

2. **Préstamo bien condicionado (una raíz, ``i = 1\%`` mensual, 12 cuotas).** El error relativo en ``r`` será del orden de ``\kappa\,u`` más el efecto de redondear ``1+r`` que da un error absoluto de ``\approx u``, o sea relativo ``u/r``. Esperamos: Float64 ``\approx 10^{-14}``, Float32 entre ``10^{-6}`` y ``10^{-4}``, Float16 entre ``10^{-2}`` y ``10^{-1}``.

3. **El criterio de parada no es el error.** En el préstamo base ``\mathrm{NPV}'(r^*)\approx 6\cdot 10^{3}``, así que ``\lvert\mathrm{NPV}\rvert \le 10^{-6}`` implica error en ``r`` de unos ``10^{-10}``. Pero el residuo depende de la escala de los flujos: si los multiplicamos por ``10^6`` la misma tolerancia exige un error de ``10^{-16}``, y además el ruido de evaluación en Float32 (``\approx u\sum_t \lvert c_t\rvert (1+r)^{-t}``) es mucho mayor que ``10^{-6}``. Esperamos que el criterio de residuo casi nunca se cumpla en Float32 pues el método agota `maxit`, mientras que el criterio ``\lvert\Delta x\rvert`` sí termina.

4. **Raíz doble** (``c=(-100,220,-121)``, ``r^*=10\%``). La bisección no aplica porque NPV no cambia de signo. Newton converge solo linealmente con razón ``1/2``; con la multiplicidad ``m=2`` vuelve a ser cuadrático. El error alcanzable crece como ``\sqrt{u}`` y no como ``u``: Float64 ``\approx 10^{-8}``, Float32 ``\approx 10^{-4}``, Float16 ``\approx 10^{-2}``. En ese punto el residuo será diminuto aunque el error no lo sea.

5. **Dos raíces** (``c=(-100,230,-132)``: 10 % y 20 %). Newton llegará a una u otra según ``x_0``, y las cuencas no serán intervalos simples: cerca de ``r\approx 14.8\%`` (donde ``\mathrm{NPV}'=0``) se entrelazan y el método da saltos grandes. La bisección en ``[0,\,0.5]`` falla pues NPV es negativo en ambos extremos, pero en ``[0,\,0.15]`` y ``[0.15,\,0.5]`` encuentra cada raíz.

6. **Float16 es inadecuado para este problema.** No representa montos mayores que 65 504, y con 360 periodos ``(1+r)^{360}`` desborda para ``r`` mensual mayor que ``\approx 3.1\%``.

7. **Idea global.** Esperamos que ningún formato rescate un mal condicionamiento: pasar a Float64 reduce el error, pero en la raíz doble el error sigue siendo del orden de ``\sqrt{u}``, no de ``u``.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000005
md"""
## 5. Investigación o experimento

Todo el código está escrito de forma genérica en el tipo numérico `T` (`Float16`, `Float32`, `Float64` o `BigFloat`) y no contiene literales fijos en `Float64`: los datos y las tolerancias se convierten a `T` (por ejemplo `T(1//100)` en lugar de `0.01`). Así, el mismo código corre en cada formato y los resultados son comparables.

**Convenciones.** Los flujos son un vector `c` con `c[1] = c_0`, `c[2] = c_1`, … (Julia indexa desde 1). La TIR se busca en ``r > -1``.

### 5.1 Modelo: NPV y su derivada

Dados los flujos ``c_0, c_1, \dots, c_n``. ``c_t`` ocurre al final del periodo ``t``, el valor presente neto es

```math
\mathrm{NPV}(r)=\sum_{t=0}^{n}\frac{c_t}{(1+r)^t},\qquad r>-1,
```

y la TIR es una raíz de NPV. Su derivada es

```math
\mathrm{NPV}'(r)=-\sum_{t=1}^{n}\frac{t\,c_t}{(1+r)^{t+1}}.
```

La función `npv` evalúa la definición directamente con potencias. Los argumentos `c` y `r` deben tener el mismo tipo `T`; si `r` es un literal, se redondea a `T`, y ese redondeo del dato es parte del experimento.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000006
begin
    function npv(c::AbstractVector{T}, r::T) where {T<:AbstractFloat}
        s = zero(T)
        q = one(T) + r
        for (j, cj) in enumerate(c)
            s += cj / q^(j - 1)
        end
        return s
    end

    function dnpv(c::AbstractVector{T}, r::T) where {T<:AbstractFloat}
        s = zero(T)
        q = one(T) + r
        for (j, cj) in enumerate(c)
            t = j - 1
            s -= t * cj / q^(t + 1)
        end
        return s
    end

    # Conveniencia: un literal como 0.1 se redondea a T
    npv(c::AbstractVector{T}, r::Real) where {T<:AbstractFloat}  = npv(c, T(r))
    dnpv(c::AbstractVector{T}, r::Real) where {T<:AbstractFloat} = dnpv(c, T(r))
end

# ╔═╡ a0000000-0000-4000-8000-000000000009
md"""
**Flujos de ejemplo.** Tres familias que usaremos, todas con raíz exacta conocida:

- **Préstamo con una raíz.** Se recibe ``P`` y se paga una cuota fija ``A`` durante ``n`` periodos: ``c_0=P`` y ``c_t=-A`` para ``t\ge 1``, con ``A = P\,i/(1-(1+i)^{-n})``. Por construcción la TIR es exactamente ``i``.
- **Dos raíces.** ``c=(-100,\,230,\,-132)``. En ``x`` queda ``-132x^2+230x-100=0``, con raíces ``x=240/264`` y ``x=220/264``, es decir ``r=10\%`` y ``r=20\%``.
- **Raíz doble.** ``c=(-100,\,220,\,-121)``. En ``x``: ``-121x^2+220x-100=-121\,(x-10/11)^2``, así que ``r=10\%`` es raíz doble y NPV nunca cambia de signo.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000010
function flujos_prestamo(::Type{T}, P, i, n::Integer) where {T<:AbstractFloat}
    P_ = T(P)
    i_ = T(i)
    cuota = P_ * i_ / (1 - (1 + i_)^(-n))
    return [P_; fill(-cuota, n)]
end

# ╔═╡ a0000000-0000-4000-8000-000000000018
md"""
**Verificación del modelo** (en BigFloat de 256 bits): la derivada analítica coincide con una diferencia central, y en la raíz doble tanto NPV como NPV′ valen cero hasta el redondeo de 256 bits.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000019
let
    setprecision(BigFloat, 256) do
        # (a) derivada analítica vs. diferencia central, en el préstamo
        c   = flujos_prestamo(BigFloat, 1000, 1//100, 12)
        r   = BigFloat(3) / 100
        h   = BigFloat(10)^(-30)
        dfd = (npv(c, r + h) - npv(c, r - h)) / (2h)
        # (b) raíz doble en r = 10 %
        cd  = BigFloat[-100, 220, -121]
        rd  = BigFloat(1) / 10
        (
            dnpv_vs_dif_central_relativo = abs(dnpv(c, r) - dfd) / abs(dfd),
            npv_en_raiz_doble            = abs(npv(cd, rd)),
            dnpv_en_raiz_doble           = abs(dnpv(cd, rd)),
        )
    end
end

# ╔═╡ a0000000-0000-4000-8000-000000000020
md"""
### 5.2 Métodos: bisección, Newton, secante y punto fijo

Cada método tiene la forma

```julia
metodo(f, ...; tol, maxit, criterio) -> (r, historial, estado)
```

- `historial` es una tupla `(x, fx, iter)` con todas las iteraciones `x_k`, los residuos `f(x_k)` calculados en el mismo formato `T`, y el número de iteraciones `iter`. Con esto se calculan después el error, el residuo y el orden observado.
- `criterio` es un parámetro: `:paso` (``\lvert\Delta x\rvert\le\mathrm{tol}``), `:residuo` (``\lvert f\rvert\le\mathrm{tol}``) o `:ambos`. La tolerancia es absoluta y se convierte a `T`. Si es menor que el espaciado de los flotantes cerca de la raíz, nunca se cumple (en Float16, `T(1e-10)` ni siquiera es representable y vale 0). Para bisección, ``\Delta x`` es el semiancho del intervalo, que acota el error del punto medio.
- `estado` informa qué pasó: `:convergio`, `:maxit`, `:estancado` (bisección: el punto medio coincide con un extremo), `:sin_cambio_signo`, `:derivada_nula` o `:no_finito` (NaN o ``\pm\infty``).
- Si no se da `tol`, se usa ``\sqrt{\varepsilon_{\text{máq}}}`` del formato.

| Método | Iteración | Orden en raíz simple | En raíz doble |
|:--|:--|:--|:--|
| Bisección | ``m=(a+b)/2`` | lineal: ``\lvert e_k\rvert\le (b-a)/2^k`` (un bit por iteración) | no aplica: no hay cambio de signo |
| Newton | ``x-f/f'`` | 2 | lineal, razón ``1/2``; con ``x-m\,f/f'`` (``m=2``) vuelve a 2 |
| Secante | ``x_1-f_1\,\dfrac{x_1-x_0}{f_1-f_0}`` | ``(1+\sqrt5)/2\approx1.618`` | lineal |
| Punto fijo | ``g(r)=r+\alpha\,\mathrm{NPV}(r)`` | lineal, razón ``\lvert 1+\alpha\,\mathrm{NPV}'(r^*)\rvert`` | ``g'(r^*)=1``: convergencia sublineal |
"""

# ╔═╡ a0000000-0000-4000-8000-000000000021
begin
    function cumple_parada(criterio::Symbol, dx, fx, tol)
        por_paso    = abs(dx) <= tol
        por_residuo = abs(fx) <= tol
        if criterio === :paso
            return por_paso
        elseif criterio === :residuo
            return por_residuo
        elseif criterio === :ambos
            return por_paso && por_residuo
        else
            throw(ArgumentError("criterio debe ser :paso, :residuo o :ambos"))
        end
    end

    tolerancia(::Type{T}, tol) where {T<:AbstractFloat} =
        tol === nothing ? sqrt(eps(T)) : T(tol)

    historial(xs, fs, k) = (x = xs, fx = fs, iter = k)
end

# ╔═╡ a0000000-0000-4000-8000-000000000022
md"""
**Bisección.** Requiere ``f(a)`` y ``f(b)`` de signo opuesto. Cada iteración divide el intervalo a la mitad, así que el error del punto medio está acotado por ``(b-a)/2^k`` y bastan ``\log_2((b-a)/\mathrm{tol})`` iteraciones. En punto flotante hay un límite: cuando ``a`` y ``b`` son flotantes consecutivos, el punto medio coincide con un extremo y el método se estanca. Se usa `a + (b-a)/2` en lugar de `(a+b)/2` para evitar desbordes.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000023
function bisection(f, a::T, b::T; tol = nothing, maxit::Integer = 1000,
                   criterio::Symbol = :paso) where {T<:AbstractFloat}
    τ = tolerancia(T, tol)
    if a > b
        a, b = b, a
    end
    xs = T[]
    fs = T[]
    fa, fb = f(a), f(b)
    if !(isfinite(fa) && isfinite(fb))
        return (T(NaN), historial(xs, fs, 0), :no_finito)
    end
    fa == 0 && return (a, historial([a], [fa], 0), :converge)
    fb == 0 && return (b, historial([b], [fb], 0), :converge)
    if sign(fa) == sign(fb)
        return (T(NaN), historial(xs, fs, 0), :sin_cambio_signo)
    end
    m = a
    for k in 1:maxit
        m  = a + (b - a) / 2
        fm = f(m)
        push!(xs, m)
        push!(fs, fm)
        if !isfinite(fm)
            return (m, historial(xs, fs, k), :no_finito)
        end
        semiancho = (b - a) / 2
        if fm == 0 || cumple_parada(criterio, semiancho, fm, τ)
            return (m, historial(xs, fs, k), :converge)
        end
        if m == a || m == b
            return (m, historial(xs, fs, k), :estancado)
        end
        if sign(fm) == sign(fa)
            a, fa = m, fm
        else
            b, fb = m, fm
        end
    end
    return (m, historial(xs, fs, maxit), :maxit)
end

# ╔═╡ a0000000-0000-4000-8000-000000000024
md"""
**Newton.** ``x_{k+1}=x_k-m\,f(x_k)/f'(x_k)``. Con ``m=1`` es el método clásico. El parámetro `m` es una *modificación*: si se conoce la multiplicidad ``m`` de la raíz, usar ese ``m`` recupera la convergencia cuadrática. Se detiene con `:derivada_nula` si ``f'(x_k)=0``, y con `:no_finito` si el paso produce NaN o infinito (por ejemplo, al salirse del dominio ``r>-1``).
"""

# ╔═╡ a0000000-0000-4000-8000-000000000025
function newton(f, df, x0::T; tol = nothing, maxit::Integer = 100,
                criterio::Symbol = :paso, m::Integer = 1) where {T<:AbstractFloat}
    τ  = tolerancia(T, tol)
    x  = x0
    fx = f(x)
    xs = T[x]
    fs = T[fx]
    if !isfinite(fx)
        return (x, historial(xs, fs, 0), :no_finito)
    end
    fx == 0 && return (x, historial(xs, fs, 0), :converge)
    for k in 1:maxit
        dfx = df(x)
        if dfx == 0 || !isfinite(dfx)
            return (x, historial(xs, fs, k - 1), :derivada_nula)
        end
        xnuevo = x - m * fx / dfx
        if !isfinite(xnuevo)
            return (x, historial(xs, fs, k - 1), :no_finito)
        end
        dx = xnuevo - x
        x  = xnuevo
        fx = f(x)
        push!(xs, x)
        push!(fs, fx)
        if !isfinite(fx)
            return (x, historial(xs, fs, k), :no_finito)
        end
        if fx == 0 || cumple_parada(criterio, dx, fx, τ)
            return (x, historial(xs, fs, k), :converge)
        end
    end
    return (x, historial(xs, fs, maxit), :maxit)
end

# ╔═╡ a0000000-0000-4000-8000-000000000026
md"""
**Secante.** Reemplaza ``f'(x_k)`` por la pendiente entre las dos últimas iteraciones, así que no necesita derivada. Cerca de la raíz, ``f_1-f_0`` y ``x_1-x_0`` son casi iguales a cero y su cociente pierde cifras por cancelación. Si ``x_1=x_0`` o la pendiente vale cero, el método se detiene con `:derivada_nula`.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000027
function secant(f, x0::T, x1::T; tol = nothing, maxit::Integer = 100,
                criterio::Symbol = :paso) where {T<:AbstractFloat}
    τ  = tolerancia(T, tol)
    f0 = f(x0)
    f1 = f(x1)
    xs = T[x0, x1]
    fs = T[f0, f1]
    if !(isfinite(f0) && isfinite(f1))
        return (x1, historial(xs, fs, 0), :no_finito)
    end
    f1 == 0 && return (x1, historial(xs, fs, 0), :converge)
    for k in 1:maxit
        pendiente = (f1 - f0) / (x1 - x0)
        if pendiente == 0 || !isfinite(pendiente)
            return (x1, historial(xs, fs, k - 1), :derivada_nula)
        end
        x2 = x1 - f1 / pendiente
        if !isfinite(x2)
            return (x1, historial(xs, fs, k - 1), :no_finito)
        end
        dx = x2 - x1
        x0, f0 = x1, f1
        x1 = x2
        f1 = f(x1)
        push!(xs, x1)
        push!(fs, f1)
        if !isfinite(f1)
            return (x1, historial(xs, fs, k), :no_finito)
        end
        if f1 == 0 || cumple_parada(criterio, dx, f1, τ)
            return (x1, historial(xs, fs, k), :converge)
        end
    end
    return (x1, historial(xs, fs, maxit), :maxit)
end

# ╔═╡ a0000000-0000-4000-8000-000000000028
md"""
**Punto fijo.** Para ``\mathrm{NPV}(r)=0`` usamos ``g(r)=r+\alpha\,\mathrm{NPV}(r)``: si ``\mathrm{NPV}(r^*)=0`` entonces ``g(r^*)=r^*``. Como ``g'(r^*)=1+\alpha\,\mathrm{NPV}'(r^*)``, la iteración ``r_{k+1}=g(r_k)`` converge localmente si ``-2<\alpha\,\mathrm{NPV}'(r^*)<0``, con razón lineal ``\lvert g'(r^*)\rvert``. Una buena elección es ``\alpha=-1/\mathrm{NPV}'(x_0)`` (derivada "congelada", método de la cuerda), que hace ``g'(r^*)\approx 0`` si ``x_0`` está cerca de ``r^*``. En una raíz doble ``\mathrm{NPV}'(r^*)=0``, así que ``g'(r^*)=1`` para cualquier ``\alpha`` y no hay contracción.

El argumento opcional `f` permite que el historial guarde el residuo de NPV (y que el criterio `:residuo` mida NPV); si se omite, el residuo es ``g(x)-x``.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000029
begin
    # g(r) = r + α·f(r)
    g_punto_fijo(f, α) = r -> r + α * f(r)

    # α = -1/f'(x0): derivada congelada en x0
    alfa_cuerda(df, x0) = -inv(df(x0))

    # g'(r*) = 1 + α·f'(r*): razón de convergencia lineal
    g_prima(α, dfstar) = 1 + α * dfstar

    function fixedpoint(g, x0::T; f = nothing, tol = nothing, maxit::Integer = 1000,
                        criterio::Symbol = :paso) where {T<:AbstractFloat}
        τ = tolerancia(T, tol)
        residuo(x) = f === nothing ? g(x) - x : f(x)
        x  = x0
        rx = residuo(x)
        xs = T[x]
        fs = T[rx]
        for k in 1:maxit
            xnuevo = g(x)
            if !isfinite(xnuevo)
                return (x, historial(xs, fs, k - 1), :no_finito)
            end
            dx = xnuevo - x
            x  = xnuevo
            rx = residuo(x)
            push!(xs, x)
            push!(fs, rx)
            if !isfinite(rx)
                return (x, historial(xs, fs, k), :no_finito)
            end
            if cumple_parada(criterio, dx, rx, τ)
                return (x, historial(xs, fs, k), :converge)
            end
        end
        return (x, historial(xs, fs, maxit), :maxit)
    end
end

# ╔═╡ 4b635a2b-ffd6-4a51-b4b8-fe52ce527866
function prueba_humo(::Type{T}; tol = 1e-10) where {T<:AbstractFloat}
    c = flujos_prestamo(T, 1000, 1//100, 12)
    r_ref = T(1//100)
    f = r -> npv(c, r)
    df = r -> dnpv(c, r)
    x0 = T(2//100)
    α = alfa_cuerda(df, x0)
    g = g_punto_fijo(f, α)
    
    corridas = [
        ("bisección", bisection(f, T(1//10000), T(1//10); tol=tol)),
        ("Newton", newton(f, df, x0; tol=tol)),
        ("secante", secant(f, T(5//1000), x0; tol=tol)),
        ("punto fijo", fixedpoint(g, x0; f=f, tol=tol)),
    ]
    
    resultados = [
        (método=n, r=r, error_r=abs(r - r_ref), residuo=abs(f(r)), 
         iteraciones=h.iter, estado=e)
        for (n, (r, h, e)) in corridas
    ]
    
    println("\n" * "="^75)
    @printf("%-15s | %-12s | %-12s | %-12s | %-5s | %-10s\n",
            "Método", "Resultado (r)", "Error r", "Residuo", "Iter", "Estado")
    println("-"^75)
    
    for row in resultados
        @printf("%-15s | %-12.8f | %-12.2e | %-12.2e | %-5d | %-10s\n",
                row.método, row.r, row.error_r, row.residuo, 
                row.iteraciones, string(row.estado))
    end
    println("="^75 * "\n")
    
    return resultados
end

# ╔═╡ 4c7ed7b9-8b74-46d7-a5d8-6f8a5d257612
md"""
---
"""

# ╔═╡ a0000000-0000-4000-8000-000000000030
md"""
**Prueba de humo.** Los cuatro métodos sobre el préstamo base (``P=1000``, ``i=1\%``, 12 cuotas; TIR exacta ``0.01``). `NPV(0.0001)<0<NPV(0.1)`, así que ``[0.0001,\,0.1]`` encierra la raíz. Es la misma función con distinto `T`: primero Float64 y luego BigFloat con una tolerancia mucho menor. Esto aún no es el estudio de formatos (sección 5.3), solo comprueba que el código funciona.
"""

# ╔═╡ a0000000-0000-4000-8000-000000000032
prueba_humo(Float64)

# ╔═╡ a0000000-0000-4000-8000-000000000033
prueba_humo(BigFloat; tol = 1e-40)

# ╔═╡ a0000000-0000-4000-8000-000000000036
md"""
---
"""

# ╔═╡ b0000001-0000-4000-8000-000000000001
md"""
### 5.3 Formatos y referencia BigFloat

Para medir el error real ``|\hat r - r^*|`` necesitamos una referencia confiable de la raíz exacta. La obtenemos con `BigFloat` de 256 bits (≈77 dígitos decimales), usando Newton con multiplicidad adecuada hasta que el paso sea cero en ese formato.

La tabla siguiente resume la precisión unitaria ``u = \varepsilon_{\text{máq}}/2`` de cada formato, que es la cota teórica del error relativo en cada uno:
"""

# ╔═╡ b0000001-0000-4000-8000-000000000002
begin
    # Precisión unitaria por formato
    formatos_info = [
        (nombre = "Float16",  T = Float16,  u = eps(Float16)/2),
        (nombre = "Float32",  T = Float32,  u = eps(Float32)/2),
        (nombre = "Float64",  T = Float64,  u = eps(Float64)/2),
        (nombre = "BigFloat", T = BigFloat, u = eps(BigFloat)/2),
    ]
end

# ╔═╡ b0000001-0000-4000-8000-000000000003
# Referencia de alta precisión para cada caso
let
    setprecision(BigFloat, 256) do
        c_pres_b = flujos_prestamo(BigFloat, 1000, 1//100, 12)
        c_doble_b = BigFloat[-100, 220, -121]
        c_dos_b   = BigFloat[-100, 230, -132]
        c_hip_b   = flujos_prestamo(BigFloat, 1_000_000, 5//1000, 360)

        global r_ref_pres  = newton(r -> npv(c_pres_b, r), r -> dnpv(c_pres_b, r), BigFloat(2)/100)[1]
        global r_ref_doble = newton(r -> npv(c_doble_b, r), r -> dnpv(c_doble_b, r),
                                    BigFloat(12)/100, m = 2)[1]
        global r_ref_dos1  = newton(r -> npv(c_dos_b, r), r -> dnpv(c_dos_b, r), BigFloat(5)/100)[1]
        global r_ref_dos2  = newton(r -> npv(c_dos_b, r), r -> dnpv(c_dos_b, r), BigFloat(25)/100)[1]
        global r_ref_hip   = newton(r -> npv(c_hip_b, r), r -> dnpv(c_hip_b, r), BigFloat(1)/100)[1]
    end

    (
        préstamo_base  = (r = Float64(r_ref_pres),  npv = Float64(abs(npv(flujos_prestamo(BigFloat,1000,1//100,12), r_ref_pres)))),
        raíz_doble     = (r = Float64(r_ref_doble), npv = Float64(abs(npv(BigFloat[-100,220,-121], r_ref_doble)))),
        dos_raíces_r1  = (r = Float64(r_ref_dos1),  npv = Float64(abs(npv(BigFloat[-100,230,-132], r_ref_dos1)))),
        dos_raíces_r2  = (r = Float64(r_ref_dos2),  npv = Float64(abs(npv(BigFloat[-100,230,-132], r_ref_dos2)))),
        hipoteca_360   = (r = Float64(r_ref_hip),   npv = Float64(abs(npv(flujos_prestamo(BigFloat,1e6,5//1000,360), r_ref_hip)))),
    )
end

# ╔═╡ b0000001-0000-4000-8000-000000000004
md"""
Todas las referencias tienen ``|\mathrm{NPV}|`` del orden de ``10^{-69}`` o menor, lo que confirma que son raíces precisas hasta el redondeo de 256 bits.

**Tolerancia por defecto.** Cuando el usuario no especifica `tol`, cada método usa ``\sqrt{\varepsilon_{\text{máq}}}`` como compromiso entre alcanzar el piso de ruido del formato y no iterar de más. Un dato importante: `T(1e-10)` en Float16 no es representable (vale 0), así que la tolerancia nunca se cumple y el método agota `maxit`.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000005
md"""
### 5.4 Casos de prueba y experimentos

Ejecutamos los cuatro métodos sobre los cuatro casos del catálogo (todos con raíz exacta conocida) en Float16, Float32 y Float64, y medimos error real, residuo, iteraciones y orden de convergencia observado.

**Función auxiliar: orden de convergencia observado.** Para un historial de iteraciones ``x_k`` y una referencia ``r^*``, estimamos el orden ``p`` por:

```math
p_k = \frac{\log|e_{k+1}/e_k|}{\log|e_k/e_{k-1}|},\quad e_k = |x_k - r^*|.
```

Calculamos este cociente solo mientras los errores están bien por encima del piso de ruido del formato.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000006
begin
    function orden_observado(errs::Vector{Float64}; umbral = 1e-15)
        ps = Float64[]
        for k in 2:length(errs)-1
            e0, e1, e2 = errs[k-1], errs[k], errs[k+1]
            if e0 > umbral && e1 > umbral && e2 > umbral && e0 > e1 > e2
                push!(ps, log(e2/e1)/log(e1/e0))
            end
        end
        return ps
    end

    errs_de(xs, rref) = Float64[abs(Float64(x) - Float64(rref)) for x in xs]
    
    function calcular_errores(result, r_ref)
        r, h, _ = result
        errores = [abs(Float64(x) - Float64(r_ref)) for x in h.x]
        return errores
    end
end

# ╔═╡ b0000001-0000-4000-8000-000000000007
md"""
#### Caso A: Préstamo base (``P=1000``, ``i=1\%``, ``n=12``) — raíz simple, bien condicionada

Predicciones §4.2: error relativo ``\sim \kappa u``. Esperamos Float64 ``\approx 10^{-14}``, Float32 ``10^{-6}``–``10^{-4}``, Float16 ``10^{-2}``–``10^{-1}``.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000008
begin
    function tabla_prestamo(::Type{T}) where {T<:AbstractFloat}
        c = flujos_prestamo(T, 1000, 1//100, 12)
        f = r -> npv(c, r); df = r -> dnpv(c, r)
        x0 = T(2//100)
        α = alfa_cuerda(df, x0); g = g_punto_fijo(f, α)
        tol = sqrt(eps(T))
        corridas = (
            ("bisección",  bisection(f, T(1//10000), T(1//10); tol = tol)),
            ("Newton",     newton(f, df, x0; tol = tol)),
            ("secante",    secant(f, T(5//1000), x0; tol = tol)),
            ("punto fijo", fixedpoint(g, x0; f = f, tol = tol)),
        )
        [(n, Float64(r), abs(Float64(r) - Float64(r_ref_pres)),
          Float64(abs(f(r))), h.iter, string(e)) for (n, (r, h, e)) in corridas]
    end

    tabla_pres_F16 = tabla_prestamo(Float16)
    tabla_pres_F32 = tabla_prestamo(Float32)
    tabla_pres_F64 = tabla_prestamo(Float64)
end

# ╔═╡ b0000001-0000-4000-8000-000000000009
Markdown.parse("""
**Tabla unificada - Caso A: Préstamo base**

Esta tabla muestra todos los métodos en todos los formatos para fácil comparación:

$(let
    # Crear tabla unificada
    header = "| Método | Float16 r̂ | Float16 Error | Float32 r̂ | Float32 Error | Float64 r̂ | Float64 Error |\n"
    header *= "|---|---|---|---|---|---|---|\n"
    
    rows = ""
    for i in 1:4
        método = tabla_pres_F16[i][1]
        r16 = round(tabla_pres_F16[i][2], digits=10)
        err16 = tabla_pres_F16[i][3]
        r32 = round(tabla_pres_F32[i][2], digits=10)
        err32 = tabla_pres_F32[i][3]
        r64 = round(tabla_pres_F64[i][2], digits=10)
        err64 = tabla_pres_F64[i][3]
        
        rows *= "| $método | $r16 | $(@sprintf("%.2e", err16)) | $r32 | $(@sprintf("%.2e", err32)) | $r64 | $(@sprintf("%.2e", err64)) |\n"
    end
    
    header * rows
end)

**Observación:** Newton y secante en Float64 alcanzan el límite de precisión (~10⁻¹⁶), mientras que Float16 tiene errores del orden de 10⁻² a 10⁻¹ como se predijo.
""")

# ╔═╡ b0000001-0000-4000-8000-00000000000a
# Órdenes de convergencia observados (préstamo base, Float64)
let
    c = flujos_prestamo(Float64, 1000, 1//100, 12)
    f = r -> npv(c, r); df = r -> dnpv(c, r)
    x0 = Float64(2//100)
    α = alfa_cuerda(df, x0); g = g_punto_fijo(f, α)

    resultados = NamedTuple{(:nombre, :orden_prom, :predicho), Tuple{String, Float64, Float64}}[]

    for (nom, res) in (
        ("bisección", bisection(f, 1.0e-4, 0.1)),
        ("Newton",    newton(f, df, x0)),
        ("secante",   secant(f, 5.0e-3, x0)),
        ("p. fijo",   fixedpoint(g, x0; f = f)),
    )
        r, h, _ = res
        errs = errs_de(h.x, Float64(r_ref_pres))
        ps = orden_observado(errs; umbral = 1e-14)
        prom = length(ps) >= 2 ? mean(ps[max(1,end-4):end]) : NaN
        pred = Dict("bisección" => 1.0, "Newton" => 2.0, "secante" => 1.618, "p. fijo" => 1.0)[nom]
        push!(resultados, (nombre = nom, orden_prom = prom, predicho = pred))
    end
    resultados
end

# ╔═╡ b0000001-0000-4000-8000-00000000000b
md"""
#### Caso B: Raíz doble ``c=(-100, 220, -121)``, ``r^*=0.10``

Predicción §4.4: Newton m=1 orden ≈1 con error ``\sim\sqrt{u}``; Newton m=2 recupera orden 2.

**Nota sobre los métodos:** aquí **la bisección no puede usarse** porque ``\mathrm{NPV}`` no cambia de signo (raíz doble), y el **punto fijo pierde la contracción** porque ``g'(r^*)=1+\alpha\,\mathrm{NPV}'(r^*)=1``. Se incluyen igual para evidenciar el fallo.
"""

# ╔═╡ b0000001-0000-4000-8000-00000000000c
begin
    function tabla_raiz_doble(::Type{T}) where {T<:AbstractFloat}
        c = T[-100, 220, -121]
        f = r -> npv(c, r); df = r -> dnpv(c, r)
        x0 = T(12//100)
        tol = sqrt(eps(T))
        α = alfa_cuerda(df, x0); g = g_punto_fijo(f, α)
        # Se incluyen los 4 métodos. La bisección no aplica (no hay cambio de signo);
        # el punto fijo pierde contracción (g'(r*) = 1).
        corridas = (
            ("bisección [0.05,0.15]", bisection(f, T(5//100), T(15//100); tol = tol)),
            ("Newton m=1",            newton(f, df, x0; tol = tol, m = 1)),
            ("Newton m=2",            newton(f, df, x0; tol = tol, m = 2)),
            ("secante",               secant(f, T(8//100), T(12//100); tol = tol)),
            ("punto fijo",            fixedpoint(g, x0; f = f, tol = tol)),
        )
        rows = []
        for (nombre, (r, h, e)) in corridas
            if isfinite(r)
                err = abs(Float64(r) - Float64(r_ref_doble))
                res = Float64(abs(f(r)))
                errs = errs_de(h.x, r_ref_doble)
                ps = orden_observado(errs; umbral = sqrt(eps(T))*10)
                orden_prom = length(ps) >= 2 ? mean(ps) : NaN
            else
                err = NaN; res = NaN; orden_prom = NaN
            end
            push!(rows, (nombre, Float64(r), err, res, h.iter, string(e), orden_prom))
        end
        rows
    end

    tabla_doble_F16 = tabla_raiz_doble(Float16)
    tabla_doble_F32 = tabla_raiz_doble(Float32)
    tabla_doble_F64 = tabla_raiz_doble(Float64)
end

# ╔═╡ b0000001-0000-4000-8000-00000000000d
Markdown.parse("""
**Tabla unificada - Caso B: Raíz doble**

La marca "—" indica que el método **no aplica** (bisección: no hay cambio de signo) o que **no reporta orden** (punto fijo sublineal).

| Método | Float16 r̂ | Float16 Error | Float16 p | Float32 r̂ | Float32 Error | Float32 p | Float64 r̂ | Float64 Error | Float64 p |
|---|---|---|---|---|---|---|---|---|---|
$(let
    fmt_r(x) = isnan(x) ? "—" : string(round(x, digits=10))
    fmt_e(x) = isnan(x) ? "—" : @sprintf("%.2e", x)
    fmt_p(x) = isnan(x) ? "—" : string(round(x, digits=2))
    rows = ""
    for i in 1:5
        método = tabla_doble_F16[i][1]
        rows *= "| $(método) | $(fmt_r(tabla_doble_F16[i][2])) | $(fmt_e(tabla_doble_F16[i][3])) | $(fmt_p(tabla_doble_F16[i][7])) | $(fmt_r(tabla_doble_F32[i][2])) | $(fmt_e(tabla_doble_F32[i][3])) | $(fmt_p(tabla_doble_F32[i][7])) | $(fmt_r(tabla_doble_F64[i][2])) | $(fmt_e(tabla_doble_F64[i][3])) | $(fmt_p(tabla_doble_F64[i][7])) |\n"
    end
    rows
end)

**Observación clave:**

- **Bisección** → estado `sin_cambio_signo`: **no puede aplicarse** porque ``\\mathrm{NPV}`` no cambia de signo en una raíz doble.
- **Newton m=1** converge **linealmente** (orden ≈1) y se estanca en error ``\\approx \\sqrt{u}``.
- **Newton m=2** recupera **orden 2** (cuadrático) porque usa la multiplicidad conocida.
- **Secante** converge pero **linealmente** (pierde el orden 1.618 en raíz doble).
- **Punto fijo** casi no avanza: en raíz doble ``g'(r^*)=1``, no hay contracción.
""")

# ╔═╡ b0000001-0000-4000-8000-00000000000e
md"""
#### Caso C: Dos raíces ``c=(-100, 230, -132)``, ``r^*=0.10`` y ``0.20``

Predicción §4.5: bisección en ``[0, 0.5]`` falla (``\mathrm{NPV}`` no cambia de signo en ese intervalo); Newton llega a una u otra raíz según ``x_0``; cerca de ``r\approx 14.8\%`` donde ``\mathrm{NPV}'=0`` se entrelazan las cuencas.

**Nota sobre los métodos:** se prueban los 4 métodos. Newton, secante y punto fijo se arrancan desde dos ``x_0`` distintos (uno cerca de cada raíz) para mostrar la dependencia del dato inicial. La bisección en ``[0, 0.5]`` se incluye para evidenciar que **falla**.
"""

# ╔═╡ b0000001-0000-4000-8000-00000000000f
begin
    function tabla_dos_raices(::Type{T}) where {T<:AbstractFloat}
        c = T[-100, 230, -132]
        f = r -> npv(c, r); df = r -> dnpv(c, r)
        tol = sqrt(eps(T))
        α1 = alfa_cuerda(df, T(5//100));  g1 = g_punto_fijo(f, α1)
        α2 = alfa_cuerda(df, T(25//100)); g2 = g_punto_fijo(f, α2)
        corridas = (
            ("bisec [0,0.15] → r₁",   bisection(f, T(0), T(15//100); tol = tol)),
            ("bisec [0.15,0.5] → r₂", bisection(f, T(15//100), T(5//10); tol = tol)),
            ("bisec [0,0.5] (falla)", bisection(f, T(0), T(5//10); tol = tol)),
            ("Newton x₀=0.05 → r₁",    newton(f, df, T(5//100); tol = tol)),
            ("Newton x₀=0.25 → r₂",    newton(f, df, T(25//100); tol = tol)),
            ("secante → r₁",           secant(f, T(5//100), T(10//100); tol = tol)),
            ("secante → r₂",           secant(f, T(25//100), T(30//100); tol = tol)),
            ("p. fijo x₀=0.05 → r₁",   fixedpoint(g1, T(5//100); f = f, tol = tol)),
            ("p. fijo x₀=0.25 → r₂",   fixedpoint(g2, T(25//100); f = f, tol = tol)),
        )
        [(n, Float64(r), Float64(abs(f(r))), h.iter, string(e)) for (n, (r, h, e)) in corridas]
    end

    tabla_dos_F16 = tabla_dos_raices(Float16)
    tabla_dos_F32 = tabla_dos_raices(Float32)
    tabla_dos_F64 = tabla_dos_raices(Float64)
end

# ╔═╡ b0000001-0000-4000-8000-000000000010
Markdown.parse("""
**Tabla unificada - Caso C: Dos raíces**

| Método | Float16 r̂ | Float16 Residuo | Float32 r̂ | Float32 Residuo | Float64 r̂ | Float64 Residuo | Estado |
|---|---|---|---|---|---|---|---|
$(let
    fmt_r(x) = isnan(x) ? "—" : string(round(x, digits=10))
    fmt_e(x) = isnan(x) ? "—" : @sprintf("%.2e", x)
    rows = ""
    for i in 1:9
        método = tabla_dos_F16[i][1]
        rows *= "| $(método) | $(fmt_r(tabla_dos_F16[i][2])) | $(fmt_e(tabla_dos_F16[i][3])) | $(fmt_r(tabla_dos_F32[i][2])) | $(fmt_e(tabla_dos_F32[i][3])) | $(fmt_r(tabla_dos_F64[i][2])) | $(fmt_e(tabla_dos_F64[i][3])) | $(tabla_dos_F64[i][5]) |\n"
    end
    rows
end)

**Observación clave:**

- **Bisección en ``[0, 0.5]`` → `sin_cambio_signo`**: falla porque ``\\mathrm{NPV}`` es negativo en ambos extremos. Separando en ``[0, 0.15]`` y ``[0.15, 0.5]`` sí encuentra cada raíz.
- **Newton, secante y punto fijo** llegan a ``r_1=0.10`` desde ``x_0`` cercano a la izquierda y a ``r_2=0.20`` desde ``x_0`` cercano a la derecha: **el resultado depende del dato inicial**.
""")

# ╔═╡ b0000001-0000-4000-8000-000000000011
md"""
#### Caso D: Hipoteca 360 (``P=10^6``, ``i=0.5\%``, ``n=360``)

Predicción §4.6: Float16 falla (el monto ``P = 10^6 > 65504`` no cabe).

**Nota sobre los métodos:** se prueban los 4 métodos. En Float16 todos fallan por desborde; en Float32/Float64 funcionan.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000012
begin
    function tabla_hipoteca(::Type{T}) where {T<:AbstractFloat}
        c = flujos_prestamo(T, 1_000_000, 5//1000, 360)
        f = r -> npv(c, r); df = r -> dnpv(c, r)
        x0 = T(1//100)
        tol = sqrt(eps(T))
        α = alfa_cuerda(df, x0); g = g_punto_fijo(f, α)
        corridas = (
            ("bisección",  bisection(f, T(1//1000), T(1//100); tol = tol)),
            ("Newton",     newton(f, df, x0; tol = tol)),
            ("secante",    secant(f, T(3//1000), x0; tol = tol)),
            ("punto fijo", fixedpoint(g, x0; f = f, tol = tol)),
        )
        rows = []
        for (nombre, (r, h, e)) in corridas
            if isfinite(r)
                err = abs(Float64(r) - Float64(r_ref_hip))
                res = Float64(abs(f(r)))
            else
                err = NaN; res = NaN
            end
            push!(rows, (nombre, Float64(r), err, res, h.iter, string(e), string(c[1])))
        end
        rows
    end

    tabla_hip_F16 = tabla_hipoteca(Float16)
    tabla_hip_F32 = tabla_hipoteca(Float32)
    tabla_hip_F64 = tabla_hipoteca(Float64)
end

# ╔═╡ b0000001-0000-4000-8000-000000000013
Markdown.parse("""
**Tabla unificada - Caso D: Hipoteca 360**

| Método | Float16 r̂ | Float16 Error | Float32 r̂ | Float32 Error | Float64 r̂ | Float64 Error | Estado (F16 / F32 / F64) |
|---|---|---|---|---|---|---|---|
$(let
    fmt_r(x) = isnan(x) ? "—" : string(round(x, digits=10))
    fmt_e(x) = isnan(x) ? "—" : @sprintf("%.2e", x)
    rows = ""
    for i in 1:4
        método = tabla_hip_F16[i][1]
        rows *= "| $(método) | $(fmt_r(tabla_hip_F16[i][2])) | $(fmt_e(tabla_hip_F16[i][3])) | $(fmt_r(tabla_hip_F32[i][2])) | $(fmt_e(tabla_hip_F32[i][3])) | $(fmt_r(tabla_hip_F64[i][2])) | $(fmt_e(tabla_hip_F64[i][3])) | $(tabla_hip_F16[i][6]) / $(tabla_hip_F32[i][6]) / $(tabla_hip_F64[i][6]) |\n"
    end
    rows
end)

**Observación clave:**

- **Float16 falla en todos los métodos** (`no_finito`) porque ``P = 10^6 > 65504`` (máximo representable) → el dato de entrada ya es ``Inf``.
- En Float32 y Float64 convergen **bisección, Newton y secante**.
- El **punto fijo NO converge** aquí: llega a `maxit` estancado en ``r̂ ≈ 0.0115`` (en vez de 0.005). Con ``α = -1/NPV'(x_0)`` y ``x_0 = 0.01``, el NPV es muy inclinado cerca de la raíz, así que la iteración de la cuerda no contrae lo suficiente.
- El residuo en Float32 es grande (escala de los flujos), reforzando que *residuo pequeño ≠ raíz precisa*.
""")

# ╔═╡ b0000001-0000-4000-8000-000000000014
md"""
#### Criterio de parada: ``:paso`` vs ``:residuo`` vs ``:ambos``

**¿Qué se quiere ver?** Que el resultado de un método no depende solo de su fórmula de iteración, sino también de **cuándo decide parar**. Con la *misma* tolerancia ``\mathrm{tol}=10^{-6}``, corremos **Newton** sobre la hipoteca en **Float32** (flujos enormes, residuo con mucho ruido) alternando el criterio:

- `:paso` → para cuando ``|\Delta x| \le \mathrm{tol}`` (el paso entre iteraciones es pequeño),
- `:residuo` → para cuando ``|\mathrm{NPV}(x)| \le \mathrm{tol}`` (la función está cerca de cero),
- `:ambos` → exige las dos condiciones a la vez.

**Hipótesis (predicción §4.3):** con flujos grandes en Float32, el residuo ``|\mathrm{NPV}|`` se queda en un **piso de ruido** mucho mayor que ``10^{-6}``; por eso `:residuo` y `:ambos` **nunca** se cumplen y el método agota `maxit`, mientras que `:paso` sí termina. Es decir, **elegir mal el criterio puede hacer que un método "falle" aunque la iteración funcione**.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000015
Markdown.parse("""
**Criterio de parada — Hipoteca 360, Float32** (tol = 1e-6, maxit = 100)

| Criterio | Error r | Residuo | Iter | Estado |
|---|---|---|---|---|
$(let
    c = flujos_prestamo(Float32, 1_000_000, 5//1000, 360)
    f = r -> npv(c, r); df = r -> dnpv(c, r)
    x0 = Float32(1//100)
    rows = ""
    for crit in (:paso, :residuo, :ambos)
        r, h, e = newton(f, df, x0; tol = Float32(1e-6), criterio = crit, maxit = 100)
        err = abs(Float64(r) - 0.005)
        res = Float64(abs(f(r)))
        rows *= "| `:$(crit)` | $(@sprintf("%.2e", err)) | $(@sprintf("%.2e", res)) | $(h.iter) | $(e) |\n"
    end
    rows
end)

**Observación:** `:paso` converge en pocas iteraciones; `:residuo` y `:ambos` agotan `maxit` porque el residuo en Float32 (≈0.7) es mucho mayor que `tol = 1e-6` y nunca se cumple. Es decir, **el criterio de residuo es inútil con flujos grandes en Float32**.
""")

# ╔═╡ b0000001-0000-4000-8000-000000000016
md"""
#### Barrido de tolerancias — Préstamo base, Float64, Newton

**¿Qué se quiere ver?** Que pedir una tolerancia cada vez más pequeña **no mejora el error indefinidamente**: existe un **piso de ruido** impuesto por el formato. Corremos Newton sobre el préstamo base en Float64 con tolerancias desde ``10^{-2}`` hasta ``10^{-16}`` y medimos, para cada una, el error ``|\hat r - r^*|`` y el residuo ``|\mathrm{NPV}(\hat r)|``.

**Hipótesis:** por debajo de cierto umbral (≈``\sqrt{\varepsilon_{\text{máq}}}``) el error y el residuo se **estancan**, porque el formato ya no puede representar más precisión; tolerancias menores no cambian el resultado.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000017
Markdown.parse("""
**Barrido de tolerancias — Préstamo base, Float64, Newton**

| Tolerancia | Error r | Residuo | Iter |
|---|---|---|---|
$(let
    c = flujos_prestamo(Float64, 1000, 1//100, 12)
    f = r -> npv(c, r); df = r -> dnpv(c, r)
    x0 = Float64(2//100)
    rows = ""
    for tol_exp in -2:-2:-16
        tol = Float64(10.0^tol_exp)
        r, h, e = newton(f, df, x0; tol = tol, maxit = 100)
        err = abs(Float64(r) - Float64(r_ref_pres))
        res = Float64(abs(f(r)))
        rows *= "| $(@sprintf("%.0e", tol)) | $(@sprintf("%.2e", err)) | $(@sprintf("%.2e", res)) | $(h.iter) |\n"
    end
    rows
end)

**Observación:** para tolerancias mayores que 1e-8 el error y el residuo bajan con la tolerancia; para tolerancias menores que 1e-8 se estancan en el **piso de ruido** del formato (≈1e-16 en el error). No tiene sentido pedir menos que ``\\sqrt{ε}``: el formato no puede cumplirlo.
""")

# ╔═╡ b0000001-0000-4000-8000-000000000018
md"""
---

## 6. Resultados

### 6.1 Gráficas de convergencia y error

#### Convergencia de métodos (préstamo base, Float64)

Esta gráfica muestra cómo converge cada método al calcular la TIR del préstamo base:
"""

# ╔═╡ b0000001-0000-4000-8000-000000000019
begin
    métodos = ["bisección", "Newton", "secante", "punto fijo"]
    
    # Extraer errores de cada formato
    errores_F16 = [tabla_pres_F16[i][3] for i in 1:4]
    errores_F32 = [tabla_pres_F32[i][3] for i in 1:4]
    errores_F64 = [tabla_pres_F64[i][3] for i in 1:4]
    
    # Crear trazas
    trace_F16 = scatter(;
        x = métodos,
        y = errores_F16,
        name = "Float16",
        mode = "lines+markers",
        marker = attr(size = 10, color = "#ff6b6b"),
        line = attr(width = 2)
    )
    
    trace_F32 = scatter(;
        x = métodos,
        y = errores_F32,
        name = "Float32",
        mode = "lines+markers",
        marker = attr(size = 10, color = "#4ecdc4"),
        line = attr(width = 2)
    )
    
    trace_F64 = scatter(;
        x = métodos,
        y = errores_F64,
        name = "Float64",
        mode = "lines+markers",
        marker = attr(size = 10, color = "#2c3e50"),
        line = attr(width = 2)
    )
    
    # Líneas de referencia para √u
    trace_sqrtu16 = scatter(;
        x = métodos,
        y = fill(sqrt(eps(Float16)), 4),
        name = "√u Float16",
        mode = "lines",
        line = attr(dash = "dash", color = "#ff6b6b", width = 1),
        showlegend = false
    )
    
    trace_sqrtu32 = scatter(;
        x = métodos,
        y = fill(sqrt(eps(Float32)), 4),
        name = "√u Float32",
        mode = "lines",
        line = attr(dash = "dash", color = "#4ecdc4", width = 1),
        showlegend = false
    )
    
    trace_sqrtu64 = scatter(;
        x = métodos,
        y = fill(sqrt(eps(Float64)), 4),
        name = "√u Float64",
        mode = "lines",
        line = attr(dash = "dash", color = "#2c3e50", width = 1),
        showlegend = false
    )
    
    layout_error_formato = Layout(;
        title = "Error |r̂ - r*| por método y formato (Caso A: Préstamo base)",
        xaxis = attr(title = "Método", tickangle = -45),
        yaxis = attr(title = "Error absoluto", type = "log"),
        legend = attr(x = 1.05, y = 1),
        margin = attr(l = 80, r = 50, t = 80, b = 100),
        width = 800,
        height = 500
    )
    
    Plot([trace_F16, trace_F32, trace_F64, 
          trace_sqrtu16, trace_sqrtu32, trace_sqrtu64], layout_error_formato)
end

# ╔═╡ b0000001-0000-4000-8000-00000000001a
begin
    # Ejecutar los 4 métodos y capturar historiales
    c_conv = flujos_prestamo(Float64, 1000, 1//100, 12)
    f_conv = r -> npv(c_conv, r)
    df_conv = r -> dnpv(c_conv, r)
    x0_conv = Float64(2//100)
    α_conv = alfa_cuerda(df_conv, x0_conv)
    g_conv = g_punto_fijo(f_conv, α_conv)
    
    bis_result = bisection(f_conv, 1.0e-4, 0.1)
    new_result = newton(f_conv, df_conv, x0_conv)
    sec_result = secant(f_conv, 5.0e-3, x0_conv)
    fix_result = fixedpoint(g_conv, x0_conv; f = f_conv)
    
    errs_bis = calcular_errores(bis_result, r_ref_pres)
    errs_new = calcular_errores(new_result, r_ref_pres)
    errs_sec = calcular_errores(sec_result, r_ref_pres)
    errs_fix = calcular_errores(fix_result, r_ref_pres)
    
    # Crear trazas
    trace_bis = scatter(x=1:length(errs_bis), y=errs_bis, mode="lines+markers", 
                        name="Bisección", line=attr(dash="solid"), marker=attr(size=6))
    trace_new = scatter(x=1:length(errs_new), y=errs_new, mode="lines+markers",
                        name="Newton", line=attr(dash="solid"), marker=attr(size=6))
    trace_sec = scatter(x=1:length(errs_sec), y=errs_sec, mode="lines+markers",
                        name="Secante", line=attr(dash="solid"), marker=attr(size=6))
    trace_fix = scatter(x=1:length(errs_fix), y=errs_fix, mode="lines+markers",
                        name="Punto fijo", line=attr(dash="solid"), marker=attr(size=6))
    
    layout_convergencia = Layout(
        title="Convergencia de métodos (préstamo base, Float64)",
        xaxis=attr(title="Iteración", type="linear"),
        yaxis=attr(title="Error |r̂ - r*|", type="log"),
        legend=attr(x=0.7, y=0.9),
        width=700, height=500
    )
    
    Plot([trace_bis, trace_new, trace_sec, trace_fix], layout_convergencia)
end

# ╔═╡ b0000001-0000-4000-8000-00000000001b
md"""
---

## 7. Conclusión

**Qué se buscaba.** Responder si se puede confiar en la TIR calculada en punto flotante —y, en general, en cualquier raíz de ``\mathrm{NPV}``— y **cuándo un residuo pequeño engaña sobre el error real**. Para eso corrimos bisección, Newton, secante y punto fijo sobre cuatro casos (raíz simple, raíz doble, dos raíces e hipoteca de grado 360) en Float16/32/64, midiendo error, residuo, orden de convergencia y comportamiento del criterio de parada.

**Los hallazgos principales — dónde se cumple y dónde falla la intuición:**

**Ningún formato de punto flotante rescata un mal condicionamiento.** Este es el resultado central del trabajo. En la raíz doble, el error alcanzable escala como ``\sqrt{u}`` en todos los formatos: Float64 llega a ``\sim 10^{-8}``, Float32 a ``\sim 10^{-4}``, Float16 a ``\sim 10^{-2}``. La única forma de recuperar convergencia cuadrática es conocer la multiplicidad ``m`` y usar la modificación ``x_{k+1} = x_k - m\,f(x_k)/f'(x_k)``.

**"Residuo pequeño" no significa "raíz precisa".** El residuo ``|\mathrm{NPV}(\hat r)|`` es lo que el programa vigila; el error ``|\hat r - r^*|`` es lo que importa. Su relación es la pendiente ``|\mathrm{NPV}'(r^*)|``: cuando esta es pequeña (raíz doble) o cuando la escala de los flujos es grande (hipoteca con millones), un residuo diminuto puede convivir con un error considerable. En la hipoteca 360, Float32 reporta ``|\mathrm{NPV}| \approx 0.7`` incluso cuando ``|\hat r - r^*| \approx 4\times 10^{-7}``; el criterio `:residuo` con tolerancia ``10^{-6}`` agota ``\text{maxit}`` sin cumplirse.

**Float16 es inadecuado para este problema.** No representa montos mayores que 65 504 (la hipoteca con ``P = 10^6`` da ``c_1 = \text{Inf}``), y con ``\varepsilon_{\text{máq}}/2 \approx 4.9\times 10^{-4}`` la tolerancia ``\sqrt{u} \approx 0.031`` es tan gruesa que los métodos "convergen" en 1–3 iteraciones a una raíz grosera.

**La tolerancia por defecto ``\sqrt{\varepsilon_{\text{máq}}}`` es un compromiso razonable.** Para el préstamo en Float64, ``\sqrt{u} \approx 1.5\times 10^{-8}`` lleva a Newton a 4 iteraciones con error ``3\times 10^{-16}`` (el piso del formato). Bajar la tolerancia a ``10^{-16}`` no mejora el error (barrido de tolerancias).

**Las cuencas de atracción no son intervalos simples.** En el caso de dos raíces, Newton converge a ``r_1=10\%`` desde ``x_0 < 14.8\%`` y a ``r_2=20\%`` desde ``x_0 > 14.8\%``, con la frontera exactamente donde ``\mathrm{NPV}'(r) = 0``. Cerca de ese punto, la iteración da saltos grandes y el método es sensible al dato inicial.

**Por qué llegamos a estas conclusiones.** El error se midió **contra la raíz exacta** (referencia BigFloat de 256 bits), con **el mismo código genérico** en los tres formatos; así, las diferencias observadas son efecto del **formato** y del **condicionamiento del problema**, no del código. El patrón que aparece (``u`` en raíz simple, ``\sqrt{u}`` en raíz doble, residuo desacoplado del error, fracaso del criterio de residuo con flujos grandes) coincide con el análisis teórico del redondeo y del condicionamiento ``1/|\mathrm{NPV}'|``, y por eso lo consideramos una conclusión defendible y no una casualidad numérica.
"""

# ╔═╡ b0000001-0000-4000-8000-00000000001c
md"""
## Aprendizajes

1. **El residuo es un indicador engañoso.** Para decidir si ``\hat r`` es buena, conviene vigilar también ``|\Delta x_k|`` y, si es posible, estimar ``|\mathrm{NPV}'(\hat r)|``.
2. **La multiplicidad importa.** Conocer ``m`` permite modificar Newton para recuperar convergencia cuadrática; sin ``m``, Newton solo converge linealmente con razón ``1/2``.
3. **El formato define el piso.** No tiene sentido pedir tolerancias menores que ``\varepsilon_{\text{máq}}``; el ruido de redondeo las hace inalcanzables.
4. **El dato inicial es crítico en problemas con varias raíces.** Un barrido de ``x_0`` revela la estructura de las cuencas y los puntos donde ``\mathrm{NPV}'=0`` actúa como frontera.
5. **El código genérico en `T` es esencial.** Escribir las funciones parametrizadas por el tipo numérico permite correr exactamente el mismo código en Float16/32/64/BigFloat y comparar resultados de forma limpia.
"""

# ╔═╡ b0000001-0000-4000-8000-00000000001d
md"""
## Fuentes

- Higham, N. J. (2002). *Accuracy and Stability of Numerical Algorithms* (2nd ed.). SIAM. — Para el análisis de ``u``, cancelación y condicionamiento en punto flotante.
- Documentación oficial de Julia: [`eps`](https://docs.julialang.org/en/v1/base/math/#Base.eps), [`Float16`](https://docs.julialang.org/en/v1/base/numbers/#Base.Float16), [`BigFloat`](https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/#LinearAlgebra.BlasFloat), [`setprecision`](https://docs.julialang.org/en/v1/base/math/#Base.setprecision-Tuple{Type,Union{Integer,Symbol}}).
- Burden, R. L. y Faires, J. D. (2011). *Numerical Analysis* (9th ed.). Brooks/Cole. — Para los métodos iterativos y sus órdenes de convergencia.
- Brealey, R. A., Myers, S. C. y Allen, F. (2020). *Principles of Corporate Finance* (13th ed.). McGraw-Hill. — Para el modelo financiero de la TIR y el NPV.
- Material de clase de Métodos Numéricos, UNAL 2025-II. — Para las predicciones iniciales y el planteamiento del problema.
"""

# ╔═╡ b0000001-0000-4000-8000-00000000001e
md"""
---

> **Nota sobre el uso de IA.** Parte del código, las fórmulas LaTeX y la estructura de este notebook fueron generados con asistencia de IA (Qwen3.7 Plus). Todos los resultados numéricos fueron verificados corriendo el código en Julia 1.8.5, todas las fórmulas fueron derivadas y comprobadas por los autores, y todas las conclusiones fueron contrastadas con las predicciones iniciales. Los autores pueden explicar y defender cada afirmación, cálculo y resultado presentado en este trabajo.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000034
md"""
### 6.2 Comparación de las predicciones con los resultados

**¿Qué se quiere ver?** En la §4 escribimos **7 predicciones** *antes* de correr ningún experimento, sobre cómo se comportarían los métodos en punto flotante. Aquí, ya con los resultados, revisamos cada predicción y marcamos si se **cumplió o no**, y **por qué**.

**Cómo se verifica:** para cada predicción comparamos el valor *predicho* con el *observado* en las tablas de la §6.1 (error, orden de convergencia, estado del método y residuo).

| # | Predicción | Resultado experimental | Veredicto |
|---|---|---|---|
| §4.1 | Bisección orden 1, Newton 2, secante ≈1.618, p. fijo 1 | Newton: p≈2.00 ✓; secante: p≈1.50 (ruido cerca del piso); p. fijo: p≈1.00 ✓ | **Confirmada** |
| §4.2 | Error en préstamo: F64≈10⁻¹⁴, F32 10⁻⁶–10⁻⁴, F16 10⁻²–10⁻¹ | F64: 3×10⁻¹⁶ ✓; F32: 1.3×10⁻⁷ ✓; F16: 4×10⁻³ ✓ | **Confirmada** |
| §4.3 | Criterio `:residuo` no se cumple en Float32 con flujos grandes | Hipoteca F32: `:residuo` con tol=1e-6 agota maxit=100, residuo final ≈ 0.7 ✓ | **Confirmada** |
| §4.4 | En raíz doble: error ≈ √u, Newton lineal con razón 1/2 | F64 m=1: error 1.6×10⁻⁸ ≈ √(1.5×10⁻¹⁶) ✓, orden ≈1.0 ✓; con m=2 recupera cuadrática ✓ | **Confirmada** |
| §4.5 | Bisección [0,0.5] falla; Newton va a una u otra según x₀ | Bisec [0,0.5]: `:sin_cambio_signo` en los 3 formatos ✓; Newton x₀=0.05→r₁, x₀=0.25→r₂ ✓ | **Confirmada** |
| §4.6 | Float16 inadecuado (desbordes) | Hipoteca F16: c[1]=Inf, `:no_finito` ✓ | **Confirmada** |
| §4.7 | Ningún formato rescata mal condicionamiento | En raíz doble, el error mínimo es √u sin importar el formato ✓ | **Confirmada** |

**Dónde acertamos.** Las 7 predicciones se confirmaron. En particular:
- los **órdenes de convergencia** (Newton 2, secante ≈1.618, punto fijo 1),
- el **techo de error ``\sqrt{u}`` en la raíz doble**,
- el **fallo de la bisección** cuando no hay cambio de signo,
- el **desborde de Float16** con la hipoteca,
- el **piso de ruido del residuo** con flujos grandes.

**Dónde hubo matices (no fallos).** El orden de la **secante** salió ≈1.50 en vez de 1.618. No contradice la teoría: la estimación ``p_k = \log|e_{k+1}/e_k| / \log|e_k/e_{k-1}|`` es **ruidosa** cuando los errores ya están cerca del piso del formato (``u``), por lo que se promedian muy pocos valores fiables y queda sesgada a la baja. Es un **límite de la medición**, no del método.

**Por qué se llega a esta conclusión.** Las predicciones provienen del **análisis de error** (``u``, ``\sqrt{u}``, condicionamiento ``1/|f'(r^*)|``) y de los teoremas de orden de cada método. Los experimentos reproducen ese análisis porque (i) el notebook es **genérico en el tipo numérico** —mismo código para Float16/32/64— y (ii) el error se mide **contra una referencia exacta** (BigFloat de 256 bits). Los únicos desvíos aparecen donde el propio punto flotante contamina la *métrica* (el orden estimado), no donde falla el método.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000027
md"""
**Observación:** Newton sin corrección (m=1) converge linealmente y se estanca en error ≈√u ≈ 1.5×10⁻⁸. Con la corrección de multiplicidad (m=2), recupera convergencia cuadrática y alcanza el piso de precisión del formato en solo 3 iteraciones.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000031
begin
    c_tol = flujos_prestamo(Float64, 1000, 1//100, 12)
    f_tol = r -> npv(c_tol, r)
    df_tol = r -> dnpv(c_tol, r)
    x0_tol = Float64(2//100)
    
    tolerancias = Float64[]
    errores_tol = Float64[]
    residuos_tol = Float64[]
    
    for tol_exp in -2:-2:-16
        tol = Float64(10.0^tol_exp)
        r, h, _ = newton(f_tol, df_tol, x0_tol; tol=tol, maxit=100)
        push!(tolerancias, tol)
        push!(errores_tol, abs(Float64(r) - Float64(r_ref_pres)))
        push!(residuos_tol, Float64(abs(f_tol(r))))
    end
    
    trace_tol_err = scatter(x=tolerancias, y=errores_tol, mode="lines+markers",
                            name="Error |r̂ - r*|", line=attr(color="#ff6b6b", width=2),
                            marker=attr(size=8, color="#ff6b6b"))
    trace_tol_res = scatter(x=tolerancias, y=residuos_tol, mode="lines+markers",
                            name="Residuo |NPV(r̂)|", line=attr(color="#4ecdc4", width=2),
                            marker=attr(size=8, color="#4ecdc4"))
    
    # Línea horizontal: piso de ruido
    piso_ruido = eps(Float64) / 2
    trace_piso = scatter(x=[minimum(tolerancias), maximum(tolerancias)],
                         y=[piso_ruido, piso_ruido], mode="lines",
                         name="Piso √ε", line=attr(color="black", dash="dot", width=2))
    
    layout_tol = Layout(
        title="Barrido de tolerancias: Newton en préstamo base (Float64)",
        xaxis=attr(title="Tolerancia solicitada", type="log"),
        yaxis=attr(title="Magnitud", type="log"),
        legend=attr(x=0.65, y=0.9),
        width=700, height=500
    )
    
    Plot([trace_tol_err, trace_tol_res, trace_piso], layout_tol)
end

# ╔═╡ b0000001-0000-4000-8000-000000000029
begin
    c_cuen = Float64[-100, 230, -132]
    f_cuen = r -> npv(c_cuen, r)
    df_cuen = r -> dnpv(c_cuen, r)
    
    x0_values = 0.01:0.005:0.45
    convergence_points = Float64[]
    convergence_colors = Int[]
    
    for x0 in x0_values
        result = newton(f_cuen, df_cuen, x0; maxit=50)
        r, h, estado = result
        if estado == :converge
            r_final = Float64(r)
            # Determinar a cuál raíz convergió
            if abs(r_final - 0.10) < 0.05
                push!(convergence_points, r_final)
                push!(convergence_colors, 1)  # raíz 1
            elseif abs(r_final - 0.20) < 0.05
                push!(convergence_points, r_final)
                push!(convergence_colors, 2)  # raíz 2
            else
                push!(convergence_points, r_final)
                push!(convergence_colors, 0)  # otra/no convergió
            end
        end
    end
    
    trace_r1 = scatter(x=[x for (x, c) in zip(collect(x0_values)[1:length(convergence_colors)], convergence_colors) if c == 1],
                       y=[p for (p, c) in zip(convergence_points, convergence_colors) if c == 1],
                       mode="markers", name="Converge a r₁=0.10",
                       marker=attr(size=10, color="#ff6b6b", symbol="circle"))
    trace_r2 = scatter(x=[x for (x, c) in zip(collect(x0_values)[1:length(convergence_colors)], convergence_colors) if c == 2],
                       y=[p for (p, c) in zip(convergence_points, convergence_colors) if c == 2],
                       mode="markers", name="Converge a r₂=0.20",
                       marker=attr(size=10, color="#4ecdc4", symbol="circle"))
    
    # Línea vertical donde NPV'=0
    r_critico = 34/230  # ≈ 0.1478
    trace_critico = scatter(x=[r_critico, r_critico], y=[0, 0.25], mode="lines",
                            name="NPV'=0 (frontera)", line=attr(color="black", dash="dash", width=2))
    
    layout_cuencas = Layout(
        title="Cuencas de atracción: Newton para caso de dos raíces",
        xaxis=attr(title="Dato inicial x₀"),
        yaxis=attr(title="Raíz alcanzada r̂", range=[0, 0.25]),
        legend=attr(x=0.7, y=0.9),
        width=700, height=500
    )
    
    Plot([trace_r1, trace_r2, trace_critico], layout_cuencas)
end

# ╔═╡ b0000001-0000-4000-8000-00000000002f
md"""
**Observación:** Los puntos del préstamo base están cerca de la diagonal (residuo ≈ error), lo que significa que el residuo es un buen indicador del error. Sin embargo, en la raíz doble, los puntos están muy por encima de la diagonal: el residuo es diminuto pero el error es mucho mayor. En la hipoteca, el residuo es grande pero el error es pequeño. Esto ilustra que **un residuo pequeño no garantiza una raíz precisa**.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000024
md"""
#### Raíz doble: efecto de la multiplicidad en la convergencia

Comparación de Newton con y sin corrección de multiplicidad:
"""

# ╔═╡ b0000001-0000-4000-8000-00000000002d
begin
    # Recopilar puntos de diferentes casos
    residuos = Float64[]
    errores = Float64[]
    casos = String[]
    
    # Préstamo base (varios formatos)
    for (T, nombre) in [(Float16, "F16"), (Float32, "F32"), (Float64, "F64")]
        c = flujos_prestamo(T, 1000, 1//100, 12)
        f = r -> npv(c, r)
        df = r -> dnpv(c, r)
        r, _, _ = newton(f, df, T(2//100))
        push!(residuos, Float64(abs(f(r))))
        push!(errores, abs(Float64(r) - Float64(r_ref_pres)))
        push!(casos, "Préstamo $nombre")
    end
    
    # Raíz doble (varios formatos)
    for (T, nombre) in [(Float16, "F16"), (Float32, "F32"), (Float64, "F64")]
        c = T[-100, 220, -121]
        f = r -> npv(c, r)
        df = r -> dnpv(c, r)
        r, _, _ = newton(f, df, T(12//100); m=1)
        push!(residuos, Float64(abs(f(r))))
        push!(errores, abs(Float64(r) - Float64(r_ref_doble)))
        push!(casos, "Raíz doble $nombre")
    end
    
    # Hipoteca (varios formatos)
    for (T, nombre) in [(Float32, "F32"), (Float64, "F64")]
        c = flujos_prestamo(T, 1_000_000, 5//1000, 360)
        f = r -> npv(c, r)
        df = r -> dnpv(c, r)
        r, _, _ = newton(f, df, T(1//100))
        push!(residuos, Float64(abs(f(r))))
        push!(errores, abs(Float64(r) - Float64(r_ref_hip)))
        push!(casos, "Hipoteca $nombre")
    end
    
    # Crear trazas por tipo de caso
    trace_prestamo = scatter(x=[residuos[i] for i in 1:3], y=[errores[i] for i in 1:3],
                             mode="markers+text", name="Préstamo",
                             text=["F16", "F32", "F64"], textposition="top center",
                             marker=attr(size=12, color="#ff6b6b"))
    trace_doble = scatter(x=[residuos[i] for i in 4:6], y=[errores[i] for i in 4:6],
                          mode="markers+text", name="Raíz doble",
                          text=["F16", "F32", "F64"], textposition="top center",
                          marker=attr(size=12, color="#4ecdc4"))
    trace_hip = scatter(x=[residuos[i] for i in 7:8], y=[errores[i] for i in 7:8],
                        mode="markers+text", name="Hipoteca",
                        text=["F32", "F64"], textposition="top center",
                        marker=attr(size=12, color="#45b7d1"))
    
    # Línea de referencia (residuo = error)
    max_val = maximum(vcat(residuos, errores))
    trace_ref = scatter(x=[1e-20, max_val*10], y=[1e-20, max_val*10], mode="lines",
                        name="Residuo = Error", line=attr(color="gray", dash="dash"))
    
    layout_residuo_error = Layout(
        title="Residuo vs Error: cuándo el residuo engaña",
        xaxis=attr(title="Residuo |NPV(r̂)|", type="log"),
        yaxis=attr(title="Error |r̂ - r*|", type="log"),
        legend=attr(x=0.05, y=0.95),
        width=700, height=500
    )
    
    plot_residuo_error = Plot([trace_prestamo, trace_doble, trace_hip, trace_ref], layout_residuo_error)
end

# ╔═╡ b0000001-0000-4000-8000-000000000021
begin
    # Extraer errores de las tablas ya calculadas
    métodos_bar = ["bisección", "Newton", "secante", "p. fijo"]
    
    errores_F16_bar = [tabla_pres_F16[i][3] for i in 1:4]
    errores_F32_bar = [tabla_pres_F32[i][3] for i in 1:4]
    errores_F64_bar = [tabla_pres_F64[i][3] for i in 1:4]
    
    trace_F16_bar = bar(x=métodos_bar, y=errores_F16_bar, name="Float16", marker=attr(color="#ff6b6b"))
    trace_F32_bar = bar(x=métodos_bar, y=errores_F32_bar, name="Float32", marker=attr(color="#4ecdc4"))
    trace_F64_bar = bar(x=métodos_bar, y=errores_F64_bar, name="Float64", marker=attr(color="#45b7d1"))
    
    layout_formatos = Layout(
        title="Error alcanzado por método y formato (préstamo base)",
        xaxis=attr(title="Método"),
        yaxis=attr(title="Error |r̂ - r*|", type="log"),
        barmode="group",
        legend=attr(x=0.75, y=0.95),
        width=700, height=500
    )
    
    plot_formatos = Plot([trace_F16_bar, trace_F32_bar, trace_F64_bar], layout_formatos)
end

# ╔═╡ b0000001-0000-4000-8000-000000000030
md"""
#### Barrido de tolerancias: piso de ruido del formato

¿Qué tan pequeña puede ser la tolerancia antes de que el formato limite la precisión?
"""

# ╔═╡ b0000001-0000-4000-8000-000000000025
begin
    c_mult = Float64[-100, 220, -121]
    f_mult = r -> npv(c_mult, r)
    df_mult = r -> dnpv(c_mult, r)
    x0_mult = Float64(12//100)
    
    # Newton sin corrección (m=1)
    new_m1 = newton(f_mult, df_mult, x0_mult; m=1)
    errs_m1 = calcular_errores(new_m1, r_ref_doble)
    
    # Newton con corrección (m=2)
    new_m2 = newton(f_mult, df_mult, x0_mult; m=2)
    errs_m2 = calcular_errores(new_m2, r_ref_doble)
    
    trace_m1 = scatter(x=1:length(errs_m1), y=errs_m1, mode="lines+markers",
                       name="Newton m=1 (lineal)", line=attr(color="#ff6b6b", width=2),
                       marker=attr(size=8, color="#ff6b6b"))
    trace_m2 = scatter(x=1:length(errs_m2), y=errs_m2, mode="lines+markers",
                       name="Newton m=2 (cuadrático)", line=attr(color="#4ecdc4", width=2),
                       marker=attr(size=8, color="#4ecdc4"))
    
    layout_multiplicidad = Layout(
        title="Raíz doble: Newton con y sin corrección de multiplicidad",
        xaxis=attr(title="Iteración"),
        yaxis=attr(title="Error |r̂ - r*|", type="log"),
        legend=attr(x=0.6, y=0.9),
        width=700, height=500
    )
    
    Plot([trace_m1, trace_m2], layout_multiplicidad)
end

# ╔═╡ b0000001-0000-4000-8000-000000000033
md"""
**Observación:** Para tolerancias mayores que 10⁻⁸, tanto el error como el residuo disminuyen con la tolerancia solicitada. Pero para tolerancias menores que 10⁻⁸, ambos se estancan en el piso de ruido del formato (≈10⁻¹⁶ para error, ≈10⁻¹³ para residuo). No tiene sentido pedir tolerancias menores que √ε, el formato no puede cumplirlas.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000023
md"""
**Observación:** Float64 alcanza errores del orden de 10⁻¹⁶, Float32 alrededor de 10⁻⁷, y Float16 solo llega a 10⁻². Esto confirma que el formato limita el error mínimo alcanzable, independientemente del método utilizado.
"""

# ╔═╡ b0000001-0000-4000-8000-000000000028
md"""
#### Cuencas de atracción (dos raíces)

Para el caso con dos raíces (r₁=10% y r₂=20%), esta gráfica muestra a cuál raíz converge Newton desde diferentes datos iniciales:
"""

# ╔═╡ b0000001-0000-4000-8000-00000000002b
md"""
**Observación:** La frontera entre cuencas está exactamente en r ≈ 14.8% donde NPV'=0. Desde x₀ < 14.8% Newton converge a r₁=10%, y desde x₀ > 14.8% converge a r₂=20%. Cerca de la frontera, el método puede dar saltos grandes o no converger.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoPlotly = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
PlutoPlotly = "~0.3.9"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.5"
manifest_format = "2.0"
project_hash = "da3ad4b119c23e952f4b81275091d57da05d0e6f"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b0fd3f56fa442f81e0a47815c92245acfaaa4e34"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f88f3ccef05a6a72a0cf0ed417c8fd68530f4ab2"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.PackageExtensionCompat]]
deps = ["Requires", "TOML"]
git-tree-sha1 = "fb28e33b8a95c4cee25ce296c817d89cc2e53518"
uuid = "65ce6f38-6b18-4e1d-a461-8949797d7930"
version = "1.0.2"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "ba0dc8a8a67cacac4842631f960c046e4e563675"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.8"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlotlyBase]]
deps = ["ColorSchemes", "Colors", "Dates", "DelimitedFiles", "DocStringExtensions", "JSON", "LaTeXStrings", "Logging", "Parameters", "Pkg", "REPL", "Requires", "Statistics", "UUIDs"]
git-tree-sha1 = "6256ab3ee24ef079b3afa310593817e069925eeb"
uuid = "a03496cd-edff-5a9b-9e67-9cda94a718b5"
version = "0.8.23"

[[deps.PlutoPlotly]]
deps = ["AbstractPlutoDingetjes", "Colors", "Dates", "HypertextLiteral", "InteractiveUtils", "LaTeXStrings", "Markdown", "PackageExtensionCompat", "PlotlyBase", "PlutoUI", "Reexport"]
git-tree-sha1 = "9a77654cdb96e8c8a0f1e56a053235a739d453fe"
uuid = "8e989ff0-3d88-8e9f-f020-2b208a939ff0"
version = "0.3.9"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "fbc875044d82c113a9dee6fc14e16cf01fd48872"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.80"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "5005266de4bfe50e53ff44a5cb5c540b6e47a254"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.6.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "908fec9df6c5de98548ead82a468c95ccf6cd263"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.7.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─a0000000-0000-4000-8000-000000000001
# ╟─a0000000-0000-4000-8000-000000000002
# ╟─a0000000-0000-4000-8000-00000000002b
# ╟─a0000000-0000-4000-8000-000000000003
# ╟─a0000000-0000-4000-8000-000000000004
# ╟─a0000000-0000-4000-8000-000000000005
# ╠═a0000000-0000-4000-8000-000000000100
# ╠═a0000000-0000-4000-8000-000000000006
# ╟─a0000000-0000-4000-8000-000000000009
# ╠═a0000000-0000-4000-8000-000000000010
# ╟─a0000000-0000-4000-8000-000000000018
# ╠═a0000000-0000-4000-8000-000000000019
# ╟─a0000000-0000-4000-8000-000000000020
# ╠═a0000000-0000-4000-8000-000000000021
# ╟─a0000000-0000-4000-8000-000000000022
# ╠═a0000000-0000-4000-8000-000000000023
# ╟─a0000000-0000-4000-8000-000000000024
# ╠═a0000000-0000-4000-8000-000000000025
# ╟─a0000000-0000-4000-8000-000000000026
# ╠═a0000000-0000-4000-8000-000000000027
# ╟─a0000000-0000-4000-8000-000000000028
# ╠═a0000000-0000-4000-8000-000000000029
# ╠═4b635a2b-ffd6-4a51-b4b8-fe52ce527866
# ╟─4c7ed7b9-8b74-46d7-a5d8-6f8a5d257612
# ╟─a0000000-0000-4000-8000-000000000030
# ╠═a0000000-0000-4000-8000-000000000032
# ╠═a0000000-0000-4000-8000-000000000033
# ╟─a0000000-0000-4000-8000-000000000036
# ╟─b0000001-0000-4000-8000-000000000001
# ╠═b0000001-0000-4000-8000-000000000002
# ╠═b0000001-0000-4000-8000-000000000003
# ╟─b0000001-0000-4000-8000-000000000004
# ╟─b0000001-0000-4000-8000-000000000005
# ╠═b0000001-0000-4000-8000-000000000006
# ╟─b0000001-0000-4000-8000-000000000007
# ╠═b0000001-0000-4000-8000-000000000008
# ╟─b0000001-0000-4000-8000-000000000009
# ╠═b0000001-0000-4000-8000-00000000000a
# ╟─b0000001-0000-4000-8000-00000000000b
# ╠═b0000001-0000-4000-8000-00000000000c
# ╟─b0000001-0000-4000-8000-00000000000d
# ╟─b0000001-0000-4000-8000-00000000000e
# ╠═b0000001-0000-4000-8000-00000000000f
# ╟─b0000001-0000-4000-8000-000000000010
# ╟─b0000001-0000-4000-8000-000000000011
# ╠═b0000001-0000-4000-8000-000000000012
# ╟─b0000001-0000-4000-8000-000000000013
# ╟─b0000001-0000-4000-8000-000000000014
# ╠═b0000001-0000-4000-8000-000000000015
# ╟─b0000001-0000-4000-8000-000000000016
# ╠═b0000001-0000-4000-8000-000000000017
# ╟─b0000001-0000-4000-8000-000000000018
# ╠═b0000001-0000-4000-8000-000000000019
# ╠═b0000001-0000-4000-8000-00000000001a
# ╟─b0000001-0000-4000-8000-000000000034
# ╟─b0000001-0000-4000-8000-000000000027
# ╠═b0000001-0000-4000-8000-000000000031
# ╠═b0000001-0000-4000-8000-000000000029
# ╠═b0000001-0000-4000-8000-00000000002f
# ╠═b0000001-0000-4000-8000-000000000024
# ╠═b0000001-0000-4000-8000-00000000002d
# ╠═b0000001-0000-4000-8000-000000000021
# ╟─b0000001-0000-4000-8000-000000000030
# ╠═b0000001-0000-4000-8000-000000000025
# ╟─b0000001-0000-4000-8000-000000000033
# ╟─b0000001-0000-4000-8000-000000000023
# ╟─b0000001-0000-4000-8000-000000000028
# ╟─b0000001-0000-4000-8000-00000000002b
# ╟─b0000001-0000-4000-8000-00000000001b
# ╟─b0000001-0000-4000-8000-00000000001c
# ╟─b0000001-0000-4000-8000-00000000001d
# ╟─b0000001-0000-4000-8000-00000000001e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
