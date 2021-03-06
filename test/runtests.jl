using VisualEFM
using Statistics
using Test

@testset "VisualEFM.jl" begin

    f = "test_figures/".*["rpm000.jpg", "rpm150.jpg", "rpm175.jpg", "rpm225.jpg"]
    im_original = read_image.(f, roi=[500:2050,:])
    mask = binarymask("test_figures/teste_mascara.png")
    im = read_image.(f, roi=[500:2050,:], mask=mask)
    
    @testset "Common functions" begin
        @test_throws MethodError read_image(f)
        @test length(im_original) == 4
        @test size(im_original[1]) == (1551, 1456)
        @test typeof(mask) == BitArray{2}
        @test mask[1:10,1:10] == fill(false, (10,10))
        @test size(im[1]) == (1551, 1456)
        @test length(im) == 4
    end

    _,mo = erosion_one(im_original[3], im_original[1], showPlot=false)
    _,m = erosion_one(im[3], im[1], showPlot=false)
    a,_ = erosion_colormap(im_original, [150,175,225], showPlot=false)
    b,_ = erosion_colormap(im, [150,175,225], showPlot=false)

    @testset "Sand erosion" begin
        @test count(mo) > 231400 & count(mo) < 231800
        @test count(m) > 102620 & count(m) < 102820 
        @test_throws DimensionMismatch erosion_anim("test.gif",im_original[2:4], im_original[1:2])  
        @test_throws DimensionMismatch erosion_colormap(im_original, [150,175])
        @test_throws DimensionMismatch erosion_colormap(im, [150,175])
        @test maximum(x->isnan(x) ? -Inf : x, a) == 225
        @test maximum(x->isnan(x) ? -Inf : x, b) == 225
        @test minimum(x->isnan(x) ? Inf : x, a) == 150      
        @test minimum(x->isnan(x) ? Inf : x, b) == 150
    end

    f_smoke = "test_figures/".*["frame1.png", "frame2.png", "frame3.png"]
    im_smoke = read_image.(f_smoke)
    s_all,s_m = smoke_statsmap(mean, im_smoke, nothing, showPlot=false)
    _,s_sd = smoke_statsmap(std, im_smoke, nothing, showPlot=false)

    @testset "Smoke" begin
        @test_throws MethodError smoke_anim("as.gif", im_smoke, im_smoke)
        @test_throws MethodError smoke_statsmap(mean, im_smoke, im_smoke)
        @test s_m[250,300] ≈ (s_all[1][250,300]+s_all[2][250,300]+s_all[3][250,300])/3
        @test s_m[250,300] ≈ mean([s_all[1][250,300],s_all[2][250,300],s_all[3][250,300]])
        @test s_sd[250,300] ≈ std([s_all[1][250,300],s_all[2][250,300],s_all[3][250,300]])
        @test s_m[250,500] ≈ mean([s_all[1][250,500],s_all[2][250,500],s_all[3][250,500]])
        @test s_sd[250,500] ≈ std([s_all[1][250,500],s_all[2][250,500],s_all[3][250,500]])
    end

end
