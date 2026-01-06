#!/usr/bin/env python3
"""
Markdown Presentation Viewer
A simple fullscreen presentation tool that reads markdown files.

Usage: python3 presenter.py presentation.md

Controls:
- Right Arrow / Space: Next slide
- Left Arrow: Previous slide
- ESC / Q: Exit presentation

Markdown Support:
- Title: # Title
- Bold: **text** or __text__
- Italic: *text* or _text_
- Monospace: `code`
- Code blocks: ```code```
- Images: ![alt](path/to/image.png) - Supports JPEG, PNG, GIF, etc.
- Video: ![alt](path/to/video.mp4)
- Alignment: <left>, <center>, <right> tags
- Slides: Separated by ---

Requirements:
- python3-tk: sudo apt install python3-tk
- python3-pil: sudo apt install python3-pil python3-pil.imagetk
"""

import os
import re
import sys
import tkinter as tk
from dataclasses import dataclass
from tkinter import font as tkfont
from typing import Optional, List, Any

from PIL import Image, ImageTk


@dataclass(frozen=True)
class Element:
    align: str


@dataclass(frozen=True)
class TextSegment:
    text: str
    format: str


@dataclass(frozen=True)
class TitleElement(Element):
    segments: List[TextSegment]
    level: int


@dataclass(frozen=True)
class TextElement(Element):
    segments: List[TextSegment]


@dataclass(frozen=True)
class CodeBlockElement(Element):
    content: List[str]


@dataclass(frozen=True)
class ImageElement(Element):
    path: str
    alt: str


@dataclass(frozen=True)
class VideoElement(Element):
    path: str
    alt: str


@dataclass(frozen=True)
class Slide:
    elements: List[Element]


class Parser:
    def parse_markdown(self, markdown_file: str) -> List[Slide]:
        """Parse markdown file into slides"""
        try:
            with open(markdown_file, 'r', encoding='utf-8') as f:
                content = f.read()
        except FileNotFoundError:
            print(f"Error: File '{markdown_file}' not found")
            sys.exit(1)

        # Split by horizontal rules
        raw_slides = re.split(r'\n---+\n', content)

        slides = []
        for raw_slide in raw_slides:
            if not raw_slide.strip(): continue
            elements = self._parse_slide_content(raw_slide.strip())
            slides.append(Slide(elements))
        return slides

    @staticmethod
    def _parse_slide_content(content) -> List[Element]:
        """Parse individual slide content into structured format"""
        elements: List[Element] = []
        lines = content.split('\n')
        in_code_block = False
        code_block = []

        for line in lines:
            # Check for code block
            if line.strip().startswith('```'):
                if in_code_block:
                    elements.append(CodeBlockElement(
                        content=code_block,
                        align='left',
                    ))
                    code_block = []
                    in_code_block = False
                else:
                    in_code_block = True
                continue

            if in_code_block:
                code_block.append(line)
                continue

            # Skip empty lines
            if not line.strip():
                continue

            # Check for alignment tags
            align = 'left'
            if '<center>' in line.lower():
                align = 'center'
                line = re.sub(r'</?center>', '', line, flags=re.IGNORECASE)
            elif '<right>' in line.lower():
                align = 'right'
                line = re.sub(r'</?right>', '', line, flags=re.IGNORECASE)
            elif '<left>' in line.lower():
                align = 'left'
                line = re.sub(r'</?left>', '', line, flags=re.IGNORECASE)

            # Check for title
            if line.startswith('#'):
                level = len(line) - len(line.lstrip('#'))
                text = line.lstrip('#').strip()
                elements.append(TitleElement(
                    segments=Parser._parse_inline_formatting(text),
                    level=level,
                    align=align,
                ))
            # Check for images
            elif '![' in line:
                match = re.search(r'!\[([^]]*)]\(([^)]+)\)', line)
                if match:
                    alt_text = match.group(1)
                    path = match.group(2)
                    # Determine if it's a video
                    if path.lower().endswith(('.mp4', '.avi', '.mov', '.mkv', '.webm')):
                        elements.append(VideoElement(
                            path=path,
                            alt=alt_text,
                            align=align,
                        ))
                    else:
                        elements.append(ImageElement(
                            path=path,
                            alt=alt_text,
                            align=align
                        ))
            # Regular text
            else:
                elements.append(TextElement(
                    segments=Parser._parse_inline_formatting(line),
                    align=align,
                ))

        return elements

    @staticmethod
    def _parse_inline_formatting(text: str) -> List[Any]:
        """Parse bold, italic, and code formatting"""
        segments = []
        pos = 0

        # Pattern to match **bold**, __bold__, *italic*, _italic_, `code`
        pattern = r'(\*\*|__)(.*?)\1|(\*|_)(.*?)\3|`([^`]+)`'

        for match in re.finditer(pattern, text):
            # Add text before match
            if match.start() > pos:
                segments.append(TextSegment(text[pos:match.start()], 'normal'))

            if match.group(1):  # Bold
                segments.append(TextSegment(match.group(2), 'bold'))
            elif match.group(3):  # Italic
                segments.append(TextSegment(match.group(4), 'italic'))
            elif match.group(5):  # Code
                segments.append(TextSegment(match.group(5), 'code'))

            pos = match.end()

        # Add remaining text
        if pos < len(text):
            segments.append(TextSegment(text[pos:], 'normal'))

        return segments if segments else [TextSegment(text, 'normal')]


class SlideRenderer:
    def __init__(self, root: tk.Tk, canvas: tk.Canvas):
        self.canvas = canvas

        self._screen_width = root.winfo_width()
        self._screen_height = root.winfo_height()

        self._title_font: Optional[tkfont.Font] = None
        self._normal_font: Optional[tkfont.Font] = None
        self._code_font: Optional[tkfont.Font] = None


    def setup_fonts(self, title_size, normal_size, code_size):
        """Create fonts with specified sizes"""
        self._title_font = tkfont.Font(family="Arial", size=title_size, weight="bold")
        self._normal_font = tkfont.Font(family="Arial", size=normal_size)
        self._code_font = tkfont.Font(family="Courier", size=code_size)

    def render_text(self, segments: List[TextSegment], x, y, align='left', is_title=False) -> int:
        """Render formatted text with markdown styling"""
        font = self._title_font if is_title else self._normal_font

        # Calculate total width for alignment
        total_width = 0
        for segment in segments:
            temp_font = font
            match segment.format:
                case 'code':
                    temp_font = self._code_font
                case 'bold':
                    temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold")
                case 'italic':
                    temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], slant="italic")
                case 'bold_italic':
                    temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold", slant="italic")
            total_width += temp_font.measure(segment.text)

        # Adjust x based on alignment
        screen_width = self._screen_width
        if align == 'center':
            x = (screen_width - total_width) // 2
        elif align == 'right':
            x = screen_width - total_width - 50

        # Render each segment
        current_x = x
        for segment in segments:
            use_font = font
            fill = 'white'
            match segment.format:
                case 'code':
                    use_font = self._code_font
                    fill = '#00ff00'
                case 'bold':
                    use_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold")
                    fill = 'white'
                case 'italic':
                    use_font = tkfont.Font(family="Arial", size=font.actual()['size'], slant="italic")
                    fill = 'white'
                case 'bold_italic':
                    use_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold", slant="italic")
                    fill = 'white'

            self.canvas.create_text(
                current_x, y,
                text=segment.text,
                fill=fill,
                font=use_font,
                anchor='nw'
            )
            current_x += use_font.measure(segment.text)

        return y + font.metrics()['linespace']

    def render_code_text(self, text, x, y) -> int:
        self.canvas.create_text(x, y, text=text, fill='#00ff00', font=self._code_font, anchor='nw')
        return y + self._code_font.metrics()['linespace']

    def render_image(self, img, anchor, x, y) -> int:
        self.canvas.create_image(x, y, image=img, anchor=anchor)
        return y + img.height()

    def render_video_text(self, name, label, x, y) -> int:
        self.canvas.create_text(x, y, text=name, fill='yellow', font=self._normal_font, anchor='nw')
        # TODO Hardcoded name line height 35px
        self.canvas.create_text(x, y + 35, text=label, fill='gray', font=self._code_font, anchor='nw')
        return y + 35 + self._code_font.metrics()['linespace']

    def render_error_text(self, text, x, y) -> int:
        self.canvas.create_text(x, y, text=text, fill='red', font=self._normal_font, anchor='nw')
        return y + self._normal_font.metrics()['linespace']

    def render_slide_number(self, text):
        screen_width = self._screen_width
        screen_height = self._screen_height
        self.canvas.create_text(screen_width - 50, screen_height - 30, text=text, fill='gray', font=self._code_font, anchor='se')


class MarkdownPresenter:
    def __init__(self, markdown_file):
        self.markdown_file = markdown_file
        self.current_slide = 0
        self.slides = []
        self.current_video = None

        # Parse markdown file
        self.slides = Parser().parse_markdown(markdown_file)

        # Setup GUI
        self.root = tk.Tk()
        self.root.title("Markdown Presenter")
        self.root.configure(bg='black')
        self.root.attributes('-fullscreen', True)

        # Font sizes will be calculated dynamically
        self.base_title_size = 48
        self.base_normal_size = 24
        self.base_code_size = 20

        # Create canvas for rendering
        self.canvas = tk.Canvas(self.root, bg='black', highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)

        # Wait for window to be fully rendered to get accurate dimensions
        self.root.update_idletasks()

        # Bind keys
        self.root.bind('<Right>', lambda e: self.next_slide())
        self.root.bind('<Left>', lambda e: self.prev_slide())
        self.root.bind('<space>', lambda e: self.toggle_video())
        self.root.bind('<Escape>', lambda e: self.root.quit())
        self.root.bind('q', lambda e: self.root.quit())

        # Display first slide
        self.display_slide()

    def count_text_lines(self, slide: Slide):
        """Count the number of text lines in a slide (excluding images/videos)"""
        line_count = 0
        for element in slide.elements:
            match element:
                case TitleElement() | TextElement():
                    line_count += 1
                case CodeBlockElement(content=content):
                    line_count += len(content)
        return line_count

    def calculate_font_sizes(self, slide: Slide):
        """Calculate appropriate font sizes based on slide content"""
        # Force window update to get accurate dimensions
        self.root.update_idletasks()
        screen_height = self.root.winfo_height()

        # If window height is still not available, use screen dimensions
        if screen_height <= 1:
            screen_height = self.root.winfo_screenheight()

        # Reserve space for margins and slide number (minimum 100px total)
        margin_space = min(200, int(screen_height * 0.1))
        available_height = max(screen_height - margin_space, 100)

        # Count text lines
        text_lines = self.count_text_lines(slide)

        if text_lines == 0:
            # No text, use default sizes
            return self.base_title_size, self.base_normal_size, self.base_code_size

        # If we have more than 20 lines, reduce font size proportionally
        if text_lines > 20:
            scale_factor = 20 / text_lines
        else:
            scale_factor = 1.0

        # Calculate new font sizes
        title_size = max(16, int(self.base_title_size * scale_factor))
        normal_size = max(12, int(self.base_normal_size * scale_factor))
        code_size = max(10, int(self.base_code_size * scale_factor))

        return title_size, normal_size, code_size

    def display_slide(self):
        """Display current slide"""
        self.canvas.delete('all')

        if self.current_slide >= len(self.slides):
            return

        slide = self.slides[self.current_slide]

        slide_renderer = SlideRenderer(
            root=self.root,
            canvas=self.canvas
        )

        # Calculate and setup fonts based on slide content
        title_size, normal_size, code_size = self.calculate_font_sizes(slide)
        slide_renderer.setup_fonts(title_size, normal_size, code_size)

        y = 100
        x = 100

        for element in slide.elements:
            match element:
                case TitleElement(segments=segments, align=align):
                    y = slide_renderer.render_text(segments, x, y, align, is_title=True)
                    y += 30

                case TextElement(segments=segments, align=align):
                    y = slide_renderer.render_text(segments, x, y, align)
                    y += 10

                case CodeBlockElement(content=content):
                    for line in content:
                        y = slide_renderer.render_code_text(line, x, y)
                    y += 20

                case ImageElement(path=path, alt=alt, align=align):
                    try:
                        img_path = self.resolve_path(path)

                        # Load image with PIL if available
                        pil_img = Image.open(img_path)

                        # Resize if too large (max 80% of screen height)
                        max_height = int(self.root.winfo_height() * 0.8)
                        max_width = int(self.root.winfo_width() * 0.9)

                        if pil_img.height > max_height or pil_img.width > max_width:
                            pil_img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

                        img = ImageTk.PhotoImage(pil_img)

                        # Keep reference to prevent garbage collection
                        if not hasattr(self, 'images'):
                            self.images = []
                        self.images.append(img)

                        # Calculate position based on alignment
                        screen_width = self.root.winfo_width()
                        if align == 'center':
                            img_x = screen_width // 2
                            anchor = 'n'
                        elif align == 'right':
                            img_x = screen_width - 50
                            anchor = 'ne'
                        else:
                            img_x = x
                            anchor = 'nw'

                        y = slide_renderer.render_image(img, anchor, img_x, y)
                        y += 20
                    except Exception as e:
                        error_msg = f"[Image error: {path} - {str(e)}]"
                        y = slide_renderer.render_error_text(error_msg, x, y)
                        y += 20

                case VideoElement(path=path, alt=alt, align=align):
                    try:
                        video_path = self.resolve_path(path)
                        video_msg = f"🎬 Video: {os.path.basename(video_path)}"
                        y = slide_renderer.render_video_text(video_msg, "(Press SPACE to play/pause)", x, y)
                        self.current_video = video_path
                        y += 20
                    except Exception as e:
                        error_msg = f"[Video not found: {path}]"
                        slide_renderer.render_error_text(error_msg, x, y)
                        y += 20

                case _:
                    raise TypeError(type(element))

        # Display slide number
        slide_info = f"Slide {self.current_slide + 1} / {len(self.slides)}"
        slide_renderer.render_slide_number(slide_info)

    def resolve_path(self, path):
        """Resolve relative path based on markdown file location"""
        if os.path.isabs(path):
            return path
        md_dir = os.path.dirname(os.path.abspath(self.markdown_file))
        return os.path.join(md_dir, path)

    def next_slide(self):
        """Go to next slide"""
        if self.current_slide < len(self.slides) - 1:
            self.current_slide += 1
            self.current_video = None
            self.display_slide()

    def prev_slide(self):
        """Go to previous slide"""
        if self.current_slide > 0:
            self.current_slide -= 1
            self.current_video = None
            self.display_slide()

    def toggle_video(self):
        """Toggle video playback"""
        if self.current_video:
            print(f"Playing video: {self.current_video}")
            # Open video with system player
            try:
                import subprocess
                subprocess.Popen(['mpv', '--fullscreen', self.current_video])
            except Exception as e:
                print(f"Error playing video: {e}")
        else:
            # If no video, space acts as next slide
            self.next_slide()

    def run(self):
        """Start the presentation"""
        self.root.mainloop()

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 presenter.py <markdown_file>")
        print("\nExample markdown format:")
        print("# Title Slide")
        print("This is **bold** and this is *italic*")
        print("This is `code`")
        print("---")
        print("# Second Slide")
        print("<center>Centered text</center>")
        print("![Image](path/to/image.png)")
        sys.exit(1)

    presenter = MarkdownPresenter(sys.argv[1])
    presenter.run()

if __name__ == '__main__':
    main()