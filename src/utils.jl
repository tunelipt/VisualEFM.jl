# New color palette
inv_rainbow = [:red,:orange,:yellow,:green,:blue]

# From given color palette gets discrete number of colors
function getcolors(n; palette_name=inv_rainbow, alpha=0.6)
    col = cgrad(palette_name, n, categorical=true, alpha=alpha)
end

# Given a black and white image returns a binary mask
# ---------------------------------------------------------------------------------------------
# maskname: string with the file name
# ---------------------------------------------------------------------------------------------
# returns a binary mask
# ---------------------------------------------------------------------------------------------
function binarymask(maskname::String)
    mask = load(maskname)
    mask = Gray{Float64}.(mask)
    mask = round.(mask)
    mask = Bool.(mask)
end

# Function that can be used to load one or more images (broadcast)
# ---------------------------------------------------------------------------------------------
# fname: file name
# roi: region of interest (if nothing, roi = [:,:])
# mask: provide a mask be aplied to the figure (BitArray{2}). White is the portion to be kept
# ---------------------------------------------------------------------------------------------
# returns the images with with roi and mask applied
# ---------------------------------------------------------------------------------------------
function read_image(fname::String; roi=nothing, mask::Union{BitArray{2}, Nothing}=nothing)
    img = load(fname)

    if !isnothing(mask)	
        mask = .!Bool.(mask)
        img[mask] .= RGBA(1.0,1.0,1.0,0)
    end
    if !isnothing(roi)
    	img = img[roi[1],roi[2]]
    end

    return img
end


# Function to apply a gaussian filter to the images
# ---------------------------------------------------------------------------------------------
# im: original image
# ksize: size of the kernel (Kernel.gaussian)
# ---------------------------------------------------------------------------------------------
# returns blur image
# ---------------------------------------------------------------------------------------------
function apply_gaussian(img; ksize=1)
    k = Kernel.gaussian(ksize)
    blur = imfilter(img, reflect(k)) # apply convolution!0
    return blur
end

# Auxiliary function to apply Gaussian filter and convert to grayscale
# ---------------------------------------------------------------------------------------------
# img: image in Normed RGB
# ksize: size of the kernel (Kernel.gaussian)
# ---------------------------------------------------------------------------------------------
# returns the image filtered and in grayscale
# ---------------------------------------------------------------------------------------------
function gauss_grayscale(img::Array{RGB{Normed{UInt8,8}},2}; ksize=1)
    
    img_blur = apply_gaussian(img, ksize=ksize)
    img_gs = Gray.(img_blur)

    return img_gs

end

# Background subtraction (grayscale)
# ---------------------------------------------------------------------------------------------
# img: image 
# bgimg: background image
# inverse: if false do img-bgimg, if true do bgimg-img
# ---------------------------------------------------------------------------------------------
# returns grayscale image subtracted
# ---------------------------------------------------------------------------------------------
function backsubtraction(img::Array{Gray{Float64},2}, bgimg::Array{Gray{Float64},2}; 
                        inverse=false)

    if inverse
        img_sub = bgimg .- img
    else
        img_sub = img .- bgimg
    end

    return img_sub

end

# Function to get the difference pattern
# ---------------------------------------------------------------------------------------------
# img: image to extract pattern
# bgimg: image to subtract (background subtraction)
# thrfun: threshold algorithm (default Otsu)
# nclose: number of times to apply dilatation followed by erosion (closing)
# inverse: direction of background subtraction (see backSubtraction())
# ---------------------------------------------------------------------------------------------
# returns image difference pattern
# ---------------------------------------------------------------------------------------------
function getdiffpattern(img::Array{RGB{Float64},2},
                    bgimg::Array{RGB{Float64},2};
                    thrfun = Otsu(), nclose=1, inverse=true)

    img_pattern = backsubtraction(Gray.(img), Gray.(bgimg), inverse=inverse)  
    binarize!(img_pattern, thrfun)

    # if nclose is negative or zero, nothing is done!
    if nclose <= 0
        @warn("If nclose is negative or zero, no closing is applied!")
    else
        [dilate!(img_pattern) for _ in 1:nclose]
        [erode!(img_pattern) for _ in 1:nclose]
    end

    return img_pattern

end
