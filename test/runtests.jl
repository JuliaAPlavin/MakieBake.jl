using TestItems
using TestItemRunner
@run_package_tests


@testitem "basic usage" begin    
    precompute_save_images(
        params => (
            (@o _.a + 1) => 1:5,
            (@o _.def.c) => [0.1, 0.3, 1],
        ),
        blocks=[fig[1,1], ax2],
        outdir=joinpath(@__DIR__, "tmp")
    )
end

@testitem "_" begin
    import Aqua
    Aqua.test_all(MakieBake)

    import CompatHelperLocal as CHL
    CHL.@check()
end
