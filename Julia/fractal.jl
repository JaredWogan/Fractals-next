using Distributed
using ArgParse
using ProgressMeter
using Colors
using Images
using ImageInTerminal
@everywhere using DataStructures

@everywhere include("./function.jl")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--w"
            help = "Width of the image"
            arg_type = Int
            default = 1920
        "--h"
            help = "Height of the image"
            arg_type = Int
            default = 1080
        "--x"
            help = "Center X coordinate of the image"
            arg_type = Float64
            default = 0.0
        "--y"
            help = "Center Y coordinate of the image"
            arg_type = Float64
            default = 0.0
        "--xrange"
            help = "Range of the X coordinate"
            arg_type = Float64
            default = 1.5
        "--yrange"
            help = "Range of the Y coordinate"
            arg_type = Float64
            default = 1.0
        "--zoom"
            help = "Zoom level"
            arg_type = Float64
            default = 1.0
        "--maxiters"
            help = "Maximum number of iterations to determine divergence / convergence"
            arg_type = Int
            default = 1000
        "--preal"
            help = "Real part of the added constant"
            arg_type = Float64
            default = 0.0
        "--pimag"
            help = "Imaginary part of the added constant"
            arg_type = Float64
            default = 0.0
        "--d"
            help = "Divergence condition"
            arg_type = Float64
            default = 10.0
        "--c"
            help = "Convergence condition"
            arg_type = Float64
            default = 10^(-5)
        "--coordz0"
            help = "Z coordinate is taken as z0 for iterative fractals"
            action = :store_true
        "--k"
            help = "K period index"
            arg_type = Int
            default = 2
        "--n"
            help = "Number of regions to divide canvas into"
            arg_type = Int
            default = 2
    end

    return parse_args(s)
end

@everywhere function pixel_to_coord(i, j)
    return complex(
        2*(i / w - 0.5) * (range_x / zoom) + move_x,
        2*(j / h - 0.5) * (-range_y / zoom) + move_y
    )
end

@everywhere function process_pixel((i, j))
    z = pixel_to_coord(i, j)
    if coord_z0
        z_cache = DefaultDict(0, 0 => z)
    else
        z_cache = DefaultDict(0, 0 => param)
    end
    # Check for divergence
    for iters=1:max_iters
        if !haskey(z_cache, iters)
            z_cache[iters] = f(z, iters, z_cache, param)
        end
        z = z_cache[iters]
        if abs(z) > divergence
            return ((i, j), iters, 1)
        end
    end
    # The above loop didn't return, so we reached the iteration limit
    # Now we check for convergence
    # Check for convergence
    for iters=0:(max_iters-k)
        z2 = z_cache[iters + k]
        z1 = z_cache[iters]
        if abs(z2 - z1) < convergence
            return ((i, j), iters, 2)
        end
    end
    return ((i, j), max_iters, 3)
end

function main()
    parsed_args = parse_commandline()

    @everywhere w, h = $parsed_args["w"], $parsed_args["h"]
    @everywhere move_x, move_y = $parsed_args["x"], $parsed_args["y"]
    @everywhere range_x, range_y = $parsed_args["xrange"], $parsed_args["yrange"]
    @everywhere zoom = $parsed_args["zoom"]
    @everywhere param = complex($parsed_args["preal"], $parsed_args["pimag"])
    @everywhere max_iters, divergence = $parsed_args["maxiters"], $parsed_args["d"]
    @everywhere coord_z0 = $parsed_args["coordz0"]
    @everywhere k, convergence = $parsed_args["k"], $parsed_args["c"]
    @everywhere n = $parsed_args["n"]

    for (key, arg) in parsed_args
        println("$key => $arg")
    end

    ij_grid = [(i, j) for i in 1:w for j in 1:h]

    results = fetch(@showprogress "Generating Fractal..." pmap(process_pixel, ij_grid))

    pixels = colour_fractal(results, n)

    # min_max_regions = [
    #     (
    #         min_region_1 = minimum(x->x[3] == 1 && x[2], results),
    #         max_region_1 = maximum(x->x[3] == 1 && x[2], results)
    #     ),
    #     (
    #         min_region_2 = minimum(x->x[3] == 2 && x[2], results),
    #         max_region_2 = maximum(x->x[3] == 2 && x[2], results)
    #     ),
    #     (
    #         min_region_3 = minimum(x->x[3] == 3 && x[2], results),
    #         max_region_3 = maximum(x->x[3] == 3 && x[2], results)
    #     )
    # ]

    # pixels = zeros(RGB, h, w)
    # for ((i, j), k, region) in results
    #     pixels[j, i] = colour_map(k, region, min_max_regions)
    # end

    save("fractal.png", pixels)
end

@time main()
display(load("fractal.png"))