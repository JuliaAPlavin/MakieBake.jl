using TestItems
using TestItemRunner
@run_package_tests


@testitem "bake_images" begin
    using MakieBake
    using JSON3
    using CairoMakie

    fig = Figure()
    ax = Axis(fig[1, 1])
    params = Observable((a=1, b=0.5))
    lines!(ax, 1:10, @lift x -> x * $params.a + $params.b)

    outdir = mktempdir()

    MakieBake.bake_images(
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

@testitem "bake_html" begin
    using MakieBake
    using CairoMakie

    fig = Figure()
    ax = Axis(fig[1, 1])
    params = Observable((x=1.0, y=0.5))
    scatter!(ax, @lift [(i + $params.x, i^$params.y) for i in 1:10])

    _,plt = image(fig[1,2][1,1], @lift rand(100,100) .^ $params.x)
    Colorbar(fig[1,2][1,2], plt; label="Random Image")

    # outdir = mktempdir()
    outdir = joinpath(@__DIR__, "tmp")

    bake_html(
        params => (
            (@o _.x) => [0.5, 1.0, 1.5],
            (@o _.y) => [0.1, 0.3, 1, 2],
        );
        blocks=[ax, fig[1,2]],
        outdir=outdir
    )

    # Test index.html and metadata.js exist (metadata.json is converted and removed)
    @test isfile(joinpath(outdir, "index.html"))
    @test !isfile(joinpath(outdir, "metadata.json"))
    @test isfile(joinpath(outdir, "metadata.js"))

    # Test HTML loads metadata.js
    html = read(joinpath(outdir, "index.html"), String)
    @test occursin("metadata.js", html)
    @test occursin("Makie Interactive Viewer", html)

    # Test images exist
    @test isdir(joinpath(outdir, "block_1"))
    @test length(readdir(joinpath(outdir, "block_1"))) == 12
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieBake)

    import CompatHelperLocal as CHL
    CHL.@check()
end
