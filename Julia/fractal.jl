using PyPlot, Colors, DataStructures, Dates, Images


struct Fractal
    func::Function
    param::Union{Int, Float64, Complex}
    div::Union{Int, Float64}
    max_iters::Int
    coord_z0::Bool
end

function f(
    fractal::Fractal,
    z::Complex,
    f_cache::AbstractDict,
    iter::Int,
    param::Union{Int, Float64, Complex}
)
    try
        return fractal.func(z, f_cache, iter, param)
    catch e
        println("Error in f: $e")
        return fractal.div + 1
    end
end

function stability(
    fractal::Fractal,
    z::Complex,
    coord_z0::Bool = false,
    smooth::Bool = false,
    clamp::Bool = true
)
    value = escape_count(fractal, z, coord_z0, smooth) / fractal.max_iters
    return clamp ? max(0, min(1, value)) : value
end

function escape_count(
    fractal::Fractal,
    z::Complex,
    coord_z0::Bool = false,
    smooth::Bool = false
)
    f_cache = DefaultDict(0, coord_z0 ? 0 => z : 0 => fractal.param)
    for iters=1:fractal.max_iters
        if !haskey(f_cache, iters)
            f_cache[iters] = f(fractal, z, f_cache, iters, fractal.param)
        end
        current_f = f_cache[iters]
        if abs(current_f) > fractal.div
            return smooth ? iters + 1 - log(log(abs(current_f))) / log(2) : iters
        end
    end
    return fractal.max_iters
end

struct Viewport
    image::Array{RGB, 2}
    xcenter::Union{Int, Float64}
    ycenter::Union{Int, Float64}
    xrange::Union{Int, Float64}
    yrange::Union{Int, Float64}
    zoom::Union{Int, Float64}
end

function Base.iterate(View::Viewport, state=1)
    h = size(View.image, 1)
    w = size(View.image, 2)
    if state > w * h
        return nothing
    else
        row = Int(((state - 1 - ((state - 1) % w)) / w)) + 1
        col = state - (row - 1) * w
        return (Pixel(View, row, col), state + 1)
    end
end

function Base.length(View::Viewport)
    return size(View.image, 1) * size(View.image, 2)
end

struct Pixel
    viewport::Viewport
    x::Int
    y::Int
end

function coord(
    pixel::Pixel
)
    h = size(pixel.viewport.image, 1)
    w = size(pixel.viewport.image, 2)
    zoom = pixel.viewport.zoom
    xrange = pixel.viewport.xrange
    yrange = pixel.viewport.yrange
    xcenter = pixel.viewport.xcenter
    ycenter = pixel.viewport.ycenter
    value = complex(
        (xrange * ((pixel.x - w/2) / (0.5 * zoom * w)) + xcenter),
        (yrange * ((pixel.y - h/2) / (0.5 * zoom * h)) - ycenter)
    )
    return value
end

function color(
    pixel::Pixel,
    value::RGB
)
    pixel.viewport.image[pixel.y, pixel.x] = value
    return nothing
end

function gen_fractal(;
    func::Function,
    param::Union{Int, Float64, Complex} = 0,
    savedir::Union{Nothing, String} = nothing,
    w::Int = 1920,
    h::Int = 1080,
    xrange::Union{Int, Float64} = 1.5,
    yrange::Union{Int, Float64} = 1.5,
    xcenter::Union{Int, Float64} = 0,
    ycenter::Union{Int, Float64} = 0,
    zoom::Union{Int, Float64} = 1,
    div::Union{Int, Float64} = 1000,
    max_iters::Int = 20,
    coord_z0::Bool = true,
    cmap::String = "twilight",
    invert_cmap::Bool = false
)
    # Configure the file name to save the image to
    date = Dates.format(Dates.now(), "yyyy-mm-dd at HH-MM-SS")
    if savedir === nothing
        savename = "./Fractal - " * date * ".png"
    else
        savename = savedir * "/Fractal - " * date * ".png"
    end

    # Create a blank image
    image = zeros(RGB, h, w)

    # Create a fractal object
    fractal = Fractal(
        func,
        param,
        div,
        max_iters,
        coord_z0
    )

    # Configure the viewport
    viewport = Viewport(
        image,
        xcenter,
        ycenter,
        xrange,
        yrange,
        zoom
    )

    # Get the colourmap
    colourmap = [
        RGB(Tuple(get_cmap(cmap)(invert_cmap ? 1 - i : i)[1:3])...)
        for i in 0:1:256
    ]
   
    # Paint the fractal
    for pixel in viewport
        s = stability(fractal, coord(pixel), coord_z0, true, true)
        index = round(Int, min(s * length(colourmap), length(colourmap) - 1))
        color(pixel, colourmap[(index % length(colourmap)) + 1])
    end

    save(savename, image)
    return image
end
