#!/usr/bin/env python3
import queue
import threading
import tkinter as tk
from dataclasses import dataclass
from math import floor
from pathlib import Path
from queue import Queue
from tkinter import Canvas, Event, PhotoImage
from typing import Dict, Optional

from PIL import Image, ImageTk


@dataclass(frozen=True)
class ImageFile:
    name: str


@dataclass(frozen=True)
class ImageDimensions:
    name: str
    size: int


@dataclass(frozen=True)
class LoadedImage:
    image_dimensions: ImageDimensions
    image: tk.Image


@dataclass(frozen=True)
class LoadedPhotoImage:
    image_dimensions: ImageDimensions
    photo_image: PhotoImage


@dataclass(frozen=True)
class ImagePosition:
    x: int
    y: int


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


class ImageProvider:
    def __init__(self):
        self._in_queue: Queue[ImageDimensions] = Queue()
        self._out_queue: Queue[LoadedImage] = Queue()
        ImageProvider.Worker(self._in_queue, self._out_queue).start()
        self._loaded_images: Dict[ImageDimensions, LoadedImage] = {}
        self._loaded_photo_images: Dict[ImageDimensions, LoadedPhotoImage] = {}

    def request_image(self, image_dimensions: ImageDimensions) -> Optional[LoadedPhotoImage]:
        if image_dimensions in self._loaded_photo_images:
            return self._loaded_photo_images[image_dimensions]
        elif image_dimensions in self._loaded_images:
            loaded_image = self._loaded_images[image_dimensions]
            self._out_queue.put(loaded_image)
            return None
        else:
            self._in_queue.put(image_dimensions)
            return None

    def reset_loading(self):
        self._loaded_images = {}
        self._loaded_photo_images = {}
        self._clear_queue(self._in_queue)
        self._clear_queue(self._out_queue)

    @staticmethod
    def _clear_queue(q: Queue):
        try:
            while True:
                q.get_nowait()
        except queue.Empty:
            pass

    def poll_loaded_photo_images(self) -> list[LoadedPhotoImage]:
        items = []
        while not self._out_queue.empty():
            try:
                loaded_image = self._out_queue.get_nowait()
                self._loaded_images[loaded_image.image_dimensions] = loaded_image

                photo_image = ImageTk.PhotoImage(loaded_image.image)
                loaded_photo_image = LoadedPhotoImage(
                    image_dimensions=loaded_image.image_dimensions,
                    photo_image=photo_image,
                )
                self._loaded_photo_images[loaded_image.image_dimensions] = loaded_photo_image

                items.append(loaded_photo_image)
            except queue.Empty:
                break
        return items

    class Worker(threading.Thread):
        def __init__(self, in_queue: Queue[ImageDimensions], out_queue: Queue[LoadedImage]):
            super().__init__(daemon=True)
            self._in_queue = in_queue
            self._out_queue = out_queue

        def run(self):
            while True:
                image_dimensions = self._in_queue.get()

                image = Image.open(image_dimensions.name)
                image = image.resize((image_dimensions.size, image_dimensions.size))

                loaded_image = LoadedImage(
                    image_dimensions=image_dimensions,
                    image=image,
                )
                self._out_queue.put(loaded_image)


class UI:
    def __init__(self, image_provider: ImageProvider, image_files: list[ImageFile]):
        self._image_provider = image_provider
        self._image_files = image_files

        self._margin = 5

        self._first_render = True
        self._scroll_offset = 0
        self._image_size = 100

        self._requested_image_positions: Dict[ImageDimensions, ImagePosition] = {}

    def run(self):
        root = tk.Tk()
        root.title("Blank Box")

        canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
        canvas.pack(fill="both", expand=True)
        canvas.bind("<Configure>", lambda e: self._render(canvas))

        canvas.bind("<MouseWheel>", lambda e: self._scroll_render(e, canvas))  # Windows / macOS
        canvas.bind("<Button-4>", lambda e: self._scroll_render(e, canvas))
        canvas.bind("<Button-5>", lambda e: self._scroll_render(e, canvas))

        root.bind('<Home>', lambda _: self._scroll_start_render(canvas))

        canvas.bind("<Control-MouseWheel>", lambda e: self._zoom_render(e, canvas))
        canvas.bind("<Control-Button-4>", lambda e: self._zoom_render(e, canvas))
        canvas.bind("<Control-Button-5>", lambda e: self._zoom_render(e, canvas))

        root.bind('<Escape>', lambda e: root.quit())
        root.bind('q', lambda e: root.quit())

        root.after_idle(self._render_images, root, canvas)
        root.mainloop()

    def _scroll_start_render(self, canvas: Canvas):
        self._scroll_offset = 0
        self._render(canvas)

    def _scroll_render(self, event: Event, canvas: Canvas):
        scroll_speed = 50
        if event.num == 4:
            self._scroll_offset += scroll_speed
        elif event.num == 5:
            self._scroll_offset -= scroll_speed
        self._render(canvas)

    def _zoom_render(self, event: Event, canvas: Canvas):
        zoom_speed = 3
        if event.num == 4:
            self._image_size += zoom_speed
        elif event.num == 5:
            self._image_size = max(self._image_size - zoom_speed, 1)
        self._image_provider.reset_loading()
        self._render(canvas)

    def _render(self, canvas: Canvas):
        canvas_width = canvas.winfo_width()
        canvas_height = canvas.winfo_height()

        if self._first_render:
            self._first_render = False
            image_width = self._image_size + 2 * self._margin
            line_images_count = floor(canvas_width / image_width)
            unused_margin = canvas_width - image_width * line_images_count
            self._image_size += floor(unused_margin / line_images_count)

        canvas.delete("all")

        x = 0
        y = self._scroll_offset
        for i in range(0, len(self._image_files)):
            image_file = self._image_files[i]

            if (x + self._image_size + 2 * self._margin) > canvas_width:
                x = 0
                y += self._image_size + 2 * self._margin

            if y > canvas_height:
                break

            canvas.create_rectangle(
                x + self._margin,
                y + self._margin,
                x + self._margin + self._image_size,
                y + self._margin + self._image_size,
                width=2,
                fill="#01302f",
            )

            canvas.create_text(
                x + self._margin + self._image_size / 2,
                y + self._margin + self._image_size / 2,
                text=image_file.name,
                anchor="center",
                font=("Arial", 12),
                fill="white",
            )

            image_dimensions = ImageDimensions(
                name=image_file.name,
                size=self._image_size,
            )
            image_position = ImagePosition(
                x=x,
                y=y,
            )

            self._requested_image_positions[image_dimensions] = image_position
            loaded_photo_image = self._image_provider.request_image(image_dimensions)
            if loaded_photo_image:
                self._render_loaded_photo_image(loaded_photo_image, canvas)

            x += self._image_size + 2 * self._margin

    def _render_images(self, root, canvas: Canvas):
        loaded_photo_images = self._image_provider.poll_loaded_photo_images()
        for loaded_photo_image in loaded_photo_images:
            self._render_loaded_photo_image(loaded_photo_image, canvas)

        root.after(50, self._render_images, root, canvas)

    def _render_loaded_photo_image(self, loaded_photo_image: LoadedPhotoImage, canvas: Canvas):
        image_dimensions = loaded_photo_image.image_dimensions
        image_position = self._requested_image_positions[image_dimensions]
        if not image_position:
            raise Exception(f"No image position for: {image_dimensions}")

        canvas.create_image(
            image_position.x + self._margin,
            image_position.y + self._margin,
            image=loaded_photo_image.photo_image,
            anchor="nw"
        )


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return
    image_provider = ImageProvider()
    UI(image_provider, files).run()


if __name__ == '__main__':
    main()
