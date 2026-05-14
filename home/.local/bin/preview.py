#!/usr/bin/env python3
import io
import queue
import threading
from dataclasses import dataclass
from pathlib import Path
from queue import Queue
from tkinter import Canvas, Event, Tk
from typing import Dict, Optional, Set, Tuple

from PIL import Image, ImageTk
from PIL.Image import Resampling
from PIL.ImageTk import PhotoImage


@dataclass(frozen=True)
class ImageFile:
    name: str


@dataclass(frozen=True)
class Dimensions:
    width: int
    height: int


@dataclass
class Position:
    x: int
    y: int


@dataclass(frozen=True)
class Rectangle:
    position: Position
    dimensions: Dimensions

    @property
    def x1(self) -> int:
        return self.position.x

    @property
    def y1(self) -> int:
        return self.position.y

    @property
    def x2(self) -> int:
        return self.position.x + self.dimensions.width

    @property
    def y2(self) -> int:
        return self.position.y + self.dimensions.height

    @property
    def center_x(self) -> int:
        return int(self.position.x + self.dimensions.width / 2)

    @property
    def center_y(self) -> int:
        return int(self.position.y + self.dimensions.height / 2)

    def contains_position(self, position: Position) -> bool:
        return self.x1 <= position.x <= self.x2 and self.y1 <= position.y <= self.y2


@dataclass(frozen=True)
class LoadImageRequest:
    image_file: ImageFile
    dimensions: Dimensions


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
    position: Position
    inner_dimensions: Dimensions
    margin: int
    selected: bool

    @property
    def inner_rect(self) -> Rectangle:
        return Rectangle(
            position=Position(
                self.position.x + self.margin,
                self.position.y + self.margin,
            ),
            dimensions=self.inner_dimensions,
        )

    @property
    def outer_rect(self) -> Rectangle:
        return Rectangle(
            position=self.position,
            dimensions=Dimensions(
                self.inner_dimensions.width + 2 * self.margin,
                self.inner_dimensions.height + 2 * self.margin,
            )
        )

    def contains_position(self, position: Position) -> bool:
        return self.outer_rect.contains_position(position)


@dataclass
class OverviewLoadedImage(OverviewImage):
    photo_image: PhotoImage

    @property
    def photo_rect(self) -> Rectangle:
        x_offset = int((self.inner_rect.dimensions.width - self.photo_image.width()) / 2)
        y_offset = int((self.inner_rect.dimensions.height - self.photo_image.height()) / 2)
        return Rectangle(
            position=Position(
                x=self.inner_rect.position.x + x_offset,
                y=self.inner_rect.position.y + y_offset,
            ),
            dimensions=Dimensions(
                width=self.photo_image.width(),
                height=self.photo_image.height(),
            )
        )


@dataclass
class OverviewRequestedImage(OverviewImage):
    def is_for_loaded_image(self, loaded_image: LoadedImage) -> bool:
        request = loaded_image.request
        return self.image_file == request.image_file and self.inner_dimensions == request.dimensions

    def to_loaded_image(self, photo_image: PhotoImage) -> OverviewLoadedImage:
        return OverviewLoadedImage(
            image_file=self.image_file,
            position=self.position,
            inner_dimensions=self.inner_dimensions,
            margin=self.margin,
            selected=self.selected,
            photo_image=photo_image,
        )


@dataclass
class OverviewModel:
    viewport: Viewport
    scroll_offset: int
    image_size: int
    images: list[OverviewImage]

    def set_viewport(self, viewport: Viewport):
        self.viewport = viewport
        # TODO Add logic

    def set_scroll_offset(self, scroll_offset: int):
        self.scroll_offset = scroll_offset
        for i, image in enumerate(self.images):
            image_outer_size = image.outer_rect.dimensions.width
            image_position = OverviewModel.calculate_image_position(i, self.viewport, image_outer_size)
            image.position = Position(
                x=image_position.x,
                y=image_position.y + self.scroll_offset,
            )

    # TODO scroll_offset adjustment should be performed inside this method, not externally
    def set_image_size(self, image_size: int, scroll_offset: int):
        self.image_size = image_size
        self.scroll_offset = scroll_offset
        # TODO Add logic

    @staticmethod
    def calculate_image_position(index: int, viewport: Viewport, image_outer_size: int) -> Position:
        viewport_width = viewport.width
        image_width = image_outer_size
        image_height = image_outer_size

        columns = max(1, viewport_width // image_width)
        return Position(
            x=(index % columns) * image_width,
            y=(index // columns) * image_height,
        )

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
            if image.position.x == selected_image.position.x:
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
            if image.position.x == selected_image.position.x:
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

            overview_loaded_image = image.to_loaded_image(loaded_image.photo_image)
            self.images[i] = overview_loaded_image
            return overview_loaded_image
        else:
            return None


@dataclass(frozen=True)
class DetailModel:
    image_file: ImageFile
    image_dimensions: Dimensions
    photo_image: PhotoImage

    @property
    def photo_rect(self) -> Rectangle:
        return Rectangle(
            position=Position(
                x=int((self.image_dimensions.width - self.photo_image.width()) / 2),
                y=int((self.image_dimensions.height - self.photo_image.height()) / 2),
            ),
            dimensions=self.image_dimensions,
        )


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

        image_files.sort(key=lambda f: f.name)

        return image_files


class ImageLoader:
    def __init__(self):
        self._in_queue: Queue[LoadImageRequest] = Queue()
        self._out_queue: Queue[ImageLoader._LoadedRawImage] = Queue()
        ImageLoader._Worker(self._in_queue, self._out_queue).start()

        self._requested_images: Set[LoadImageRequest] = set()
        self._loaded_images: Dict[ImageFile, ImageLoader._LoadedRawImage] = {}
        self._loaded_photo_images: Dict[LoadImageRequest, LoadedImage] = {}

    def request_image(self, request: LoadImageRequest) -> Optional[LoadedImage]:
        if request in self._loaded_photo_images:
            return self._loaded_photo_images[request]
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
                self._loaded_images[loaded_image.request.image_file] = loaded_image

                loaded_photo_image = LoadedImage(
                    request=loaded_image.request,
                    photo_image=loaded_image.to_photo_image(),
                )
                self._loaded_photo_images[loaded_image.request] = loaded_photo_image

                items.append(loaded_photo_image)
            except queue.Empty:
                break
        return items

    def get_low_quality_image(self, request: LoadImageRequest) -> Optional[LoadedImage]:
        if request.image_file in self._loaded_images:
            loaded_image = self._loaded_images[request.image_file]

            image = Image.open(io.BytesIO(loaded_image.image_data))
            image.load()

            image = self._resize_image(image, request.dimensions)
            return LoadedImage(
                request=request,
                photo_image=ImageTk.PhotoImage(image),
            )
        else:
            return None

    def cancel(self):
        self._requested_images = set()
        self._loaded_photo_images = {}
        self._clear_queue(self._in_queue)
        self._clear_queue(self._out_queue)

    @staticmethod
    def load_image(image_file: ImageFile, dimensions: Dimensions) -> ImageTk.PhotoImage:
        image = Image.open(image_file.name)
        image = ImageLoader._resize_image(image, dimensions)
        return ImageTk.PhotoImage(image)

    @staticmethod
    def _resize_image(image: Image.Image, dimensions: Dimensions) -> Image.Image:
        scale = min(dimensions.width / image.width, dimensions.height / image.height)
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
        image_data: bytes

        def to_photo_image(self) -> ImageTk.PhotoImage:
            return ImageTk.PhotoImage(data=self.image_data)

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
                    image = ImageLoader._resize_image(image, request.dimensions)

                    buf = io.BytesIO()
                    buf.write(f"P6\n{image.width} {image.height}\n255\n".encode())
                    buf.write(image.convert("RGB").tobytes())

                    loaded_image = ImageLoader._LoadedRawImage(
                        request=request,
                        image_data=buf.getvalue(),
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
            if image.outer_rect.y1 > canvas_height or image.outer_rect.y2 < 0:
                continue

            self._canvas.create_rectangle(
                image.inner_rect.x1,
                image.inner_rect.y1,
                image.inner_rect.x2,
                image.inner_rect.y2,
                width=2,
                fill="#01302f",
            )

            self._canvas.create_text(
                image.outer_rect.center_x,
                image.outer_rect.center_y,
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
            image.photo_rect.x1,
            image.photo_rect.y1,
            image=image.photo_image,
            anchor="nw"
        )

    def render_overview_image_highlight(self, image: OverviewImage):
        outline = "white" if image.selected else "black"
        self._canvas.create_rectangle(
            image.inner_rect.x1,
            image.inner_rect.y1,
            image.inner_rect.x2,
            image.inner_rect.y2,
            width=2,
            outline=outline,
        )

    def render_detail(self, image: DetailModel):
        self._canvas.delete("all")
        self._canvas.create_image(
            image.photo_rect.x1,
            image.photo_rect.y1,
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
    _MARGIN = 5

    _MOUSE_SCROLL_SPEED = 75
    _MOUSE_ZOOM_SPEED = 10

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

        self._scroll_offset = 0
        self._image_size = 100

        self._mouse_position = Position(0, 0)

        # TODO Rename to self._overview_model
        self._model = OverviewModel(
            viewport=self._renderer.viewport(),
            scroll_offset=self._scroll_offset,
            image_size=self._image_size,
            images=[],
        )
        self._selected_image: Optional[OverviewImage] = None
        self._detail_model: Optional[DetailModel] = None

    @property
    def _image_outer_size(self) -> int:
        return self._image_size + 2 * self._MARGIN

    @property
    def _min_scroll_offset(self) -> int:
        return 0

    @property
    def _max_scroll_offset(self) -> int:
        viewport_height = self._renderer.viewport().height
        last_index = len(self._model.images) - 1
        images_height = self._calculate_image_position(last_index).y + self._image_outer_size
        return viewport_height - images_height

    def mouse_select(self, event: Event):
        self._mouse_position.x = event.x
        self._mouse_position.y = event.y
        if self._selected_image:
            return

        for image in self._model.images:
            if image.selected and not image.contains_position(self._mouse_position):
                image.selected = False
                self._renderer.render_overview_image_highlight(image)
            elif not image.selected and image.contains_position(self._mouse_position):
                image.selected = True
                self._renderer.render_overview_image_highlight(image)

    def scroll_to_start(self):
        if self._selected_image:
            return

        new_offset = self._min_scroll_offset
        if self._scroll_offset == new_offset:
            return

        self._scroll_offset = new_offset
        self._model.set_scroll_offset(self._scroll_offset)
        self._renderer.render_overview(self._model)

    def scroll_to_end(self):
        if self._selected_image:
            return

        new_offset = self._max_scroll_offset
        if self._scroll_offset == new_offset:
            return

        self._scroll_offset = new_offset
        self._model.set_scroll_offset(self._scroll_offset)
        self._renderer.render_overview(self._model)

    def scroll_page_up(self):
        if self._selected_image:
            return

        viewport_height = self._renderer.viewport().height
        new_offset = min(self._scroll_offset + viewport_height, self._max_scroll_offset)
        if self._scroll_offset == new_offset:
            return

        self._scroll_offset = new_offset
        self._model.set_scroll_offset(self._scroll_offset)
        self._renderer.render_overview(self._model)

    def scroll_page_down(self):
        if self._selected_image:
            return

        viewport_height = self._renderer.viewport().height
        new_offset = max(self._scroll_offset - viewport_height, self._min_scroll_offset)
        if self._scroll_offset == new_offset:
            return

        self._scroll_offset = new_offset
        self._model.set_scroll_offset(self._scroll_offset)
        self._renderer.render_overview(self._model)

    def scroll(self, event: Event):
        if self._selected_image:
            return

        if event.num == 4:
            new_offset = min(self._scroll_offset + self._MOUSE_SCROLL_SPEED, self._min_scroll_offset)
        elif event.num == 5:
            new_offset = max(self._scroll_offset - self._MOUSE_SCROLL_SPEED, self._max_scroll_offset)
        else:
            return

        if self._scroll_offset == new_offset:
            return

        self._scroll_offset = new_offset
        self._model.set_scroll_offset(self._scroll_offset)
        self._renderer.render_overview(self._model)

    def zoom(self, event: Event):
        if self._selected_image:
            return

        old_tile_size = self._image_outer_size

        if event.num == 4:
            max_image_size = self._renderer.viewport().width - 2 * self._MARGIN
            self._image_size = min(self._image_size + self._MOUSE_ZOOM_SPEED, max_image_size)
        elif event.num == 5:
            min_image_size = 1
            self._image_size = max(self._image_size - self._MOUSE_ZOOM_SPEED, min_image_size)

        new_tile_size = self._image_outer_size
        if old_tile_size == new_tile_size:
            return

        content_y = self._mouse_position.y - self._scroll_offset
        self._scroll_offset = round(self._mouse_position.y - content_y * new_tile_size / old_tile_size)

        self._image_loader.cancel()
        self._model.set_image_size(self._image_size, self._scroll_offset)
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
            self._detail_model = self._create_detail_model()
            self._renderer.render_detail(self._detail_model)
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
            self._detail_model = self._create_detail_model()
            self._renderer.render_detail(self._detail_model)
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
            self._renderer.render_overview(self._model)
        else:
            self._selected_image = self._model.find_selected_image()
            self._detail_model = self._create_detail_model()
            self._renderer.render_detail(self._detail_model)

    def initialize(self):
        if self._selected_image:
            self._window_manager.set_title(self._selected_image.image_file.name)
            detail_model = self._create_detail_model()
            self._detail_model = detail_model
            self._renderer.render_detail(detail_model)
        else:
            self._window_manager.reset_title()
            self._model.set_viewport(self._renderer.viewport())
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
        meta_images: list[UI._MetaImage] = []
        for i, image_file in enumerate(self._image_files):
            image_position = self._calculate_image_position(i)
            meta_images.append(UI._MetaImage(
                file=image_file,
                position=Position(
                    x=image_position.x,
                    y=image_position.y + self._scroll_offset,
                ),
                dimensions=Dimensions(
                    width=self._image_size,
                    height=self._image_size,
                ),
            ))

        # Request images closes to the mouse cursor first
        meta_images.sort(key=lambda mi: mi.distance_to(self._mouse_position))
        loaded_images = {}
        for i, meta_image in enumerate(meta_images):
            request = LoadImageRequest(
                image_file=meta_image.file,
                dimensions=meta_image.dimensions,
            )
            loaded_image = self._image_loader.request_image(request)
            # Image(s) close to mouse cursor immediate low quality render to prevent flicker
            if not loaded_image and i == 0:
                loaded_image = self._image_loader.get_low_quality_image(request)

            loaded_images[meta_image.file] = meta_image, loaded_image

        overview_images: list[OverviewImage] = []
        for image_file in self._image_files:
            (meta_image, loaded_image) = loaded_images[image_file]
            if loaded_image:
                overview_image = OverviewLoadedImage(
                    image_file=meta_image.file,
                    position=meta_image.position,
                    inner_dimensions=meta_image.dimensions,
                    margin=self._MARGIN,
                    selected=False,
                    photo_image=loaded_image.photo_image,
                )
            else:
                overview_image = OverviewRequestedImage(
                    image_file=meta_image.file,
                    position=meta_image.position,
                    inner_dimensions=meta_image.dimensions,
                    margin=self._MARGIN,
                    selected=False,
                )
            overview_image.selected = overview_image.contains_position(self._mouse_position)
            overview_images.append(overview_image)

        return OverviewModel(
            viewport=self._renderer.viewport(),
            scroll_offset=self._scroll_offset,
            image_size=self._image_size,
            images=overview_images
        )

    def _calculate_image_position(self, index: int) -> Position:
        return OverviewModel.calculate_image_position(index, self._renderer.viewport(), self._image_outer_size)

    def _create_detail_model(self) -> DetailModel:
        viewport = self._renderer.viewport()
        image_dimensions = Dimensions(
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
        position: Position
        dimensions: Dimensions

        def distance_to(self, position: Position) -> int:
            center_x = int(self.position.x + self.dimensions.width / 2)
            center_y = int(self.position.y + self.dimensions.height / 2)
            return (position.x - center_x) ** 2 + (position.y - center_y) ** 2


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
    root.bind('<End>', lambda _: ui.scroll_to_end())
    root.bind('<Prior>', lambda _: ui.scroll_page_up())
    root.bind('<Next>', lambda _: ui.scroll_page_down())

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
