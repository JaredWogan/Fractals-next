from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from math import log
from typing import Callable, Dict, Optional, Tuple, Union

import matplotlib.pyplot as plt
import numpy as np
from IPython.display import display
from matplotlib.cm import get_cmap
from PIL import Image
from tqdm.notebook import tqdm


@dataclass
class Fractal:
    func: Callable[[complex, Dict[int, complex], int, int | float | complex], complex]
    param: int | float | complex = 0
    div: float = 10
    max_iters: int = 300
    coord_z0: bool = True

    def f(
        self: Fractal, 
        z: complex, 
        f_cache: Dict[int, complex], 
        iter: int, 
        param: int | float | complex
    ):
        try:
            return self.func(z, f_cache, iter, param)
        except (OverflowError, ZeroDivisionError):
            return self.div + 1

    def __contains__(
        self: Fractal,
        z: complex
    ) -> bool:
        return self.stability(z) == 1

    def stability(
        self: Fractal,
        z: complex,
        smooth: bool=False,
        clamp: bool=True
    ) -> float:
        value = self.escape_count(z, smooth) / self.max_iters
        return max(0, min(value, 1)) if clamp else value

    def escape_count(
        self: Fractal,
        z: complex,
        smooth: bool=False
    ) -> int | float:
        f_cache = defaultdict(lambda: 0)
        if self.coord_z0:
            f_cache[0] = z
        else:
            f_cache[0] = self.param
        for iter in range(1, self.max_iters):
            if not iter in f_cache:
                f_cache[iter] = self.f(z, f_cache, iter, self.param)
            f = f_cache[iter]
            if abs(f) > self.div:
                if smooth:
                    return iter + 1 - log(log(abs(f))) / log(2)
                return iter
        return self.max_iters

@dataclass
class Viewport:
    image: Image.Image
    xcenter: float = 0.0
    ycenter: float = 0.0
    xrange: float = 1.5
    yrange: float = 1.5
    zoom: float = 1.0

    def __iter__(self):
        for y in range(self.image.height):
            for x in range(self.image.width):
                yield Pixel(self, x, y)

@dataclass
class Pixel:
    viewport: Viewport
    x: int
    y: int

    @property
    def color(self: Pixel):
        return self.viewport.image.getpixel((self.x, self.y))

    @color.setter
    def color(self: Pixel, value: float | Tuple[int, int, int]):
        self.viewport.image.putpixel((self.x, self.y), value)

    def __complex__(self: Pixel):
        w = self.viewport.image.width
        h = self.viewport.image.height
        zoom = self.viewport.zoom
        xcenter = self.viewport.xcenter
        ycenter = self.viewport.ycenter
        xrange = self.viewport.xrange
        yrange = self.viewport.yrange
        return complex(
            xrange*(self.x - w/2)/(0.5*zoom*w) + xcenter,
            yrange*(self.y - h/2)/(0.5*zoom*h) - ycenter
        )


def gen_fractal(
    func: Callable[[complex, Dict[int, complex], int, Union[int, float, complex]], complex],
    param: Union[int, float, complex] = 0,
    savedir: Optional[str] = None,
    w: int = 1920,
    h: int = 1080,
    xrange: float = 1.5,
    yrange: float = 1.5,
    xcenter: float = 0,
    ycenter: float = 0,
    zoom: float = 1,
    div: float = 1000,
    max_iters: int = 20,
    coord_z0: bool = True,
    cmap: str = "twilight",
    invert_cmap: bool = False
) -> None:
    # Configure the file name to save
    date = datetime.now().strftime(r"%Y-%m-%d at %H-%M-%S")
    if not savedir:
        savename = f"Fractal - {func.__name__} - {date}.png"
    else:
        savename = savedir+f"\\Fractal - {func.__name__} - {date}.png"
    
    # Create a blank image
    image = Image.new(mode="RGB", size=(w, h))
    
    # Create a fractal object
    fractal = Fractal(
        func=func,
        param=param,
        div=div,
        max_iters=max_iters,
        coord_z0=coord_z0
    )
    
    # Configure the viewport
    viewport = Viewport(
        image,
        xrange=xrange,
        yrange=yrange,
        xcenter=xcenter,
        ycenter=ycenter,
        zoom=zoom
    )
    
    # Get the colourmap
    colourmap = [
        tuple(int(channel * 255) for channel in get_cmap(cmap)(i if not invert_cmap else 1 - i)) for i in np.linspace(0, 1, 256)
    ]
    
    # Paint the fractal
    for pixel in tqdm(
        viewport,
        total=w*h,
        unit="pixels",
        desc="Generating Fractal"
    ):
        stability = fractal.stability(complex(pixel), smooth=True)
        index = int(min(stability * len(colourmap), len(colourmap) - 1))
        pixel.color = colourmap[index % len(colourmap)]
        
    # Save the image
    image.convert("RGB").save(savename)
    display(Image.open(savename))


def get_cmaps():
    cmaps = [('Perceptually Uniform Sequential', [
            'viridis', 'plasma', 'inferno', 'magma', 'cividis']),
         ('Sequential', [
            'Greys', 'Purples', 'Blues', 'Greens', 'Oranges', 'Reds',
            'YlOrBr', 'YlOrRd', 'OrRd', 'PuRd', 'RdPu', 'BuPu',
            'GnBu', 'PuBu', 'YlGnBu', 'PuBuGn', 'BuGn', 'YlGn']),
         ('Sequential (2)', [
            'binary', 'gist_yarg', 'gist_gray', 'gray', 'bone', 'pink',
            'spring', 'summer', 'autumn', 'winter', 'cool', 'Wistia',
            'hot', 'afmhot', 'gist_heat', 'copper']),
         ('Diverging', [
            'PiYG', 'PRGn', 'BrBG', 'PuOr', 'RdGy', 'RdBu',
            'RdYlBu', 'RdYlGn', 'Spectral', 'coolwarm', 'bwr', 'seismic']),
         ('Cyclic', ['twilight', 'twilight_shifted', 'hsv']),
         ('Qualitative', [
            'Pastel1', 'Pastel2', 'Paired', 'Accent',
            'Dark2', 'Set1', 'Set2', 'Set3',
            'tab10', 'tab20', 'tab20b', 'tab20c']),
         ('Miscellaneous', [
            'flag', 'prism', 'ocean', 'gist_earth', 'terrain', 'gist_stern',
            'gnuplot', 'gnuplot2', 'CMRmap', 'cubehelix', 'brg',
            'gist_rainbow', 'rainbow', 'jet', 'turbo', 'nipy_spectral',
            'gist_ncar'])]


    gradient = np.linspace(0, 1, 256)
    gradient = np.vstack((gradient, gradient))


    def plot_color_gradients(cmap_category, cmap_list):
        # Create figure and adjust figure height to number of colormaps
        nrows = len(cmap_list)
        figh = 0.35 + 0.15 + (nrows + (nrows-1)*0.1)*0.22
        fig, axs = plt.subplots(nrows=nrows, figsize=(6.4, figh))
        fig.subplots_adjust(top=1-.35/figh, bottom=.15/figh, left=0.2, right=0.99)

        axs[0].set_title(cmap_category + ' colormaps', fontsize=14)

        for ax, cmap_name in zip(axs, cmap_list):
            ax.imshow(gradient, aspect='auto', cmap=cmap_name)
            ax.text(-.01, .5, cmap_name, va='center', ha='right', fontsize=10,
                    transform=ax.transAxes)

        # Turn off *all* ticks & spines, not just the ones with colormaps.
        for ax in axs:
            ax.set_axis_off()

    for cmap_category, cmap_list in cmaps:
        plot_color_gradients(cmap_category, cmap_list)

    plt.show()
