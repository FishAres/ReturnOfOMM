using DrWatson, Test
@quickactivate "OMM"

include(srcdir("utils", "act_utils.jl"))

@testset "pad_array tests" begin
    @testset "2D array tests" begin
        x = [1 2 3; 4 5 6]
        @test isequal(pad_array(x, (4, 3)), [1 2 3; 4 5 6; NaN NaN NaN; NaN NaN NaN])
        @test isequal(pad_array(x, (2, 4)), [1 2 3 NaN; 4 5 6 NaN])
    end

    @testset "3D array tests" begin
        x = reshape(1:12, (2, 2, 3))
        @test isequal(pad_array(x, (2, 2, 4)), cat(x, fill(NaN, (2, 2, 1)), dims=3))
        @test isequal(pad_array(x, (3, 2, 3)), cat(x, fill(NaN, (1, 2, 3)), dims=1))
    end

    @testset "No padding needed" begin
        x = [1 2 3; 4 5 6]
        @test isequal(pad_array(x, (2, 3)), x)
    end
end


println("Starting tests")
