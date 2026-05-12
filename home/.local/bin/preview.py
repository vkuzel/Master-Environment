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


@dataclass
class ViewImage:
    image_file: ImageFile
    image_position: ImagePosition
    image_dimensions: ImageDimensions
    selected: bool

    def contains_point(self, x: int, y: int) -> bool:
        x1, y1 = self.image_position.x, self.image_position.y
        x2, y2 = x1 + self.image_dimensions.size, y1 + self.image_dimensions.size
        return x1 <= x <= x2 and y1 <= y <= y2


@dataclass
class ViewRequestedImage(ViewImage):
    def is_for_loaded_image(self, loaded_image: LoadedImage) -> bool:
        request = loaded_image.request
        return self.image_file == request.image_file and self.image_dimensions == request.image_dimensions


@dataclass
class ViewLoadedImage(ViewImage):
    photo_image: PhotoImage


@dataclass(frozen=True)
class ViewModel:
    images: list[ViewImage]


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

    def render(self, view_model: ViewModel):
        self._canvas.delete("all")

        canvas_height = self._canvas.winfo_height()

        for image in view_model.images:
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

            if isinstance(image, ViewLoadedImage):
                self.render_loaded_image(image)

            self.render_image_highlight(image)

    def render_loaded_image(self, image: ViewLoadedImage):
        self._canvas.create_image(
            image.image_position.x + self._margin,
            image.image_position.y + self._margin,
            image=image.photo_image,
            anchor="nw"
        )

    def render_image_highlight(self, image: ViewImage):
        outline = "white" if image.selected else "black"
        self._canvas.create_rectangle(
            image.image_position.x + self._margin,
            image.image_position.y + self._margin,
            image.image_position.x + self._margin + image.image_dimensions.size,
            image.image_position.y + self._margin + image.image_dimensions.size,
            width=2,
            outline=outline,
        )


class UI:
    def __init__(self, image_provider: ImageLoader, image_files: list[ImageFile]):
        self._image_provider = image_provider
        self._image_files = image_files
        self._renderer: Optional[Renderer] = None

        self._first_render = True
        self._scroll_offset = 0
        self._image_size = 100

        self._mouse_x = 0
        self._mouse_y = 0

        self._model = ViewModel([])

    def run(self):
        root = tk.Tk()
        root.title("Blank Box")

        canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
        self._renderer = Renderer(canvas)

        canvas.pack(fill="both", expand=True)
        canvas.bind("<Configure>", lambda e: self._render(canvas))

        canvas.bind('<Motion>', lambda e: self._mouse_move_render(e))

        canvas.bind("<MouseWheel>", lambda e: self._scroll_render(e, canvas))  # Windows / macOS
        canvas.bind("<Button-4>", lambda e: self._scroll_render(e, canvas))
        canvas.bind("<Button-5>", lambda e: self._scroll_render(e, canvas))

        root.bind('<Home>', lambda _: self._scroll_start_render(canvas))

        canvas.bind("<Control-MouseWheel>", lambda e: self._zoom_render(e, canvas))
        canvas.bind("<Control-Button-4>", lambda e: self._zoom_render(e, canvas))
        canvas.bind("<Control-Button-5>", lambda e: self._zoom_render(e, canvas))

        root.bind('<Escape>', lambda e: root.quit())
        root.bind('q', lambda e: root.quit())

        root.after_idle(self._render_images, root)
        root.mainloop()

    def _mouse_move_render(self, event: Event):
        self._mouse_x = event.x
        self._mouse_y = event.y
        for image in self._model.images:
            if image.selected and not image.contains_point(self._mouse_x, self._mouse_y):
                image.selected = False
                self._renderer.render_image_highlight(image)
            elif not image.selected and image.contains_point(self._mouse_x, self._mouse_y):
                image.selected = True
                self._renderer.render_image_highlight(image)

    def _scroll_start_render(self, canvas: Canvas):
        self._scroll_offset = 0
        self._model = self._create_view_model(canvas)
        if self._renderer: self._renderer.render(self._model)

    def _scroll_render(self, event: Event, canvas: Canvas):
        scroll_speed = 75
        if event.num == 4:
            self._scroll_offset += scroll_speed
        elif event.num == 5:
            self._scroll_offset -= scroll_speed
        self._model = self._create_view_model(canvas)
        if self._renderer: self._renderer.render(self._model)

    def _zoom_render(self, event: Event, canvas: Canvas):
        zoom_speed = 10
        if event.num == 4:
            self._image_size += zoom_speed
        elif event.num == 5:
            self._image_size = max(self._image_size - zoom_speed, 1)
        self._image_provider.cancel()
        self._model = self._create_view_model(canvas)
        if self._renderer: self._renderer.render(self._model)

    def _render(self, canvas: Canvas):
        self._model = self._create_view_model(canvas)
        if self._renderer: self._renderer.render(self._model)

    def _render_images(self, root):
        loaded_images = self._image_provider.poll_loaded_images()
        for loaded_image in loaded_images:
            if not self._model:
                continue

            for i in range(0, len(self._model.images)):
                image = self._model.images[i]
                if not isinstance(image, ViewRequestedImage):
                    continue
                if not image.is_for_loaded_image(loaded_image):
                    continue

                view_loaded_image = ViewLoadedImage(
                    image_file=image.image_file,
                    image_position=image.image_position,
                    image_dimensions=image.image_dimensions,
                    selected=image.selected,
                    photo_image=loaded_image.photo_image,
                )
                self._model.images[i] = view_loaded_image
                self._renderer.render_loaded_image(view_loaded_image)

        root.after(50, self._render_images, root)

    def _create_view_model(self, canvas: Canvas) -> ViewModel:
        margin = 5
        canvas_width = canvas.winfo_width()

        if self._first_render:
            self._first_render = False
            image_width = self._image_size + 2 * margin
            line_images_count = floor(canvas_width / image_width)
            unused_margin = canvas_width - image_width * line_images_count
            self._image_size += floor(unused_margin / line_images_count)

        view_images: list[ViewImage] = []

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
            loaded_image = self._image_provider.request_image(request)
            if loaded_image:
                view_image = ViewLoadedImage(
                    image_file=image_file,
                    image_position=image_position,
                    image_dimensions=image_dimensions,
                    selected=False,
                    photo_image=loaded_image.photo_image,
                )
            else:
                view_image = ViewRequestedImage(
                    image_file=image_file,
                    image_position=image_position,
                    image_dimensions=image_dimensions,
                    selected=False,
                )
            view_image.selected = view_image.contains_point(self._mouse_x, self._mouse_y)
            view_images.append(view_image)

            x += self._image_size + 2 * margin

        return ViewModel(view_images)


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return
    image_provider = ImageLoader()
    UI(image_provider, files).run()


if __name__ == '__main__':
    main()
