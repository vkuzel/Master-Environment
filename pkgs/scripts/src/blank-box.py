#!/usr/bin/env python3

import tkinter as tk
from tkinter import Canvas


def render_stripes(canvas: Canvas):
    width = canvas.winfo_width()
    height = canvas.winfo_height()

    for i in range(0, width + height, 20):
        x1 = max(0, i - height)
        y1 = min(i, height)
        x2 = min(i, width)
        y2 = max(0, i - width)
        canvas.create_line(x1, y1, x2, y2, width=2, fill="#01302f")


def main():
    root = tk.Tk()
    root.title("Blank Box")

    canvas = tk.Canvas(root, bg="#00201e", highlightthickness=0)
    canvas.pack(fill="both", expand=True)
    canvas.bind("<Configure>", lambda e: render_stripes(e.widget))

    root.bind('<Escape>', lambda e: root.quit())
    root.bind('q', lambda e: root.quit())

    root.mainloop()


if __name__ == '__main__':
    main()
