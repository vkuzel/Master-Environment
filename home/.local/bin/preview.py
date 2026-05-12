#!/usr/bin/env python3
import queue
import threading
import tkinter as tk
from dataclasses import dataclass
from math import floor
from pathlib import Path
from queue import Queue
from tkinter import Canvas, Event, PhotoImage
from typing import Dict, Optional, Set

from PIL import Image, ImageTk


@dataclass(frozen=True)
class ImageFile:
    name: str


@dataclass(frozen=True)
class ImageDimensions:
    size: int


@dataclass(frozen=True)
class ImagePosition:
    x: int
    y: int


@dataclass(frozen=True)
class LoadImageRequest:
    image_file: ImageFile
    image_dimensions: ImageDimensions


@dataclass(frozen=True)
class LoadedImage:
    request: LoadImageRequest
    photo_image: PhotoImage


@dataclass(frozen=True)
class Viewport:
    width: int
    height: int


@dataclass
class OverviewImage:
    image_file: ImageFile
    image_position: ImagePosition
    image_dimensions: ImageDimensions
    selected: bool

    def contains_point(self, x: int, y: int) -> bool:
        x1, y1 = self.image_position.x, self.image_position.y
        x2, y2 = x1 + self.image_dimensions.size, y1 + self.image_dimensions.size
        return x1 <= x <= x2 and y1 <= y <= y2


@dataclass
class OverviewRequestedImage(OverviewImage):
    def is_for_loaded_image(self, loaded_image: LoadedImage) -> bool:
        request = loaded_image.request
        return self.image_file == request.image_file and self.image_dimensions == request.image_dimensions


@dataclass
class OverviewLoadedImage(OverviewImage):
    photo_image: PhotoImage


@dataclass(frozen=True)
class OverviewModel:
    images: list[OverviewImage]

    def find_selected_image(self) -> Optional[OverviewImage]:
        for image in self.images:
            if image.selected:
                return image
        else:
            return None

    def create_loaded_image(self, loaded_image: LoadedImage) -> Optional[OverviewLoadedImage]:
        # Loop in a loop can be optimized
        for i in range(0, len(self.images)):
            image = self.images[i]
            if not isinstance(image, OverviewRequestedImage):
                continue
            if not image.is_for_loaded_image(loaded_image):
                continue

            loaded_image = OverviewLoadedImage(
                image_file=image.image_file,
                image_position=image.image_position,
                image_dimensions=image.image_dimensions,
                selected=image.selected,
                photo_image=loaded_image.photo_image,
            )
            self.images[i] = loaded_image
            return loaded_image
        else:
            return None


@dataclass(frozen=True)
class DetailModel:
    image_file: ImageFile
    image_dimensions: ImageDimensions
    photo_image: PhotoImage


class ImageFilesScanner:
    @staticmethod
    def scan() -> list[ImageFile]:
        image_suffixes = {
            ".jpg", ".jpeg", ".png", ".gif", ".bmp",
            ".tiff", ".webp", ".svg", ".ico"
        }

        image_files = []
        for file in Path.cwd().iterdir():
            if not file.is_file() or file.suffix.lower() not in image_suffixes:
                continue
            image_files.append(ImageFile(file.name))

        return image_files


class ImageLoader:
    def __init__(self):
        self._in_queue: Queue[LoadImageRequest] = Queue()
        self._out_queue: Queue[ImageLoader._LoadedRawImage] = Queue()
        ImageLoader._Worker(self._in_queue, self._out_queue).start()

        self._requested_images: Set[LoadImageRequest] = set()
        self._loaded_images: Dict[LoadImageRequest, ImageLoader._LoadedRawImage] = {}
        self._loaded_photo_images: Dict[LoadImageRequest, LoadedImage] = {}

    def request_image(self, request: LoadImageRequest) -> Optional[LoadedImage]:
        if request in self._loaded_photo_images:
            return self._loaded_photo_images[request]
        elif request in self._loaded_images:
            loaded_image = self._loaded_images[request]
            self._out_queue.put(loaded_image)
            return None
        elif request not in self._requested_images:
            self._requested_images.add(request)
            self._in_queue.put(request)
            return None
        else:
            return None

    def cancel(self):
        self._requested_images = set()
        self._loaded_images = {}
        self._loaded_photo_images = {}
        self._clear_queue(self._in_queue)
        self._clear_queue(self._out_queue)

    def poll_loaded_images(self) -> list[LoadedImage]:
        items = []
        while not self._out_queue.empty():
            try:
                loaded_image = self._out_queue.get_nowait()
                self._loaded_images[loaded_image.request] = loaded_image

                photo_image = ImageTk.PhotoImage(loaded_image.image)
                loaded_photo_image = LoadedImage(
                    request=loaded_image.request,
                    photo_image=photo_image,
                )
                self._loaded_photo_images[loaded_image.request] = loaded_photo_image

                items.append(loaded_photo_image)
            except queue.Empty:
                break
        return items

    @staticmethod
    def load_image(image_file: ImageFile, image_dimensions: ImageDimensions) -> ImageTk.PhotoImage:
        image = Image.open(image_file.name)
        image = image.resize((image_dimensions.size, image_dimensions.size))
        return ImageTk.PhotoImage(image)

    @staticmethod
    def _clear_queue(q: Queue):
        try:
            while True:
                q.get_nowait()
        except queue.Empty:
            pass

    @dataclass(frozen=True)
    class _LoadedRawImage:
        request: LoadImageRequest
        image: tk.Image

    class _Worker(threading.Thread):
        def __init__(self, in_queue: Queue[LoadImageRequest], out_queue: Queue['ImageLoader._LoadedRawImage']):
            super().__init__(daemon=True)
            self._in_queue = in_queue
            self._out_queue = out_queue

        def run(self):
            while True:
                request = self._in_queue.get()

                image = Image.open(request.image_file.name)
                image = image.resize((request.image_dimensions.size, request.image_dimensions.size))

                loaded_image = ImageLoader._LoadedRawImage(
                    request=request,
                    image=image,
                )
                self._out_queue.put(loaded_image)


class Renderer:
    def __init__(self, canvas: Canvas):
        self._canvas = canvas

        self._margin = 5

    def viewport(self) -> Viewport:
        return Viewport(
            width=self._canvas.winfo_width(),
            height=self._canvas.winfo_height(),
        )

    def render_overview(self, overview_model: OverviewModel):
        self._canvas.delete("all")

        canvas_height = self._canvas.winfo_height()

        for image in overview_model.images:
            if image.image_position.y + image.image_dimensions.size + 2 * self._margin < 0:
                continue
            if image.image_position.y > canvas_height:
                continue

            self._canvas.create_rectangle(
                image.image_position.x + self._margin,
                image.image_position.y + self._margin,
                image.image_position.x + self._margin + image.image_dimensions.size,
                image.image_position.y + self._margin + image.image_dimensions.size,
                width=2,
                fill="#01302f",
            )

            self._canvas.create_text(
                image.image_position.x + self._margin + image.image_dimensions.size / 2,
                image.image_position.y + self._margin + image.image_dimensions.size / 2,
                text=image.image_file.name,
                anchor="center",
                font=("Arial", 12),
                fill="white",
            )

            if isinstance(image, OverviewLoadedImage):
                self.render_overview_image(image)

            self.render_overview_image_highlight(image)

    def render_overview_image(self, image: OverviewLoadedImage):
        self._canvas.create_image(
            image.image_position.x + self._margin,
            image.image_position.y + self._margin,
            image=image.photo_image,
            anchor="nw"
        )

    def render_overview_image_highlight(self, image: OverviewImage):
        outline = "white" if image.selected else "black"
        self._canvas.create_rectangle(
            image.image_position.x + self._margin,
            image.image_position.y + self._margin,
            image.image_position.x + self._margin + image.image_dimensions.size,
            image.image_position.y + self._margin + image.image_dimensions.size,
            width=2,
            outline=outline,
        )

    def render_detail(self, image: DetailModel):
        self._canvas.delete("all")
        self._canvas.create_image(
            0,
            0,
            image=image.photo_image,
            anchor='nw',
        )


class UI:
    def __init__(self, image_loader: ImageLoader, renderer: Renderer, image_files: list[ImageFile]):
        self._image_loader = image_loader
        self._renderer = renderer
        self._image_files = image_files

        self._first_render = True
        self._scroll_offset = 0
        self._image_size = 100

        self._mouse_x = 0
        self._mouse_y = 0

        self._model = OverviewModel([])
        self._selected_image: Optional[OverviewImage] = None
        self._detail_model: Optional[DetailModel] = None

    def mouse_select(self, event: Event):
        self._mouse_x = event.x
        self._mouse_y = event.y
        if self._selected_image:
            return

        for image in self._model.images:
            if image.selected and not image.contains_point(self._mouse_x, self._mouse_y):
                image.selected = False
                self._renderer.render_overview_image_highlight(image)
            elif not image.selected and image.contains_point(self._mouse_x, self._mouse_y):
                image.selected = True
                self._renderer.render_overview_image_highlight(image)

    def scroll_to_start(self):
        if self._selected_image:
            return

        self._scroll_offset = 0
        self._model = self._create_overview_model()
        self._renderer.render_overview(self._model)

    def scroll(self, event: Event):
        if self._selected_image:
            return

        scroll_speed = 75
        if event.num == 4:
            self._scroll_offset += scroll_speed
        elif event.num == 5:
            self._scroll_offset -= scroll_speed
        self._model = self._create_overview_model()
        self._renderer.render_overview(self._model)

    def zoom(self, event: Event):
        if self._selected_image:
            return

        zoom_speed = 10
        if event.num == 4:
            self._image_size += zoom_speed
        elif event.num == 5:
            self._image_size = max(self._image_size - zoom_speed, 1)
        self._image_loader.cancel()
        self._model = self._create_overview_model()
        self._renderer.render_overview(self._model)

    def toggle_preview(self):
        if self._selected_image:
            self._selected_image = None
        else:
            self._selected_image = self._model.find_selected_image()
        self.initialize()

    def initialize(self):
        if self._selected_image:
            self._detail_model = self._create_detail_model()
            self._renderer.render_detail(self._detail_model)
        else:
            self._model = self._create_overview_model()
            self._renderer.render_overview(self._model)

    def process_loaded_images(self):
        loaded_images = self._image_loader.poll_loaded_images()
        for loaded_image in loaded_images:
            if not self._model:
                continue

            overview_loaded_image = self._model.create_loaded_image(loaded_image)
            if overview_loaded_image:
                self._renderer.render_overview_image(overview_loaded_image)

    def _create_overview_model(self) -> OverviewModel:
        margin = 5
        canvas_width = self._renderer.viewport().width

        if self._first_render:
            self._first_render = False
            image_width = self._image_size + 2 * margin
            line_images_count = floor(canvas_width / image_width)
            unused_margin = canvas_width - image_width * line_images_count
            self._image_size += floor(unused_margin / line_images_count)

        overview_images: list[OverviewImage] = []

        x = 0
        y = self._scroll_offset
        for i in range(0, len(self._image_files)):
            image_file = self._image_files[i]

            if (x + self._image_size + 2 * margin) > canvas_width:
                x = 0
                y += self._image_size + 2 * margin

            image_dimensions = ImageDimensions(
                size=self._image_size,
            )
            image_position = ImagePosition(
                x=x,
                y=y,
            )

            request = LoadImageRequest(
                image_file=image_file,
                image_dimensions=image_dimensions,
            )
            loaded_image = self._image_loader.request_image(request)
            if loaded_image:
                overview_image = OverviewLoadedImage(
                    image_file=image_file,
                    image_position=image_position,
                    image_dimensions=image_dimensions,
                    selected=False,
                    photo_image=loaded_image.photo_image,
                )
            else:
                overview_image = OverviewRequestedImage(
                    image_file=image_file,
                    image_position=image_position,
                    image_dimensions=image_dimensions,
                    selected=False,
                )
            overview_image.selected = overview_image.contains_point(self._mouse_x, self._mouse_y)
            overview_images.append(overview_image)

            x += self._image_size + 2 * margin

        return OverviewModel(overview_images)

    def _create_detail_model(self) -> DetailModel:
        viewport = self._renderer.viewport()
        image_dimensions = ImageDimensions(
            size=min(viewport.width, viewport.height)
        )
        photo_image = self._image_loader.load_image(self._selected_image.image_file, image_dimensions)
        return DetailModel(
            image_file=self._selected_image.image_file,
            image_dimensions=image_dimensions,
            photo_image=photo_image,
        )


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return

    root = tk.Tk()
    root.title("Blank Box")

    canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
    canvas.pack(fill="both", expand=True)

    image_loader = ImageLoader()
    renderer = Renderer(canvas)
    ui = UI(image_loader, renderer, files)

    canvas.bind("<Configure>", lambda e: ui.initialize())

    canvas.bind('<Motion>', lambda e: ui.mouse_select(e))

    canvas.bind("<MouseWheel>", lambda e: ui.scroll(e))  # Windows / macOS
    canvas.bind("<Button-4>", lambda e: ui.scroll(e))
    canvas.bind("<Button-5>", lambda e: ui.scroll(e))

    root.bind('<Home>', lambda _: ui.scroll_to_start())

    canvas.bind("<Control-MouseWheel>", lambda e: ui.zoom(e))
    canvas.bind("<Control-Button-4>", lambda e: ui.zoom(e))
    canvas.bind("<Control-Button-5>", lambda e: ui.zoom(e))

    root.bind('<space>', lambda e: ui.toggle_preview())

    root.bind('<Escape>', lambda e: root.quit())
    root.bind('q', lambda e: root.quit())

    def poll_loaded_images(_):
        ui.process_loaded_images()
        root.after(50, poll_loaded_images, root)

    root.after_idle(poll_loaded_images, root)
    root.mainloop()


if __name__ == '__main__':
    main()
