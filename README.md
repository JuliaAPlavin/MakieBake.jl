# MakieBake

Bake Makie plots into lightweight interactive HTML, by pre-rendering across parameter ranges.

## Usage

```julia
using MakieBake
using CairoMakie

# Create a figure with Observables – your typical interactive Makie plot
fig = Figure()
ax = Axis(fig[1, 1])
params = Observable((amplitude=1.0, frequency=2.0))

lines!(ax, 0:0.01:2π, @lift(x -> $params.amplitude * sin($params.frequency * x)))

# Export to self-contained HTML
bake_html(
    params => (
        (@o _.amplitude) => [0.5, 1.0, 1.5],
        (@o _.frequency) => [1, 2, 3, 4],
    );
    blocks=[fig],
    outdir="./my_visualization"
)
```

Open `my_visualization/index.html` directly in a browser — no server required.

## How it works

1. Iterates through all parameter combinations
2. Renders each state as a PNG image
3. Bundles everything into a single HTML file with interactive sliders

## Multiple blocks

Export multiple plot regions independently:

```julia
bake_html(
    params => ((@o _.x) => [1, 2, 3],);
    blocks=[ax1, ax2, fig[3,1]],  # Each gets its own image set
    outdir="./output"
)
```

## Server mode

Sometimes it's more convenient to have metadata as a separate file, not included in the HTML. In that case, use the flex viewer which loads metadata separately (requires HTTP server):

```julia
MakieBake.bake_images(params => ...; blocks=[fig], outdir="./output")
# Then copy spa/index_flex.html to ./output/ and serve with any HTTP server
```

## The `@o` macro

`@o` defines how to access and modify parts of your params:

```julia
@o _.amplitude       # access a field
@o _.nested.field    # access nested field
@o first(_.values)   # apply a function
```

See [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) for more.
