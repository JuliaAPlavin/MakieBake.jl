module MakieBake

using MakieExtra
using JSON3

export precompute_save_images

function precompute_save_images((obs, optic_vals); blocks, outdir)
    baseobsval = obs[]
    optics = first.(optic_vals)
    olabels = AccessorsExtra.barebones_string.(optics)

    # Compute initial colorbuffers to get baseline sizes
    initial_buffers = [colorbuffer(block) for block in blocks]
    block_sizes = [size(buf) for buf in initial_buffers]

    # Build block info
    blocks_info = [Dict(:size => Dict(:width => sz[1], :height => sz[2])) for sz in block_sizes]

    # Build optics info (names + value ranges for future sliders)
    optics_info = [Dict(:name => olabels[i], :values => collect(last(optic_vals[i]))) for i in eachindex(optic_vals)]

    pardicts = []
    for (i, curvals) in enumerate(Iterators.product(last.(optic_vals)...))
        @info "" curvals
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

end
