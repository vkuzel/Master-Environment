#!/usr/bin/env python3

import tkinter as tk
from dataclasses import dataclass
from pathlib import Path
from tkinter import Canvas

from rich import color


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


class UI:
    def run(self, image_files: list[ImageFile]):
        root = tk.Tk()
        root.title("Blank Box")

        canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
        canvas.pack(fill="both", expand=True)
        canvas.bind("<Configure>", lambda e: self._render_images(canvas, image_files))

        root.bind('<Escape>', lambda e: root.quit())
        root.bind('q', lambda e: root.quit())

        root.mainloop()

    @staticmethod
    def _render_images(canvas: Canvas, image_files: list[ImageFile]):
        canvas_width = canvas.winfo_width()
        canvas_height = canvas.winfo_height()

        box_width = 100
        box_height = 100

        margin = 5

        x = 0
        y = 0
        for i in range(0, len(image_files)):
            image_file = image_files[i]

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

            x += box_width + 2 * margin


def main():
    files = ImageFilesScanner().scan()
    if len(files) == 0:
        print("No images found")
        return
    UI().run(files)


if __name__ == '__main__':
    main()
