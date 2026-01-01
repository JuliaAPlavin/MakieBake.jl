using TestItems
using TestItemRunner
@run_package_tests


@testitem "bake_interactive" begin
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

@testitem "bake_to_html" begin
    using MakieBake
    using CairoMakie

    fig = Figure()
    ax = Axis(fig[1, 1])
    params = Observable((x=1.0,))
    scatter!(ax, [1, 2, 3], [params[].x, 2, 3])

    outdir = mktempdir()

    bake_to_html(
        params => (
            (@o _.x) => [0.5, 1.0, 1.5],
        );
        blocks=[fig],
        outdir=outdir
    )

    # Test index.html exists
    @test isfile(joinpath(outdir, "index.html"))

    # Test metadata.json was removed (embedded in HTML)
    @test !isfile(joinpath(outdir, "metadata.json"))

    # Test HTML contains the data
    html = read(joinpath(outdir, "index.html"), String)
    @test occursin("snapshots", html)
    @test occursin("controls", html)
    @test occursin("Makie Interactive Viewer", html)

    # Test images exist
    @test isdir(joinpath(outdir, "block_1"))
    @test length(readdir(joinpath(outdir, "block_1"))) == 3  # 3 parameter values
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieBake)

    import CompatHelperLocal as CHL
    CHL.@check()
end
