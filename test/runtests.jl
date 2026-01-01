using TestItems
using TestItemRunner
@run_package_tests


@testitem "export smoke test" begin
    using MakieBake
    using JSON3
    using CairoMakie

    fig = Figure()
    ax = Axis(fig[1, 1])
    params = Observable((a=1, b=0.5))
    lines!(ax, 1:10, x -> x * params[].a + params[].b)

    outdir = mktempdir()

    bake_interactive(
        params => (
            (@o _.a) => [1, 2],
            (@o _.b) => [0.1, 0.5],
        );
        blocks=[fig],
        outdir=outdir
    )

    # Test metadata.json exists and is valid
    metadata_path = joinpath(outdir, "metadata.json")
    @test isfile(metadata_path)

    metadata = JSON3.read(read(metadata_path, String))
    @test haskey(metadata, :snapshots)
    @test haskey(metadata, :blocks)
    @test haskey(metadata, :controls)

    # Test correct number of snapshots (2x2 = 4)
    @test length(metadata.snapshots) == 4

    # Test block directory and images exist
    @test isdir(joinpath(outdir, "block_1"))
    @test isfile(joinpath(outdir, "block_1", "1.png"))
    @test filesize(joinpath(outdir, "block_1", "1.png")) > 0
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieBake)

    import CompatHelperLocal as CHL
    CHL.@check()
end
