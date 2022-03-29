# Iterative function to be use
using Colors
using ColorVectorSpace


function f(coord, i, z_cache, p)
    z = z_cache[i - 1]
    # zp = z_cache[i - 2]
    # return 2*z*(1 - zp)
    p = complex(1.18, 0.376)
    return p * (1 - z) * (1 + z) * z
end

colours = [
    (
        RGB(0, 0, 0),
        RGB(1, 1, 1)
    ),
    (
        RGB(1, 0, 0),
        RGB(1, 0, 1)
    ),
    (
        RGB(0, 1, 1),
        RGB(0.2, 1, 0.5)
    )
]

black_white = [RGB(0,0,0), RGB(1,1,1)]

function colour_map(regions)
    pixels = zeros(RGB, h, w)
    for (i, region) in enumerate(regions)
        min_i =  minimum(x->x[2], region)
        max_i =  maximum(x->x[2], region)
        println("In region: ", length(region))
        println("min: ", min_i, " max: ", max_i)
        for pixel in region
            (pixel_i, pixel_j) = pixel[1]
            (c1, c2) = colours[i]
            x = max(min((pixel[2] - min_i)/(max_i - min_i), 1), 0)
            m = mod(pixel[2], 3)
            # pixels[pixel_j, pixel_i] = c1 + (c2 - c1) * x
            pixels[pixel_j, pixel_i] = black_white[i]
        end
    end
    return pixels
end

function colour_fractal(d, n)
    regions = [
        [
            pixel
            for pixel in d
            if mod(pixel[2], n) == i
        ]
        for i = 0:n-1
    ]
    return colour_map(regions)
end

# function colour_map(iters, region, min_max_regions)
#     (min_i, max_i) = min_max_regions[region]
#     region_1 = (
#         RGB(1, 0, 0),
#         RGB(0.25, 0, 1)
#     )
#     region_2 = (
#         RGB(1, 1, 1),
#         RGB(0.1, 1, 0.5)
#     )
#     region_3 = (
#         RGB(0, 0, 1),
#         RGB(1, 1, 1)
#     )
#     x = max(min((iters - min_i)/(max_i - min_i), 1), 0)
#     m = mod(iters, 3)
#     if m == 0
#         c = RGB(0, 0, 0)
#     elseif m == 1
#         c = RGB(1, 1, 1)
#     elseif m == 2
#         c = RGB(0, 0, 1)
#     end
#     # if region == 1
#     #     (c1, c2) = region_1
#     #     c = c1 + (c2 - c1)*x
#     # elseif region == 2
#     #     (c1, c2) = region_2
#     #     c = c1 + (c2 - c1)*x
#     # elseif region == 3
#     #     (c1, c2) = region_3
#     #     c = c1 + (c2 - c1)*x
#     # end
#     return c
# end