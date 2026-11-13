#!/usr/bin/env python3

import random
import string
import tkinter as tk
from tkinter import Canvas
from typing import List

CHARS = string.ascii_letters + string.digits
SIZE = 16
TRAIL = 20
DELAY_MS = 60


def reset(canvas: Canvas, drops: List[int]):
    canvas.delete("all")
    rows = canvas.winfo_height() // SIZE
    drops[:] = [random.randint(-rows, 0) for _ in range(canvas.winfo_width() // SIZE)]


def step(canvas: Canvas, drops: List[int], tick: int = 0):
    rows = canvas.winfo_height() // SIZE
    canvas.itemconfig(f"t{tick - 1}", fill="#00a000")
    canvas.delete(f"t{tick - TRAIL}")
    for x, y in enumerate(drops):
        if 0 <= y < rows:
            canvas.create_text(x * SIZE, y * SIZE, text=random.choice(CHARS), anchor="nw",
                               fill="#c0ffc0", font=("monospace", SIZE - 4), tags=f"t{tick}")
        drops[x] = y + 1 if y < rows else random.randint(-rows, 0)
    canvas.after(DELAY_MS, step, canvas, drops, tick + 1)


def main():
    root = tk.Tk()
    root.title("Matrix Rain")

    drops: List[int] = []
    canvas = tk.Canvas(root, bg="black", highlightthickness=0)
    canvas.pack(fill="both", expand=True)
    canvas.bind("<Configure>", lambda e: reset(e.widget, drops))

    root.bind('<Escape>', lambda e: root.quit())
    root.bind('q', lambda e: root.quit())

    step(canvas, drops)
    root.mainloop()


if __name__ == '__main__':
    main()
