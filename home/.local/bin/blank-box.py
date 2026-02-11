#!/usr/bin/env python3

import tkinter as tk


def main():
    root = tk.Tk()
    root.title("Blank Box")
    root.configure(bg='#01302f')

    root.bind('<Escape>', lambda e: root.quit())
    root.bind('q', lambda e: root.quit())

    root.mainloop()


if __name__ == '__main__':
    main()
