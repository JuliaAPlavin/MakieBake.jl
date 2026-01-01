module MakieBake

using AccessorsExtra: @o, barebones_string, concat, setall
using MakieExtra
using JSON3
using ProgressMeter

export bake_html, @o


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
    @showprogress for (i, curvals) in collect(enumerate(Iterators.product(last.(optic_vals)...)))
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

    # Save metadata as JSON
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
    # Generate images and metadata.json
    bake_images((obs, optic_vals); blocks, outdir)

    # Convert metadata.json to metadata.js (works from file:// without server)
    metadata_json = read(joinpath(outdir, "metadata.json"), String)
    rm(joinpath(outdir, "metadata.json"))
    write(joinpath(outdir, "metadata.js"), "const METADATA = $metadata_json;")

    # Copy viewer files
    cp(joinpath(@__DIR__, "..", "spa", "index.html"), joinpath(outdir, "index.html"); force=true)
    cp(joinpath(@__DIR__, "..", "spa", "app.js"), joinpath(outdir, "app.js"); force=true)

    return outdir
end

end
