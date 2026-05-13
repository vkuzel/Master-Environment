#!/usr/bin/env python3
"""
- TODO End, PageUp, PageDown shortcuts
"""
import queue
import threading
from dataclasses import dataclass
from math import floor
from pathlib import Path
from queue import Queue
from tkinter import Canvas, Event, Image, PhotoImage, Tk
from typing import Dict, Optional, Set, Tuple

from PIL import Image, ImageTk
from PIL.Image import Resampling

MARGIN = 5


@dataclass(frozen=True)
class ImageFile:
    name: str


@dataclass(frozen=True)
class ImageDimensions:
    width: int
    height: int


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
        x2, y2 = x1 + self.image_dimensions.width, y1 + self.image_dimensions.height
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
        index = self._find_selected_image_index()
        return self.images[index] if index is not None else None

    def find_selected_image_and_previous(self) -> Tuple[Optional[OverviewImage], Optional[OverviewImage]]:
        index = self._find_selected_image_index()
        if index is None:
            return None, None
        elif index == 0:
            return self.images[index], None
        else:
            return self.images[index], self.images[index - 1]

    def find_selected_image_and_next(self) -> Tuple[Optional[OverviewImage], Optional[OverviewImage]]:
        index = self._find_selected_image_index()
        if index is None:
            return None, None
        elif index == len(self.images) - 1:
            return self.images[index], None
        else:
            return self.images[index], self.images[index + 1]

    def find_selected_image_and_above(self) -> Tuple[Optional[OverviewImage], Optional[OverviewImage]]:
        index = self._find_selected_image_index()
        if index is None:
            return None, None

        selected_image = self.images[index]
        for index in range(index - 1, -1, -1):
            image = self.images[index]
            if image.image_position.x == selected_image.image_position.x:
                return selected_image, image
        else:
            return selected_image, None

    def find_selected_image_and_bellow(self) -> Tuple[Optional[OverviewImage], Optional[OverviewImage]]:
        index = self._find_selected_image_index()
        if index is None:
            return None, None

        selected_image = self.images[index]
        for index in range(index + 1, len(self.images)):
            image = self.images[index]
            if image.image_position.x == selected_image.image_position.x:
                return selected_image, image
        else:
            return selected_image, None

    def _find_selected_image_index(self) -> Optional[int]:
        for i, image in enumerate(self.images):
            if image.selected:
                return i
        else:
            return None

    def create_loaded_image(self, loaded_image: LoadedImage) -> Optional[OverviewLoadedImage]:
        # Loop in a loop can be optimized
        for i, image in enumerate(self.images):
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

    def cancel(self):
        self._requested_images = set()
        self._loaded_images = {}
        self._loaded_photo_images = {}
        self._clear_queue(self._in_queue)
        self._clear_queue(self._out_queue)

    @staticmethod
    def load_image(image_file: ImageFile, image_dimensions: ImageDimensions) -> ImageTk.PhotoImage:
        image = Image.open(image_file.name)
        image = ImageLoader._resize_image(image, image_dimensions)
        return ImageTk.PhotoImage(image)

    @staticmethod
    def _resize_image(image, image_dimensions: ImageDimensions):
        scale = min(image_dimensions.width / image.width, image_dimensions.height / image.height)
        new_width = int(image.width * scale)
        new_height = int(image.height * scale)
        return image.resize((new_width, new_height), resample=Resampling.NEAREST)

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
        image: Image

    class _Worker(threading.Thread):
        def __init__(self, in_queue: Queue[LoadImageRequest], out_queue: Queue['ImageLoader._LoadedRawImage']):
            super().__init__(daemon=True)
            self._in_queue = in_queue
            self._out_queue = out_queue

        def run(self):
            while True:
                request = self._in_queue.get()

                try:
                    image = Image.open(request.image_file.name)
                    image = ImageLoader._resize_image(image, request.image_dimensions)

                    loaded_image = ImageLoader._LoadedRawImage(
                        request=request,
                        image=image,
                    )
                    self._out_queue.put(loaded_image)
                except:
                    pass


class Renderer:
    def __init__(self, canvas: Canvas):
        self._canvas = canvas

    def viewport(self) -> Viewport:
        return Viewport(
            width=self._canvas.winfo_width(),
            height=self._canvas.winfo_height(),
        )

    def render_overview(self, overview_model: OverviewModel):
        self._canvas.delete("all")

        canvas_height = self._canvas.winfo_height()

        for image in overview_model.images:
            if image.image_position.y + image.image_dimensions.height + 2 * MARGIN < 0:
                continue
            if image.image_position.y > canvas_height:
                continue

            self._canvas.create_rectangle(
                image.image_position.x + MARGIN,
                image.image_position.y + MARGIN,
                image.image_position.x + MARGIN + image.image_dimensions.width,
                image.image_position.y + MARGIN + image.image_dimensions.height,
                width=2,
                fill="#01302f",
            )

            self._canvas.create_text(
                image.image_position.x + MARGIN + image.image_dimensions.width / 2,
                image.image_position.y + MARGIN + image.image_dimensions.height / 2,
                text=image.image_file.name,
                anchor="center",
                font=("Arial", 12),
                fill="white",
            )

            if isinstance(image, OverviewLoadedImage):
                self.render_overview_image(image)

            self.render_overview_image_highlight(image)

    def render_overview_image(self, image: OverviewLoadedImage):
        x_offset = int((image.image_dimensions.width - image.photo_image.width()) / 2)
        y_offset = int((image.image_dimensions.height - image.photo_image.height()) / 2)
        self._canvas.create_image(
            image.image_position.x + MARGIN + x_offset,
            image.image_position.y + MARGIN + y_offset,
            image=image.photo_image,
            anchor="nw"
        )

    def render_overview_image_highlight(self, image: OverviewImage):
        outline = "white" if image.selected else "black"
        self._canvas.create_rectangle(
            image.image_position.x + MARGIN,
            image.image_position.y + MARGIN,
            image.image_position.x + MARGIN + image.image_dimensions.width,
            image.image_position.y + MARGIN + image.image_dimensions.height,
            width=2,
            outline=outline,
        )

    def render_detail(self, image: DetailModel):
        self._canvas.delete("all")
        viewport = self.viewport()
        self._canvas.create_image(
            floor((viewport.width - image.photo_image.width()) / 2),
            floor((viewport.height - image.photo_image.height()) / 2),
            image=image.photo_image,
            anchor='nw',
        )

class WindowManager:
    def __init__(self, root: Tk):
        self._root = root

    def set_title(self, title: str):
        self._root.title(f"Preview {title}")

    def reset_title(self):
        self._root.title(f"Preview {Path.cwd()}")

class UI:
    def __init__(
            self,
            window_manager: WindowManager,
            image_loader: ImageLoader,
            renderer: Renderer,
            image_files: list[ImageFile]
    ):
        self._window_manager = window_manager
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

        old_tile_size = self._image_size + 2 * MARGIN

        zoom_speed = 10
        if event.num == 4:
            self._image_size = min(self._image_size + zoom_speed, self._renderer.viewport().width - 2 * MARGIN)
        elif event.num == 5:
            self._image_size = max(self._image_size - zoom_speed, 1)

        new_tile_size = self._image_size + 2 * MARGIN
        content_y = self._mouse_y - self._scroll_offset
        self._scroll_offset = round(self._mouse_y - content_y * new_tile_size / old_tile_size)

        self._image_loader.cancel()
        self._model = self._create_overview_model()
        self._renderer.render_overview(self._model)

    def select_previous(self):
        selected_image, previous_image = self._model.find_selected_image_and_previous()
        if selected_image is None or previous_image is None:
            return

        selected_image.selected = False
        previous_image.selected = True

        if self._selected_image:
            self._selected_image = previous_image
            self.initialize()
        else:
            self._renderer.render_overview_image_highlight(selected_image)
            self._renderer.render_overview_image_highlight(previous_image)

    def select_next(self):
        selected_image, next_image = self._model.find_selected_image_and_next()
        if selected_image is None or next_image is None:
            return

        selected_image.selected = False
        next_image.selected = True

        if self._selected_image:
            self._selected_image = next_image
            self.initialize()
        else:
            self._renderer.render_overview_image_highlight(selected_image)
            self._renderer.render_overview_image_highlight(next_image)

    def select_above(self):
        if self._selected_image:
            return

        selected_image, above_image = self._model.find_selected_image_and_above()
        if selected_image is None or above_image is None:
            return

        selected_image.selected = False
        above_image.selected = True

        self._renderer.render_overview_image_highlight(selected_image)
        self._renderer.render_overview_image_highlight(above_image)

    def select_below(self):
        if self._selected_image:
            return

        selected_image, bellow_image = self._model.find_selected_image_and_bellow()
        if selected_image is None or bellow_image is None:
            return

        selected_image.selected = False
        bellow_image.selected = True

        self._renderer.render_overview_image_highlight(selected_image)
        self._renderer.render_overview_image_highlight(bellow_image)

    def toggle_preview(self):
        if self._selected_image:
            self._selected_image = None
        else:
            self._selected_image = self._model.find_selected_image()
        self.initialize()

    def initialize(self):
        if self._selected_image:
            self._window_manager.set_title(self._selected_image.image_file.name)
            detail_model = self._create_detail_model()
            self._detail_model = detail_model
            self._renderer.render_detail(detail_model)
        else:
            self._window_manager.reset_title()
            self._model = self._create_overview_model()
            self._renderer.render_overview(self._model)

    def process_loaded_images(self):
        if self._selected_image:
            return

        loaded_images = self._image_loader.poll_loaded_images()
        for loaded_image in loaded_images:
            if self._selected_image:
                continue

            overview_loaded_image = self._model.create_loaded_image(loaded_image)
            if overview_loaded_image:
                self._renderer.render_overview_image(overview_loaded_image)

    def _create_overview_model(self) -> OverviewModel:
        canvas_width = self._renderer.viewport().width

        if self._first_render:
            self._first_render = False
            image_width = self._image_size + 2 * MARGIN
            line_images_count = floor(canvas_width / image_width)
            unused_margin = canvas_width - image_width * line_images_count
            self._image_size += floor(unused_margin / line_images_count)

        meta_images: list[UI._MetaImage] = []

        x = 0
        y = self._scroll_offset
        for image_file in self._image_files:
            if (x + self._image_size + 2 * MARGIN) > canvas_width:
                x = 0
                y += self._image_size + 2 * MARGIN

            meta_images.append(UI._MetaImage(
                file=image_file,
                position=ImagePosition(
                    x=x,
                    y=y,
                ),
                dimensions=ImageDimensions(
                    width=self._image_size,
                    height=self._image_size,
                ),
            ))

            x += self._image_size + 2 * MARGIN

        meta_images.sort(key=lambda mi: mi.distance_to(self._mouse_x, self._mouse_y))

        overview_images: list[OverviewImage] = []
        for meta_image in meta_images:
            request = LoadImageRequest(
                image_file=meta_image.file,
                image_dimensions=meta_image.dimensions,
            )
            loaded_image = self._image_loader.request_image(request)
            if loaded_image:
                overview_image = OverviewLoadedImage(
                    image_file=meta_image.file,
                    image_position=meta_image.position,
                    image_dimensions=meta_image.dimensions,
                    selected=False,
                    photo_image=loaded_image.photo_image,
                )
            else:
                overview_image = OverviewRequestedImage(
                    image_file=meta_image.file,
                    image_position=meta_image.position,
                    image_dimensions=meta_image.dimensions,
                    selected=False,
                )
            overview_image.selected = overview_image.contains_point(self._mouse_x, self._mouse_y)
            overview_images.append(overview_image)

        return OverviewModel(overview_images)

    def _create_detail_model(self) -> DetailModel:
        viewport = self._renderer.viewport()
        image_dimensions = ImageDimensions(
            width=viewport.width,
            height=viewport.height,
        )
        photo_image = self._image_loader.load_image(self._selected_image.image_file, image_dimensions)
        return DetailModel(
            image_file=self._selected_image.image_file,
            image_dimensions=image_dimensions,
            photo_image=photo_image,
        )

    @dataclass(frozen=True)
    class _MetaImage:
        file: ImageFile
        position: ImagePosition
        dimensions: ImageDimensions

        def distance_to(self, x: int, y: int) -> int:
            center_x = int(self.position.x + self.dimensions.width / 2)
            center_y = int(self.position.y + self.dimensions.height / 2)
            return (x - center_x) ** 2 + (y - center_y) ** 2


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return

    root = Tk()
    canvas = Canvas(root, bg="#00201e", highlightthickness=0)
    canvas.pack(fill="both", expand=True)

    window_manager = WindowManager(root)
    image_loader = ImageLoader()
    renderer = Renderer(canvas)
    ui = UI(window_manager, image_loader, renderer, files)

    canvas.bind("<Configure>", lambda e: ui.initialize())

    canvas.bind('<Motion>', lambda e: ui.mouse_select(e))

    canvas.bind("<Button-4>", lambda e: ui.scroll(e))
    canvas.bind("<Button-5>", lambda e: ui.scroll(e))

    canvas.bind("<Control-Button-4>", lambda e: ui.zoom(e))
    canvas.bind("<Control-Button-5>", lambda e: ui.zoom(e))

    root.bind('<Home>', lambda _: ui.scroll_to_start())

    root.bind('<Left>', lambda _: ui.select_previous())
    root.bind('<Right>', lambda _: ui.select_next())
    root.bind('<Up>', lambda _: ui.select_above())
    root.bind('<Down>', lambda _: ui.select_below())

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
