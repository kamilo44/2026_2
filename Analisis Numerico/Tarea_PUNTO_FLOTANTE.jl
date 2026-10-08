### A Pluto.jl notebook ###
# v1.0.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ f3fc95c1-4dbe-4ece-aa9e-fab938c1f71f
begin
    using PlutoUI
    using Random
    using Statistics
    using Plots
end

# ╔═╡ 0c4dee43-bb7e-423b-81ba-c8aa539f242d
md"""
# Universidad Nacional de Colombia
**Facultad de Ciencias – Departamento de Matemáticas**

**Análisis Numérico – 2026 II**

Profesor: Juan Carlos Galvis Arrieta

15 de septiembre de 2026

---

Sofia Salinas Rico — ssalinas@unal.edu.co

William Gallego — wgallegom@unal.edu.co

Sara Rivera — sariveras@unal.edu.co

---

# Tarea Punto Flotante
"""

# ╔═╡ f5ee528b-8d13-4299-87be-5075e4c71eef
md"""
## 1. Pregunta o tema de investigación

Todos recordamos el pánico del Samsung Note 7 incendiándose en los bolsillos o la cautela casi sagrada al manipular energía en los laboratorios del IEEE.

Aunque solemos atribuir estos desastres a fallas físicas o cables defectuosos, a veces el peligro nace de una amenaza matemática sutil: el desfase al traducir el mundo analógico continuo al lenguaje binario. Al capturar una señal con un osciloscopio de 8 bits como el OWON VDS1022I, la tensión real se fragmenta en solo 256 escalones discretos; al procesar luego esas muestras con formatos de precisión finita como Float16 o Float32, los errores analógicos de offset y el ruido térmico no desaparecen, sino que se multiplican en cada cálculo. De esta tensión entre la física y la informática surge nuestra pregunta de investigación: **¿De qué manera la propagación combinada del error analógico y la cuantización digital en instrumentos de medición compromete la precisión de los cálculos de potencia y la seguridad en sistemas electrónicos?**

Tirar de este hilo nos plantea dudas cruciales: ¿domina la tijera digital del convertidor sobre el ruido del propio cable?, ¿qué le ocurre a un algoritmo cuando integra miles de estas muestras imprecisas para estimar energía en tiempo real? En última instancia, este análisis revela si una pequeña imprecisión en punto flotante puede hacer que el sistema de gestión de una batería de litio pase por alto un pico de sobretensión crítico, demostrando que la interminable fila de decimales que dibuja la pantalla de la computadora es, muy a menudo, una peligrosa ilusión de precisión.

"""

# ╔═╡ 8fad88fb-5305-4842-bbe6-7be55fc2eec2
md"""
## 2. ¿Por qué es interesante?

Hoy dependemos a diario de la electrónica en teléfonos, vehículos y dispositivos inteligentes. Al usar instrumentos de laboratorio como un multímetro o un osciloscopio USB (como el OWON VDS1022I de 8 bits), es fácil asumir que los datos en pantalla son exactos. Sin embargo, existe un desfase entre la señal física continua y su representación en bits dentro del equipo o la computadora.

Este tema conecta directamente los conceptos de la clase (cuantización, formatos Float16/32, error de redondeo y propagación de imprecisiones) con la ingeniería del mundo real. En entornos como laboratorios del IEEE o la industria, la acumulación de pequeñas desviaciones analógicas y digitales no es solo un problema matemático abstracto: en sistemas críticos, una mala estimación de parámetros como tensión o corriente puede causar lecturas falsas en protecciones, descargas eléctricas o fallas térmicas destructivas en baterías de litio (como las ocurridas en dispositivos portátiles). Investigar este límite permite entender el riesgo real de confiar ciegamente en la precisión finita de los computadores al medir el mundo físico.
"""

# ╔═╡ f3617209-2050-4d68-a50f-b6a2e648ee4d
md"""
## 3. Predicción inicial

Los científicos de la computación que componen este grupo no poseen bastos conocimientos en electrónica pero estimamos que la OWON VDS1022I puede tener un error suficientemente grande como para tener consecuencias fatales.

Es posible que el error conjunto sea tan grande hasta 10⁻³, que es una falta de precisión inadmisible para la industria.

Tambien que el error final que es la suma del error de medición y errores de truncamiento será linealmente aumentado pero no alcanzara a ser exponencial. 

"""

# ╔═╡ ae7189ca-3ec7-4212-ad17-51f5f136845e
md"""
## 4. Investigación o experimento

De acuerdo con las especificaciones del manual del osciloscopio OWON VDS1022I y el análisis de la estructura de sus archivos de datos, la adquisición y el almacenamiento de la señal ocurren en dos etapas con formatos numéricos distintos, lo cual tiene un impacto directo en la propagación del error.

### Formatos de Datos: De Int a Float

El convertidor analógico-digital (ADC) del VDS1022I tiene una resolución vertical nativa de 8 bits. Esto significa que el hardware muestrea la señal eléctrica y la almacena internamente como un número entero (*integer*) de 8 bits sin signo. Por lo tanto, la medición física se restringe a exactamente 256 niveles discretos (2⁸ = 256).

Cuando el software de PC de OWON lee el equipo y exporta estos datos (por ejemplo, a un archivo .bin, .cap o .csv), extrae los enteros de 8 bits (almacenados a partir del byte 278 en el archivo binario) y los convierte a formato de punto flotante (float, típicamente Float32) aplicando una transformación lineal. La fórmula empírica empleada por el software es del tipo:

**$V<sub>float</sub> = a · X<sub>int</sub> + b$**

donde $a$ es un factor de escala (ej. 0.4) y $b$ es un offset (ej. 53.2).
"""

# ╔═╡ 90e4a4b7-bd29-4aa0-a5ff-7052703e6565
md"""
### Impacto en el Error y las Varianzas

Al convertir un entero de 8 bits a un float de 32 bits, el software de la computadora no pierde información en el proceso de conversión, ya que los 24 bits de la mantisa de un Float32 son más que suficientes para contener los 8 bits originales de forma exacta. Sin embargo, tampoco mejora la precisión. El error dominante sigue regido por las siguientes varianzas:

1. **Varianza de Cuantización (Error del Hardware):** el error de cuantización e<sub>q</sub> al convertir la señal continua a un entero de 8 bits tiene una distribución uniforme. Su varianza es

   $θ <sub>q</sub>^2 = \Delta^2 / 12,$

   donde el paso de resolución es $\Delta = V<sub>rango</sub> / 256$.

2. **Varianza Total Transformada (Error del Software):** cuando el software aplica la fórmula de escala para pasar a float, por las propiedades estadísticas de la varianza, el error de la variable aleatoria se escala cuadráticamente:

   $Var(V<sub>float</sub>) = a^2 · Var(X<sub>int</sub>) +$ $Var(Ruido<sub>analógico</sub>)$

El peligro para tu experimento radica en la ilusión de precisión: al abrir el archivo .csv exportado por OWON, verás datos en punto flotante con múltiples decimales (ej. 3,141592 V), pero la señal real sigue estando rígidamente discretizada en 256 escalones. La varianza del error no disminuye por usar Float32 o Float64 en la computadora; el "daño" ya fue infligido irreparablemente por el entero de 8 bits del ADC del osciloscopio.

"""

# ╔═╡ ae0ef280-8e01-4b6d-9afe-e0bd0699edc0
md"## Experimento"

# ╔═╡ f1c52e68-f0b7-46fd-a37e-ddcdf3ad91f7
md"Para este experimento vamos a fijar estas variables:"

# ╔═╡ 27f9ff62-0a48-4461-ab70-3a8c294357a1

    @bind precision Select(
        ["Float16", "Float32"],
        default="Float32"
    )


# ╔═╡ bf8eb4ef-21b4-4b5a-b27a-c2f3cb262b0f
md"tensión física real"

# ╔═╡ 97616cca-e77f-466e-baaa-b8457e41cdb2

    @bind Vreal Slider(
        0.1:0.1:10.0,
        default=1.0,
        show_value=true
    )
#tensión física real.

# ╔═╡ 9e2344b2-9b5a-4dd3-bb3e-09aacb1d8197
md"corriente física real"

# ╔═╡ c13d737a-782c-4eaf-8e37-562a51057b95
 @bind Ireal Slider(
        0.01:0.01:2.0,
        default=0.5,
        show_value=true
    )
#corriente física real.

# ╔═╡ 0bbd1a4c-9fe1-485a-9a82-e2360ff5e8e2
md"desviación estándar del error de offset."

# ╔═╡ 1b1dd69e-2cc4-470f-b2ce-d8a0108a55e6

    @bind σ_offset Slider(
        0.0:0.0001:0.05,
        default=0.005,
        show_value=true
    )
# desviación estándar del error de offset.

# ╔═╡ db67f3eb-c8a1-444a-a91c-b87b06395166
md"desviación estándar del ruido térmico"

# ╔═╡ 8977e6bb-a296-4962-80e8-b9d20a012717
 @bind σ_thermal Slider(
        0.0:0.0001:0.05,
        default=0.002,
        show_value=true
    )
#desviación estándar del ruido térmico

# ╔═╡ daf9b087-7416-45e2-93ac-28a8889a0151
md"resolución del ADC"

# ╔═╡ 3e6f10db-06c4-4f3d-aa2a-5ecce2adca82

    @bind bits Slider(
        8:16,
        default=8,
        show_value=true
    )
#resolución del ADC

# ╔═╡ 4763b8d8-6ca9-4971-ab27-f9509440b3ec
md"número de experimentos Monte Carlo"

# ╔═╡ 75336650-f6d6-467c-a04a-1402a1b73c8b
    @bind N Slider(
        1000:1000:100000,
        default=10000,
        show_value=true
    )
#número de experimentos Monte Carlo.

# ╔═╡ abc10e03-1cd6-4aea-9244-c967fcbff5ee
md"escala vertical del OWON"

# ╔═╡ 04ea6b80-5955-4187-9c8f-9f2ccceedcf3
   @bind vdiv Select(
        [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0],
        default = 1.0
    )

# ╔═╡ 6f24661c-5c39-4dba-8596-4aa4cccdabb1
md"límite para estudiar riesgo/sobrepotencia"

# ╔═╡ 0c89915c-ca15-4ecf-a282-5d58ebf172e8
@bind P_limit Slider(
        0.1:0.1:20.0,
        default = 5.0,
        show_value = true
    )

# ╔═╡ 5808801f-72b0-4af5-a043-c80e4bd0491d
begin

    # ==========================================
    # ESPECIFICACIONES REALES OWON VDS1022I
    # ==========================================

    OWON_BITS = 8
    OWON_DC_ACCURACY = 0.03
    OWON_AVG_EXTRA_DIV = 0.05

    OWON_BANDWIDTH_MHZ = 25.0
    OWON_SAMPLE_RATE_MSPS = 100.0

    OWON_MIN_VDIV = 0.005
    OWON_MAX_VDIV = 5.0

    OWON_CHANNELS = 2

    # El rango vertical visible es aproximadamente
    # 8 divisiones verticales.
    N_DIV = 8.0

end

# ╔═╡ 92e9a545-44a1-46f4-b71c-5e3c684c3e64
begin

    T = precision == "Float16" ? Float16 : Float32

    V₀ = T(Vreal)
    I₀ = T(Ireal)

    σo = T(σ_offset)
    σt = T(σ_thermal)

    dc_accuracy = T(OWON_DC_ACCURACY)
    vdiv_T = T(vdiv)

    P_real = V₀ * I₀

end

# ╔═╡ 7643351c-00e4-468e-83d7-688349b39d45
begin

    levels = T(2.0^bits)

    vertical_range = T(N_DIV) * vdiv_T

    ΔV = vertical_range / levels

    quantization_std =
        ΔV / T(sqrt(12))

end

# ╔═╡ bff0eeab-42c9-4d1f-9001-420785eb06f2
md"Aquí estamos modelando la cuantización:

$\Delta = \frac{2V_{\max}}{2^B}$

y:

$V_q=\operatorname{round}\left(\frac{V}{\Delta}\right)\Delta$"

# ╔═╡ b16ac844-9d42-46cb-8993-1bb560189071
begin

    function quantize(
        x::T,
        Δ::T,
        Vmax::T
    ) where {T <: AbstractFloat}

        x_clipped = clamp(
            x,
            -Vmax,
            Vmax
        )

        q = round(x_clipped / Δ)

        return T(q * Δ)
    end

end

# ╔═╡ 4ea93b0b-1540-4ab1-8531-7a363cd9fbec
begin

    function medir_tension(
        Vreal::T,
        σ_offset::T,
        σ_thermal::T,
        dc_accuracy::T,
        Δ::T,
        Vmax::T
    ) where {T <: AbstractFloat}

        # ----------------------------------
        # 1. ERROR DE OFFSET
        # ----------------------------------

        offset =
            T(randn()) * σ_offset


        # ----------------------------------
        # 2. RUIDO TÉRMICO
        # ----------------------------------

        thermal =
            T(randn()) * σ_thermal


        # ----------------------------------
        # 3. SEÑAL ANALÓGICA
        # ----------------------------------

        Vanalog =
            Vreal +
            offset +
            thermal


        # ----------------------------------
        # 4. ERROR DE GANANCIA DEL OWON
        #
        # ±3 %
        # ----------------------------------

        gain_error =
            T(rand()) *
            T(2) *
            dc_accuracy -
            dc_accuracy

        Vanalog_gain =
            Vanalog *
            (T(1) + gain_error)


        # ----------------------------------
        # 5. CUANTIZACIÓN ADC
        # ----------------------------------

        Vdigital =
            quantize(
                Vanalog_gain,
                Δ,
                Vmax
            )


        return (
            offset = offset,
            thermal = thermal,
            gain_error = gain_error,
            analog = Vanalog_gain,
            digital = Vdigital
        )

    end

end

# ╔═╡ 3c90efee-dd22-4cb3-ae2d-053ace71ca89
md"Ahora vamos a hacer miles de mediciones con Monte Carlo"

# ╔═╡ a94ee15c-baea-449d-aae1-bc606ff41fa7
begin

    Random.seed!(2026)

    Vmeasurements =
        Vector{T}(undef, N)

    Verrors =
        Vector{T}(undef, N)

    Voffsets =
        Vector{T}(undef, N)

    Vthermals =
        Vector{T}(undef, N)

    Vgainerrors =
        Vector{T}(undef, N)


    Vmax = T(N_DIV * vdiv)


    for k in 1:N

        m = medir_tension(
            V₀,
            σo,
            σt,
            dc_accuracy,
            ΔV,
            Vmax
        )

        Vmeasurements[k] = m.digital

        Verrors[k] =
            m.digital - V₀

        Voffsets[k] =
            m.offset

        Vthermals[k] =
            m.thermal

        Vgainerrors[k] =
            m.gain_error

    end

end

# ╔═╡ a7e55021-452f-4fd0-9a2c-24de229a22a2
mean_error_V =
        T(mean(Verrors))

# ╔═╡ 76ec24ab-8c0f-410e-9e6b-5430eaec79da
    variance_error_V =
        T(var(Verrors))

# ╔═╡ 02306a9a-075a-4904-953f-7eb13af97d37
    std_error_V =
        T(sqrt(variance_error_V))

# ╔═╡ 1c05cb1e-c877-492c-9cca-3f8e74e6602c
   min_error_V =
        minimum(Verrors)

# ╔═╡ c65a23ac-d57d-462e-9f6f-ac78e0c91255
   max_error_V =
        maximum(Verrors)

# ╔═╡ 8d8ce4a9-b550-4a25-959c-f1c35aed69bb
    mean_voltage =
        T(mean(Vmeasurements))

# ╔═╡ 44dfb409-2831-4890-b20c-c922ef1e35b2
md"### Resultados de la medición"

# ╔═╡ df57d93e-ce36-4035-a66e-59338d233ed7
begin

    println("========================================")
    println("      RESULTADOS DE LA MEDICIÓN")
    println("========================================")

    println()

    println("Precisión numérica: ", precision)

    println("Tensión real: ",
            V₀, " V")

    println("Corriente real: ",
            I₀, " A")

    println("Potencia real: ",
            P_real, " W")

    println()

    println("----------- ADC OWON ------------------")

    println("Resolución ADC: ",
            bits, " bits")

    println("Escala vertical: ",
            vdiv, " V/div")

    println("Resolución cuantización ΔV: ",
            ΔV, " V")

    println()

    println("----------- ERROR DE TENSIÓN ----------")

    println("Error medio: ",
            mean_error_V, " V")

    println("Varianza del error: ",
            variance_error_V, " V²")

    println("Desviación estándar: ",
            std_error_V, " V")

    println("Error mínimo observado: ",
            min_error_V, " V")

    println("Error máximo observado: ",
            max_error_V, " V")

end

# ╔═╡ 288d7d1f-94e4-48c7-a9b1-24aff2ec135f
md"Bueno ahora vamos con la corriente XD

Para calcular potencia necesitamos que V e I tengan errores.
"

# ╔═╡ 352b667b-c6e5-433b-b8af-8bbd877068a6
begin

    Imeasurements =
        Vector{T}(undef, N)

    Pmeasurements =
        Vector{T}(undef, N)

    Ierrors =
        Vector{T}(undef, N)


    Imax = T(2.0)

    ΔI =
        T(2.0 * Imax) /
        T(2.0^bits)


    for k in 1:N

        Ioffset =
            T(randn()) * σo

        Ithermal =
            T(randn()) * σt

        Ianalog =
            I₀ +
            Ioffset +
            Ithermal

        Idigital =
            quantize(
                Ianalog,
                ΔI,
                Imax
            )

        Imeasurements[k] =
            Idigital

        Ierrors[k] =
            Idigital - I₀

        # =================================
        # AQUÍ APARECE EL ERROR PROPAGADO
        # =================================

        Pmeasurements[k] =
            Vmeasurements[k] *
            Imeasurements[k]

    end

end

# ╔═╡ 5ee1bc72-8e41-4a88-9cea-1c2a071ade69
md"aqui lo que estamos haciendo es tensión contaminada * corriente contaminada = 
potencia contaminada"

# ╔═╡ d1b29873-9a3c-4f5e-b5e2-5b0f489f9743
md"
## 5. Resultados y explicación

Al observar los histogramas y la dispersión generada por las 10000 iteraciones de Monte Carlo, podemos desglosar cómo el hardware del OWON VDS1022I corrompe la medición antes de que el software siquiera intervenga:

1. **Dominancia de la cuantización sobre el ruido:** Con una escala de 1.0 V/div y 8 divisiones, el rango total es de 8.0 V. Al tener un ADC de 8 bits, el tamaño del escalón es $\Delta V = 8.0 / 256 = 0.03125 \text{ V}$. Dado que configuramos un ruido térmico de 0.002 y un offset de 0.005, la suma de las perturbaciones analógicas es mucho menor que el escalón de cuantización. Esto fuerza a que la distribución del error adquiera formas uniformes o discretas severas cuando bajamos la escala, ya que la señal queda atrapada o 'encasillada' en unos pocos niveles del ADC.
2. **Propagación hacia la Potencia ($P = V \cdot I$):** Al multiplicar dos variables aleatorias contaminadas, el error relativo total se aproxima a la suma de los errores relativos de la tensión y la corriente. Los gráficos demuestran que la varianza de la potencia es altamente sensible a las desviaciones de offset. Sin embargo, la dispersión resultante sigue dictada por el cuello de botella de los 8 bits del hardware, haciendo que los 24 bits de mantisa del formato Float32 computacional sean prácticamente inútiles para 'recuperar' la información. 
3. **El colapso de la varianza:** Como notamos al jugar con los parámetros, si la escala es inapropiada respecto a la señal real, el osciloscopio truncará los valores al mismo nivel discreto repetidas veces, haciendo que la varianza medida colapse a cero de forma artificial, creando una peligrosa 'ilusión de estabilidad' .

### Resultados de error de potencias"

# ╔═╡ f5fe3fb6-c7ac-4afe-94f3-0531b68fa39d
  Perrors =
        Pmeasurements .- P_real

# ╔═╡ eb3a9365-0a0f-44bf-8c7b-e7f2cccaf8e4
    P_max = maximum(Pmeasurements)

# ╔═╡ 772829bf-bbd2-4367-aa78-654fe444797e

    P_error_min = minimum(Perrors)

# ╔═╡ 23c6b0d9-b90d-46f4-af19-4cebcd73b881
    P_error_max = maximum(Perrors)

# ╔═╡ 02e42ab3-8453-432a-b00b-b5b4b836c700
P_error_mean = T(mean(Perrors))

# ╔═╡ 30cab3aa-e028-42cf-87d9-fa5343daf78c
 P_error_variance =
        T(var(Perrors))

# ╔═╡ 9f52e318-bae3-44a3-9150-9b95b02810b2
   P_error_std =
        T(sqrt(P_error_variance))

# ╔═╡ 0071601c-ecad-4c34-ba46-39524b6cdc59
mean_power =
        T(mean(Pmeasurements))

# ╔═╡ 5c79e07c-bb45-4a33-915d-bc3649d80b99
begin

    println("========================================")
    println("          RESULTADOS DE POTENCIA")
    println("========================================")

    println()

    println("Potencia real: ",
            P_real, " W")

    println("Potencia media medida: ",
            mean_power, " W")

    println()

    println("Error medio: ",
            P_error_mean, " W")

    println("Varianza del error: ",
            P_error_variance, " W²")

    println("Desviación estándar: ",
            P_error_std, " W")

    println("Error mínimo observado: ",
            P_error_min, " W")

    println("Error máximo observado: ",
            P_error_max, " W")

end

# ╔═╡ 81e22708-815e-4dcb-8d59-40fe63e92c56
begin

    histogram(
        Verrors,
        bins = 60,
        xlabel = "Error de tensión (V)",
        ylabel = "Frecuencia",
        title = "Distribución del error de tensión",
        legend = false
    )

end

# ╔═╡ 2a6dc541-3952-4452-8c91-169d1c412d50
begin

    histogram(
        Perrors,
        bins = 60,
        xlabel = "Error de potencia (W)",
        ylabel = "Frecuencia",
        title = "Propagación del error hacia la potencia",
        legend = false
    )

end

# ╔═╡ 478722b9-719c-4b96-96f5-6cfc3923d490
md"La propagación del error hacia la potencia concerva en buena medida una desviación estandar, sin embargo con un cambio de solo 0.0006 en la desviación offset, la distribución cambia de parametro.

Asi mismo cuando se reduce la escala , la propagación del error se concentra pues la distribución del error de la tensión se vuelve uniforme con frecuencia de 6000 "

# ╔═╡ 737d096e-5b64-4335-9c9b-de8b5305a026
begin

    scatter(
        1:N,
        Pmeasurements,
        markersize = 2,
        xlabel = "Experimento",
        ylabel = "Potencia medida (W)",
        title = "Variación de la potencia medida",
        label = "P medida"
    )

    hline!(
        [Float64(P_real)],
        linestyle = :dash,
        label = "P real"
    )

end

# ╔═╡ 67ace9db-0fff-4a92-9e90-85607891b010
md"Jugando un poco con los parametros vemos que la variación de la potencia media es altamente sensible a los cambios de desviación estándar del error de offset. 

Por otro lado reduciendo la escala la variación de la potencia media colapsa a 0 aunque la real este en 0.5. Esto nos da preocupantes cortes de precisión "

# ╔═╡ 56244d20-0f48-43e9-9b11-7287494105d8
begin
    false_safe =
        sum(
            Pmeasurements .> T(P_limit)
        )

    false_safe_rate =
        false_safe / N

    println("========================================")
    println("           ANÁLISIS DE SEGURIDAD")
    println("========================================")

    println()

    println("Límite de potencia: ",
            P_limit, " W")

    println("Experimentos que superan el límite: ",
            false_safe)

    println("Probabilidad estimada de superar el límite: ",
            false_safe_rate)

end

# ╔═╡ 8ed4ab0d-b978-4be7-bbe6-05d336012a94
md"""
## 6. Conclusión

Nuestra hipótesis inicial sugería que la propagación combinada de errores analógicos y el truncamiento digital en un osciloscopio de bajo costo podría causar desviaciones de magnitud catastrófica[cite: 1]. Los resultados del experimento de Monte Carlo refutan parcialmente esta predicción, pero revelan un problema mucho más sutil.

Con nuestros parámetros base ($P_{real} = 0.5 \text{ W}$) y un umbral crítico de 5.0 W, la probabilidad de sobrepasar el límite de seguridad por puro error del instrumento fue de 0[cite: 1]. La varianza introducida por los 8 bits y el ruido térmico/offset oscila en el orden de los milivatios, lo que demuestra que cuando una resistencia o un componente estalla en el laboratorio, se debe abrumadoramente a un error humano de conexión o diseño, y no a una falla del instrumento[cite: 1].

No obstante, el experimento confirma la **ilusión de la precisión en punto flotante**. El software exporta números Float32 con múltiples decimales, disfrazando el hecho de que el osciloscopio solo "ve" el mundo en 256 bloques rígidos[cite: 1]. En sistemas de gestión de baterías (BMS) más sensibles que nuestro experimento, donde un error de 30 mV al integrar energía puede significar la diferencia entre una carga segura y una fuga térmica, confiar ciegamente en los decimales que arroja la pantalla sin entender la resolución subyacente del hardware sigue siendo un riesgo de ingeniería genuino.

Fue divertido de ver
"""

# ╔═╡ 489234d1-c799-47c2-a662-d7f3de00bd91
md"
## 7. ¿Qué cambió en mi comprensión? 


Nosotros no sabiamos por ejemplo que era comun el error de cuantización, es graciosos que uno puede mejorar la medición simplemente con la escala que se usa pero que para efectos practicos por la magnitud de los datos y el ánimo de ver 'la forma' de la emtrada los estudiantes de electronica no se preocupan por tener exactas las mediciones, a pesar de que las resistencias se les pueden totear en las manos.


Usamos el asistente Gemini dado que tenemos versión pro, casi siempre para preguntarle cosas de electrónica; también usamos notebook llm para encontrar facilmente los manuales del fabricante que indicaban la precisión y el error.

Lo usamos para una o dos preguntas importantes que le formularon.

Algo que tuvimos que verificar: que el OWON trabaja en 8 bits y que daba enteros; de hecho, sí y no — él trabaja en solo 256 niveles, lo que hace es dividir una escala en 256 para poder graficarla, puesto que las pantallas para las que fue diseñado eran de solo 8 bits. Aquí, en el diseño, sacrificaron precisión por rapidez en el tiempo de respuesta.

La IA se confundía un poco con esto, sobre todo para rectificar el error de cuantización."

# ╔═╡ bd18d7dc-eade-4aee-8a3d-060181fbb996
md"""
## Referencias

[1] OWON Technology. *OWON VDS1022I USB PC Oscilloscope User Manual*, 2024. Accedido: 2026-09-16.

[2] GerdW et al. *The structure of binary waveform file saved via owon oscilloscope*, 2018. Accedido: 2026-09-17.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
Plots = "~1.41.7"
PlutoUI = "~0.7.83"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.13.0"
manifest_format = "2.1"
project_hash = "afca714ef5af0e0c526669188984c47815c4c678"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "e71ee7b4aa06b045259a7d6101e1cb45ad140bce"
registries = "General"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.1"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
registries = "General"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
registries = "General"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1fa950ebc3e37eccd51c6a8fe1f92f7d86263522"
registries = "General"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.7+0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b0fd3f56fa442f81e0a47815c92245acfaaa4e34"
registries = "General"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
registries = "General"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
registries = "General"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

    [deps.ColorVectorSpace.weakdeps]
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "37ea44092930b1811e666c3bc38065d7d87fcc74"
registries = "General"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.5.5+2"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
registries = "General"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
registries = "General"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "b0bc6d2cad1fed8b7fd59a1551a991cb3d2809e6"
registries = "General"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.6"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "473e9afc9cf30814eb67ffa5f2db7df82c3ad9fd"
registries = "General"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.16.2+0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
registries = "General"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
registries = "General"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a4be429317c42cfae6a7fc03c31bad1970c310d"
registries = "General"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+1"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "2bfb1e047e2ad0a5ca94365340bde8005d637568"
registries = "General"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.8.4+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "95ecf07c2eea562b5adbd0696af6db62c0f52560"
registries = "General"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.5"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libva_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "7a58e45171b63ed4782f2d36fdee8713a469e6e0"
registries = "General"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "8.1.2+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
registries = "General"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "f85dac9a96a01087df6e3a749840015a0ca3817d"
registries = "General"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.17.1+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
registries = "General"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "70329abc09b886fd2c5d94ad2d9527639c421e3e"
registries = "General"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.14.3+1"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
registries = "General"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "64bbbb7d1499297751b536dd39c58b20750ab1db"
registries = "General"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.5.1+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "JSON", "Libdl", "LinearAlgebra", "Preferences", "Printf", "Qt6Wayland_jll", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "p7zip_jll"]
git-tree-sha1 = "4d777f73c46b46b8b5276206059cf8a195499314"
registries = "General"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.73.27"

    [deps.GR.extensions]
    IJuliaExt = "IJulia"

    [deps.GR.weakdeps]
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "FreeType2_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Qt6Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f8eb8f7ba13ea75083531647fc8faeda8d541f07"
registries = "General"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.73.27+0"

[[deps.GettextRuntime_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll"]
git-tree-sha1 = "45288942190db7c5f760f59c04495064eedf9340"
registries = "General"
uuid = "b0724c58-0f36-5564-988d-3bb0596ebc4a"
version = "0.22.4+0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
registries = "General"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "GettextRuntime_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "090526e65de8f69648ac156daae153de8b56df62"
registries = "General"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.88.3+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "69ffb934a5c5b7e086a0b4fee3427db2556fba6e"
registries = "General"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.16+0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "9d9531a9cb63a9edc33836414e82a07e81710de2"
registries = "General"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "100.14004.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
registries = "General"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
registries = "General"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
registries = "General"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
registries = "General"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.JLFzf]]
deps = ["REPL", "Random", "fzf_jll"]
git-tree-sha1 = "82f7acdc599b65e0f8ccd270ffa1467c21cb647b"
registries = "General"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.11"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
registries = "General"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "cb5b63c11dd08229716a8b41a2325ab941a7b797"
registries = "General"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.8.1"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "037babc10853eeb8e585418922246cb97b8e5b74"
registries = "General"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.2.0+1"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "059aabebaa7c82ccb853dd4a0ee9d17796f7e1bc"
registries = "General"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "39bca05343661c347aae0bca57a5994a0bf4f08d"
registries = "General"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.2.0+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e5b100780d4d30d63b4618d7930d48af409c1772"
registries = "General"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "23.1.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f88f3ccef05a6a72a0cf0ed417c8fd68530f4ab2"
registries = "General"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.1"

[[deps.Latexify]]
deps = ["Format", "Ghostscript_jll", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "df7566479bd64f20bd16b09960145e70160ffb3b"
registries = "General"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.12"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"
    TectonicExt = "tectonic_jll"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"
    tectonic_jll = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "1.0.0"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "Zstd_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.18.0+1"

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "PCRE2_jll", "Zlib_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.1+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl", "OpenSSL_jll", "Zlib_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.103+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c8da7e6a91781c41a863611c7e966098d783c57a"
registries = "General"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.4.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
registries = "General"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
registries = "General"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "cc3ad4faf30015a3e8094c9b5b7f19e85bdf2386"
registries = "General"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.42.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "aebd334d06cee9f24cea70bd19a39749daf73881"
registries = "General"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.3+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d620582b1f0cbe2c72dd1d5bd195a9ce73370ab1"
registries = "General"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.42.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.13.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "bba2d9aa057d8f126415de240573e86a8f39d2a1"
registries = "General"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "1.0.1"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
registries = "General"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
registries = "General"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.Measures]]
git-tree-sha1 = "b513cedd20d9c914783d8ad83d08120702bf2c77"
registries = "General"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.3"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
registries = "General"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2026.8.13"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "dbd2e8cd2c1c27f0b584f6661b4309609c5a685e"
registries = "General"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6aa4566bb7ae78498a5e68943863fa8b5231b59"
registries = "General"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.6+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.30+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e2bb57a313a74b8104064b7efd01406c0a50d2ff"
registries = "General"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.6.1+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05f45c2e0de6259db764adbfd2f1dc6d3f8de13c"
registries = "General"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "2.0.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.46.0+0"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1912a9f1b9ca55005b03ba075f8e19993583e237"
registries = "General"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.58.2+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools"]
git-tree-sha1 = "663e8b48b789916221e0765393b289ca6c88f24e"
registries = "General"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "3.0.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "e4a6721aa89e62e5d4217c0b21bd714263779dda"
registries = "General"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.46.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "Zstd_jll", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.13.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "41031ef3a1be6f5bbbf3e8073f210556daeae5ca"
registries = "General"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.3.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Reexport", "Statistics"]
git-tree-sha1 = "f20e945b895d2009c6c28d8bbf40a5cd846f7c2f"
registries = "General"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.5.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "PrecompileTools", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "TOML", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "83bd514e8ff16b5858ac54c53fa0bcf6002a3b00"
registries = "General"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.41.7"

    [deps.Plots.extensions]
    FileIOExt = "FileIO"
    GeometryBasicsExt = "GeometryBasics"
    IJuliaExt = "IJulia"
    ImageInTerminalExt = "ImageInTerminal"
    UnitfulExt = "Unitful"

    [deps.Plots.weakdeps]
    FileIO = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
    GeometryBasics = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
    IJulia = "7073ff75-c697-5162-941a-fcdaad2a7d2a"
    ImageInTerminal = "d8c32880-2388-543b-8c61-d9f865259254"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
registries = "General"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
registries = "General"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "5005266de4bfe50e53ff44a5cb5c540b6e47a254"
registries = "General"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.6.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
registries = "General"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.Qt6Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Vulkan_Loader_jll", "Xorg_libSM_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_cursor_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "libinput_jll", "xkbcommon_jll"]
git-tree-sha1 = "144895f6166994730ee7ff8113b981fc360638f1"
registries = "General"
uuid = "c0090381-4147-56d7-9ebc-da0b1113ec56"
version = "6.10.2+2"

[[deps.Qt6Declarative_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6ShaderTools_jll", "Qt6Svg_jll"]
git-tree-sha1 = "159d253ab126d5b29230cf53521899bea4ef4648"
registries = "General"
uuid = "629bc702-f1f5-5709-abd5-49b8460ea067"
version = "6.10.2+2"

[[deps.Qt6ShaderTools_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "4d85eedf69d875982c46643f6b4f66919d7e157b"
registries = "General"
uuid = "ce943373-25bb-56aa-8eca-768745ed7b5a"
version = "6.10.2+1"

[[deps.Qt6Svg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll"]
git-tree-sha1 = "81587ff5ff25a4e1115ce191e36285ede0334c9d"
registries = "General"
uuid = "6de9746b-f93d-5813-b365-ba18ad4a9cf3"
version = "6.10.2+0"

[[deps.Qt6Wayland_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Qt6Base_jll", "Qt6Declarative_jll"]
git-tree-sha1 = "672c938b4b4e3e0169a07a5f227029d4905456f2"
registries = "General"
uuid = "e99dba38-086e-5de3-a5b1-6e4c66e897c3"
version = "6.10.2+1"

[[deps.REPL]]
deps = ["Base64", "Dates", "FileWatching", "InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
registries = "General"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "PrecompileTools", "RecipesBase"]
git-tree-sha1 = "45cf9fd0ca5839d06ef333c8201714e888486342"
registries = "General"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
registries = "General"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
registries = "General"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
registries = "General"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "1.0.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
registries = "General"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Showoff]]
deps = ["Dates"]
git-tree-sha1 = "8238217340ad0aaabe11afe39c1098b5bc9f4c8e"
registries = "General"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.1.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "13cd91cc9be159e3f4d95b857fa2aa383b53772a"
registries = "General"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.3"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.13.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "e2b53ce13a53367e96601081e33d34746b571bad"
registries = "General"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.5"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
registries = "General"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "adb9da019510162e67a4493fc235c23203d8b09e"
registries = "General"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.13"

[[deps.StructUtils]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "b814d5005d6a529d740ffe06f8a86396f6501138"
registries = "General"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.9.2"

    [deps.StructUtils.extensions]
    StructUtilsLazilyInitializedFieldsExt = ["LazilyInitializedFields"]
    StructUtilsMeasurementsExt = ["Measurements"]
    StructUtilsStaticArraysCoreExt = ["StaticArraysCore"]
    StructUtilsTablesExt = ["Tables"]

    [deps.StructUtils.weakdeps]
    LazilyInitializedFields = "0e77f7df-68c5-4e49-93ce-4cd80f5598bf"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.10.1+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
registries = "General"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
registries = "General"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "908fec9df6c5de98548ead82a468c95ccf6cd263"
registries = "General"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.7.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
registries = "General"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
registries = "General"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vulkan_Loader_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Wayland_jll", "Xorg_libX11_jll", "Xorg_libXrandr_jll", "xkbcommon_jll"]
git-tree-sha1 = "2f0486047a07670caad3a81a075d2e518acc5c59"
registries = "General"
uuid = "a44049a8-05dd-5a78-86c9-5fde0876e88c"
version = "1.3.243+0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "96478df35bbc2f3e1e791bc7a3d0eeee559e60e9"
registries = "General"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.24.0+0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e52eca002a11c30a858185efdfb15311e1c7a6bf"
registries = "General"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.4+0"

[[deps.Xorg_libICE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a3ea76ee3f4facd7a64684f9af25310825ee3668"
registries = "General"
uuid = "f67eecfb-183a-506d-b269-f58e52b52d7c"
version = "1.1.2+0"

[[deps.Xorg_libSM_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libICE_jll"]
git-tree-sha1 = "9c7ad99c629a44f81e7799eb05ec2746abb5d588"
registries = "General"
uuid = "c834827a-8449-5923-a945-d239c165b7dd"
version = "1.2.6+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "808090ede1d41644447dd5cbafced4731c56bd2f"
registries = "General"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.13+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
registries = "General"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "6c74ca84bbabc18c4547014765d194ff0b4dc9da"
registries = "General"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.4+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
registries = "General"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "1a4a26870bf1e5d26cd585e38038d399d7e65706"
registries = "General"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.8+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "75e00946e43621e09d431d9b95818ee751e6b2ef"
registries = "General"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.2+0"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "dcb316b3ce0941f195537dda56bea4517fcd3ff5"
registries = "General"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.8.4+0"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll"]
git-tree-sha1 = "0ba01bc7396896a4ace8aab67db31403c71628f4"
registries = "General"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.7+0"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "6c174ef70c96c76f4c3f4d3cfbe09d018bcd1b53"
registries = "General"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.6+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
registries = "General"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
registries = "General"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
registries = "General"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "ed756a03e95fff88d8f738ebc2849431bdd4fd1a"
registries = "General"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.2.0+0"

[[deps.Xorg_xcb_util_cursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_jll", "Xorg_xcb_util_renderutil_jll"]
git-tree-sha1 = "9750dc53819eba4e9a20be42349a6d3b86c7cdf8"
registries = "General"
uuid = "e920d4aa-a673-5f3a-b3d7-f755a4d47c43"
version = "0.1.6+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_jll"]
git-tree-sha1 = "f4fc02e384b74418679983a97385644b67e1263b"
registries = "General"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.1+0"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll"]
git-tree-sha1 = "68da27247e7d8d8dafd1fcf0c3654ad6506f5f97"
registries = "General"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.1+0"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_jll"]
git-tree-sha1 = "44ec54b0e2acd408b0fb361e1e9244c60c9c3dd4"
registries = "General"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.1+0"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_jll"]
git-tree-sha1 = "5b0263b6d080716a02544c55fdff2c8d7f9a16a0"
registries = "General"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.10+0"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xcb_util_jll"]
git-tree-sha1 = "f233c83cad1fa0e70b7771e0e21b061a116f2763"
registries = "General"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.2+0"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "801a858fc9fb90c11ffddee1801bb06a738bda9b"
registries = "General"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.7+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "2e59214e017a55cb87474a00fa76035c82ac0e17"
registries = "General"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.47.0+2"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
registries = "General"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.Zstd_jll]]
deps = ["CompilerSupportLibraries_jll", "Libdl"]
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.eudev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c3b0e6196d50eab0c5ed34021aaa0bb463489510"
registries = "General"
uuid = "35ca27e7-8b34-5b7f-bca9-bdc33f59eb06"
version = "3.2.14+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6a34e0e0960190ac2a4363a1bd003504772d631"
registries = "General"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.61.1+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ef17c47d22224aaecc76e597ab21a072e025cf7b"
registries = "General"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.14.1+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "cb007192783c56d8249db4cf0e3495001edfe414"
registries = "General"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.17.5+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
registries = "General"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libdrm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "28e57478e8a160d346a19c28b3fffb9273bcc9c2"
registries = "General"
uuid = "8e53e030-5e6c-5a89-a30b-be5b7263a166"
version = "2.4.134+0"

[[deps.libevdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "56d643b57b188d30cccc25e331d416d3d358e557"
registries = "General"
uuid = "2db6ffa8-e38f-5e21-84af-90c45d0032cc"
version = "1.13.4+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "646634dd19587a56ee2f1199563ec056c5f228df"
registries = "General"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.4+0"

[[deps.libinput_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "eudev_jll", "libevdev_jll", "mtdev_jll"]
git-tree-sha1 = "91d05d7f4a9f67205bd6cf395e488009fe85b499"
registries = "General"
uuid = "36db933b-70db-51c0-b978-0f229ee0e533"
version = "1.28.1+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e51150d5ab85cee6fc36726850f0e627ad2e4aba"
registries = "General"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.58+0"

[[deps.libva_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll", "Xorg_libXfixes_jll", "libdrm_jll"]
git-tree-sha1 = "7dbf96baae3310fe2fa0df0ccbb3c6288d5816c9"
registries = "General"
uuid = "9a156e7d-b971-5f62-b2c9-67348b8fb97c"
version = "2.23.0+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll"]
git-tree-sha1 = "11e1772e7f3cc987e9d3de991dd4f6b2602663a5"
registries = "General"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.8+0"

[[deps.mtdev_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b4d631fd51f2e9cdd93724ae25b2efc198b059b1"
registries = "General"
uuid = "009596ad-96f7-51b1-9f1b-5ce2d5e8a71e"
version = "1.1.7+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.67.1+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.8.2+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "14cc7083fc6dff3cc44f2bc435ee96d06ed79aa7"
registries = "General"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "10164.0.1+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e7b67590c14d487e734dcb925924c5dc43ec85f3"
registries = "General"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "4.1.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "a1fc6507a40bf504527d0d4067d718f8e179b2b8"
registries = "General"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.13.0+0"

[registries.General]
url = "https://github.com/JuliaRegistries/General.git"
uuid = "23338594-aafe-5451-b93e-139f81909106"
"""

# ╔═╡ Cell order:
# ╟─0c4dee43-bb7e-423b-81ba-c8aa539f242d
# ╟─f5ee528b-8d13-4299-87be-5075e4c71eef
# ╟─8fad88fb-5305-4842-bbe6-7be55fc2eec2
# ╟─f3617209-2050-4d68-a50f-b6a2e648ee4d
# ╟─ae7189ca-3ec7-4212-ad17-51f5f136845e
# ╟─90e4a4b7-bd29-4aa0-a5ff-7052703e6565
# ╟─ae0ef280-8e01-4b6d-9afe-e0bd0699edc0
# ╟─f3fc95c1-4dbe-4ece-aa9e-fab938c1f71f
# ╟─f1c52e68-f0b7-46fd-a37e-ddcdf3ad91f7
# ╟─27f9ff62-0a48-4461-ab70-3a8c294357a1
# ╟─bf8eb4ef-21b4-4b5a-b27a-c2f3cb262b0f
# ╟─97616cca-e77f-466e-baaa-b8457e41cdb2
# ╟─9e2344b2-9b5a-4dd3-bb3e-09aacb1d8197
# ╟─c13d737a-782c-4eaf-8e37-562a51057b95
# ╟─0bbd1a4c-9fe1-485a-9a82-e2360ff5e8e2
# ╟─1b1dd69e-2cc4-470f-b2ce-d8a0108a55e6
# ╟─db67f3eb-c8a1-444a-a91c-b87b06395166
# ╟─8977e6bb-a296-4962-80e8-b9d20a012717
# ╟─daf9b087-7416-45e2-93ac-28a8889a0151
# ╟─3e6f10db-06c4-4f3d-aa2a-5ecce2adca82
# ╟─4763b8d8-6ca9-4971-ab27-f9509440b3ec
# ╟─75336650-f6d6-467c-a04a-1402a1b73c8b
# ╟─abc10e03-1cd6-4aea-9244-c967fcbff5ee
# ╟─04ea6b80-5955-4187-9c8f-9f2ccceedcf3
# ╟─6f24661c-5c39-4dba-8596-4aa4cccdabb1
# ╟─0c89915c-ca15-4ecf-a282-5d58ebf172e8
# ╠═5808801f-72b0-4af5-a043-c80e4bd0491d
# ╠═92e9a545-44a1-46f4-b71c-5e3c684c3e64
# ╠═7643351c-00e4-468e-83d7-688349b39d45
# ╟─bff0eeab-42c9-4d1f-9001-420785eb06f2
# ╠═b16ac844-9d42-46cb-8993-1bb560189071
# ╠═4ea93b0b-1540-4ab1-8531-7a363cd9fbec
# ╟─3c90efee-dd22-4cb3-ae2d-053ace71ca89
# ╠═a94ee15c-baea-449d-aae1-bc606ff41fa7
# ╟─a7e55021-452f-4fd0-9a2c-24de229a22a2
# ╟─76ec24ab-8c0f-410e-9e6b-5430eaec79da
# ╟─02306a9a-075a-4904-953f-7eb13af97d37
# ╟─1c05cb1e-c877-492c-9cca-3f8e74e6602c
# ╟─c65a23ac-d57d-462e-9f6f-ac78e0c91255
# ╟─8d8ce4a9-b550-4a25-959c-f1c35aed69bb
# ╠═44dfb409-2831-4890-b20c-c922ef1e35b2
# ╟─df57d93e-ce36-4035-a66e-59338d233ed7
# ╟─288d7d1f-94e4-48c7-a9b1-24aff2ec135f
# ╠═352b667b-c6e5-433b-b8af-8bbd877068a6
# ╟─5ee1bc72-8e41-4a88-9cea-1c2a071ade69
# ╠═d1b29873-9a3c-4f5e-b5e2-5b0f489f9743
# ╟─f5fe3fb6-c7ac-4afe-94f3-0531b68fa39d
# ╟─eb3a9365-0a0f-44bf-8c7b-e7f2cccaf8e4
# ╟─772829bf-bbd2-4367-aa78-654fe444797e
# ╟─23c6b0d9-b90d-46f4-af19-4cebcd73b881
# ╟─02e42ab3-8453-432a-b00b-b5b4b836c700
# ╟─30cab3aa-e028-42cf-87d9-fa5343daf78c
# ╟─9f52e318-bae3-44a3-9150-9b95b02810b2
# ╟─0071601c-ecad-4c34-ba46-39524b6cdc59
# ╠═5c79e07c-bb45-4a33-915d-bc3649d80b99
# ╟─81e22708-815e-4dcb-8d59-40fe63e92c56
# ╟─2a6dc541-3952-4452-8c91-169d1c412d50
# ╠═478722b9-719c-4b96-96f5-6cfc3923d490
# ╟─737d096e-5b64-4335-9c9b-de8b5305a026
# ╟─67ace9db-0fff-4a92-9e90-85607891b010
# ╟─56244d20-0f48-43e9-9b11-7287494105d8
# ╟─8ed4ab0d-b978-4be7-bbe6-05d336012a94
# ╟─489234d1-c799-47c2-a662-d7f3de00bd91
# ╟─bd18d7dc-eade-4aee-8a3d-060181fbb996
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
