# MakieBake.jl

Bake Makie plots into lightweight interactive HTML. Most of the interactivity, none of the runtime!

Pre-renders all parameter combinations into static images — no Julia, no server, just a browser.

## Usage

https://github.com/user-attachments/assets/0c663e71-fa5e-49bb-9756-14486ad11c94

```julia
using MakieBake
using CairoMakie

# Create a figure with Observables – your typical interactive Makie plot
fig = Figure()
ax1 = Axis(fig[1, 1]; title="line")
ax2 = Axis(fig[1, 2]; title="scatter")
params = Observable((frequency=2.0, p=1.0))

f(x, frequency, p) = sin(frequency * x) * x^p

lines!(ax1, 0:0.01:2π, (@lift x -> f(x, $params.frequency, $params.p)))
xs = range(0, 2π, 100)
scatter!(ax2, xs, (@lift f.(xs, $params.frequency, $params.p) .+ 0.2 .* randn(100)))

# Export to self-contained HTML
bake_html(
    params => (
        (@o _.frequency) => [1, 2, 3, 4],
        (@o _.p) => [0, 0.2, 0.5, 1],
    );
    blocks=[ax1, ax2],
    outdir="./my_visualization"
)
```

Open `my_visualization/index.html` directly in a browser — no server required.

See [a more involved example](https://plav.in/Synchray/knot_shape/) in the wild.

## How it works

`MakieBake.jl` pre-bakes every state of your interactive plot:

1. Iterating through all parameter combinations
2. Rendering each state as a PNG image
3. Generating an HTML viewer with sliders that swap between pre-rendered images

## Layout

The output uses CSS grid for layout, which can be customized by placing a `layout.js` file in your output directory (see [layout_example.js](_readme_example/layout_example.js)). Options include a custom header, zoom factor, max width, and a grid layout specified via CSS `grid-template-areas` — for example:

```javascript
const LAYOUT = [
    "A A S",   // block A spans two columns, S = sliders
    "B C S"    // blocks B and C below, sliders on the right
];
```

## The `@o` macro

`@o` defines how to access and modify parts of your params:

```julia
@o _.amplitude       # access a field
@o _.nested.field    # access nested field
@o first(_.values)   # apply a function
```

See [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl) for more.
