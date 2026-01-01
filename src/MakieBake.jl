module MakieBake

using AccessorsExtra: @o, barebones_string, concat, setall
using MakieExtra
using JSON3

export bare_images, bake_html, @o


function bake_images((obs, optic_vals); blocks, outdir)
    baseobsval = obs[]
    optics = first.(optic_vals)
    olabels = barebones_string.(optics)

    # Compute initial colorbuffers to get baseline sizes
    initial_buffers = [colorbuffer(block) for block in blocks]
    block_sizes = [size(buf) for buf in initial_buffers]

    # Build block info
    blocks_info = [Dict(:size => Dict(:width => sz[1], :height => sz[2])) for sz in block_sizes]

    # Build optics info (names + value ranges for future sliders)
    optics_info = [Dict(:name => olabels[i], :values => collect(last(optic_vals[i]))) for i in eachindex(optic_vals)]

    pardicts = []
    for (i, curvals) in enumerate(Iterators.product(last.(optic_vals)...))
        push!(pardicts, Dict(olabels .=> curvals))

        curobsval = setall(baseobsval, concat(optics...), curvals)
        obs[] = curobsval

        for (iblock, block) in enumerate(blocks)
            buf = colorbuffer(block)
            # Verify size consistency
            if size(buf) != block_sizes[iblock]
                @warn "Block $iblock colorbuffer size changed: expected $(block_sizes[iblock]), got $(size(buf))"
            end
            outpath = joinpath(outdir, "block_$iblock", "$i.png")
            Makie.save(outpath, buf)
        end
    end

    # Save metadata JSON
    metadata = Dict(
        :snapshots => pardicts,
        :blocks => blocks_info,
        :controls => optics_info,
    )
    open(joinpath(outdir, "metadata.json"), "w") do io
        JSON3.pretty(io, metadata)
    end
end

function bake_html((obs, optic_vals); blocks, outdir)
    # Generate images and metadata
    bake_images((obs, optic_vals); blocks, outdir)

    # Read the generated metadata
    metadata_json = read(joinpath(outdir, "metadata.json"), String)

    # Inject metadata into HTML template
    VIEWER_TEMPLATE = read(joinpath(@__DIR__, "..", "spa", "index.html"), String)
    html = replace(VIEWER_TEMPLATE, "\"__DATA_PLACEHOLDER__\"" => metadata_json)

    # Write index.html
    write(joinpath(outdir, "index.html"), html)

    # Remove standalone metadata.json (now embedded in HTML)
    rm(joinpath(outdir, "metadata.json"))

    return outdir
end

end
