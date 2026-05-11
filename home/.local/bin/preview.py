#!/usr/bin/env python3

import tkinter as tk
from dataclasses import dataclass
from pathlib import Path
from tkinter import Canvas, Event

from PIL import Image, ImageTk


@dataclass(frozen=True)
class ImageFile:
    name: str


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


@dataclass
class UI:
    image_files: list[ImageFile]

    _scroll_offset = 0

    _photo_images = {}

    def run(self):
        root = tk.Tk()
        root.title("Blank Box")

        canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
        canvas.pack(fill="both", expand=True)
        canvas.bind("<Configure>", lambda e: self._render(canvas))

        canvas.bind("<MouseWheel>", lambda e: self._scroll_render(e, canvas))  # Windows / macOS
        canvas.bind("<Button-4>", lambda e: self._scroll_render(e, canvas))
        canvas.bind("<Button-5>", lambda e: self._scroll_render(e, canvas))

        root.bind('<Escape>', lambda e: root.quit())
        root.bind('q', lambda e: root.quit())

        root.mainloop()

    def _scroll_render(self, event: Event, canvas: Canvas):
        scroll_speed = 50
        if event.num == 4:
            self._scroll_offset += scroll_speed
        elif event.num == 5:
            self._scroll_offset -= scroll_speed
        self._render(canvas)

    def _render(self, canvas: Canvas):
        canvas_width = canvas.winfo_width()
        canvas_height = canvas.winfo_height()

        box_width = 100
        box_height = 100

        margin = 5

        canvas.delete("all")

        x = 0
        y = self._scroll_offset
        for i in range(0, len(self.image_files)):
            image_file = self.image_files[i]

            if (x + box_width + 2 * margin) > canvas_width:
                x = 0
                y += box_height + margin

            if y > canvas_height:
                break

            canvas.create_rectangle(
                x + margin,
                y + margin,
                x + margin + box_width,
                y + margin + box_height,
                width=2,
                fill="#01302f",
            )

            canvas.create_text(
                x + margin + box_width / 2,
                y + margin + box_height / 2,
                text=image_file.name,
                anchor="center",
                font=("Arial", 12),
                fill="white",
            )

            if image_file in self._photo_images:
                photo_image = self._photo_images[image_file]
            else:
                image = Image.open(image_file.name)
                image = image.resize((box_width, box_height))

                photo_image = ImageTk.PhotoImage(image)
                self._photo_images[image_file] = photo_image  # preserve reference on image

            canvas.create_image(
                x + margin,
                y + margin,
                image=photo_image,
                anchor="nw"
            )

            x += box_width + 2 * margin


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return
    UI(files).run()


if __name__ == '__main__':
    main()
