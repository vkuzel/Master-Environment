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

import tkinter as tk
from tkinter import font as tkfont
import re
import sys
import os
from pathlib import Path

try:
    from PIL import Image, ImageTk
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("Warning: PIL not available. Install with: sudo apt install python3-pil python3-pil.imagetk")
    print("Only GIF and PNG images will be supported without PIL.")

class MarkdownPresenter:
    def __init__(self, markdown_file):
        self.markdown_file = markdown_file
        self.current_slide = 0
        self.slides = []
        self.video_playing = False
        self.current_video = None

        # Parse markdown file
        self.parse_markdown()

        # Setup GUI
        self.root = tk.Tk()
        self.root.title("Markdown Presenter")
        self.root.configure(bg='black')
        self.root.attributes('-fullscreen', True)

        # Font sizes will be calculated dynamically
        self.base_title_size = 48
        self.base_normal_size = 24
        self.base_code_size = 20

        # Setup fonts (will be recreated for each slide)
        self.title_font = None
        self.normal_font = None
        self.code_font = None

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

    def parse_markdown(self):
        """Parse markdown file into slides"""
        try:
            with open(self.markdown_file, 'r', encoding='utf-8') as f:
                content = f.read()
        except FileNotFoundError:
            print(f"Error: File '{self.markdown_file}' not found")
            sys.exit(1)

        # Split by horizontal rules
        raw_slides = re.split(r'\n---+\n', content)

        for raw_slide in raw_slides:
            if raw_slide.strip():
                self.slides.append(self.parse_slide_content(raw_slide.strip()))

    def parse_slide_content(self, content):
        """Parse individual slide content into structured format"""
        elements = []
        lines = content.split('\n')
        in_code_block = False
        code_block = []

        for line in lines:
            # Check for code block
            if line.strip().startswith('```'):
                if in_code_block:
                    elements.append({
                        'type': 'code_block',
                        'content': '\n'.join(code_block),
                        'align': 'left'
                    })
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
                elements.append({
                    'type': 'title',
                    'level': level,
                    'content': text,
                    'align': align
                })
            # Check for images
            elif '![' in line:
                match = re.search(r'!\[([^\]]*)\]\(([^\)]+)\)', line)
                if match:
                    alt_text = match.group(1)
                    path = match.group(2)
                    # Determine if it's a video
                    if path.lower().endswith(('.mp4', '.avi', '.mov', '.mkv', '.webm')):
                        elements.append({
                            'type': 'video',
                            'path': path,
                            'alt': alt_text,
                            'align': align
                        })
                    else:
                        elements.append({
                            'type': 'image',
                            'path': path,
                            'alt': alt_text,
                            'align': align
                        })
            # Regular text
            else:
                elements.append({
                    'type': 'text',
                    'content': line,
                    'align': align
                })

        return elements

    def count_text_lines(self, slide):
        """Count the number of text lines in a slide (excluding images/videos)"""
        line_count = 0
        for element in slide:
            if element['type'] in ['title', 'text']:
                line_count += 1
            elif element['type'] == 'code_block':
                line_count += len(element['content'].split('\n'))
        return line_count

    def calculate_font_sizes(self, slide):
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

    def setup_fonts(self, title_size, normal_size, code_size):
        """Create fonts with specified sizes"""
        self.title_font = tkfont.Font(family="Arial", size=title_size, weight="bold")
        self.normal_font = tkfont.Font(family="Arial", size=normal_size)
        self.code_font = tkfont.Font(family="Courier", size=code_size)

    def render_text(self, text, x, y, align='left', is_title=False):
        """Render formatted text with markdown styling"""
        font = self.title_font if is_title else self.normal_font

        # Parse inline formatting
        segments = self.parse_inline_formatting(text)

        # Calculate total width for alignment
        total_width = 0
        for seg_text, seg_font in segments:
            if seg_font == 'code':
                temp_font = self.code_font
            elif seg_font == 'bold':
                temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold")
            elif seg_font == 'italic':
                temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], slant="italic")
            elif seg_font == 'bold_italic':
                temp_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold", slant="italic")
            else:
                temp_font = font
            total_width += temp_font.measure(seg_text)

        # Adjust x based on alignment
        screen_width = self.root.winfo_width()
        if align == 'center':
            x = (screen_width - total_width) // 2
        elif align == 'right':
            x = screen_width - total_width - 50

        # Render each segment
        current_x = x
        for seg_text, seg_font in segments:
            if seg_font == 'code':
                use_font = self.code_font
                fill = '#00ff00'
            elif seg_font == 'bold':
                use_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold")
                fill = 'white'
            elif seg_font == 'italic':
                use_font = tkfont.Font(family="Arial", size=font.actual()['size'], slant="italic")
                fill = 'white'
            elif seg_font == 'bold_italic':
                use_font = tkfont.Font(family="Arial", size=font.actual()['size'], weight="bold", slant="italic")
                fill = 'white'
            else:
                use_font = font
                fill = 'white'

            self.canvas.create_text(current_x, y, text=seg_text, fill=fill,
                                    font=use_font, anchor='nw')
            current_x += use_font.measure(seg_text)

        return y + font.metrics()['linespace']

    def parse_inline_formatting(self, text):
        """Parse bold, italic, and code formatting"""
        segments = []
        pos = 0

        # Pattern to match **bold**, __bold__, *italic*, _italic_, `code`
        pattern = r'(\*\*|__)(.*?)\1|(\*|_)(.*?)\3|`([^`]+)`'

        for match in re.finditer(pattern, text):
            # Add text before match
            if match.start() > pos:
                segments.append((text[pos:match.start()], 'normal'))

            if match.group(1):  # Bold
                segments.append((match.group(2), 'bold'))
            elif match.group(3):  # Italic
                segments.append((match.group(4), 'italic'))
            elif match.group(5):  # Code
                segments.append((match.group(5), 'code'))

            pos = match.end()

        # Add remaining text
        if pos < len(text):
            segments.append((text[pos:], 'normal'))

        return segments if segments else [(text, 'normal')]

    def display_slide(self):
        """Display current slide"""
        self.canvas.delete('all')

        if self.current_slide >= len(self.slides):
            return

        slide = self.slides[self.current_slide]

        # Calculate and setup fonts based on slide content
        title_size, normal_size, code_size = self.calculate_font_sizes(slide)
        self.setup_fonts(title_size, normal_size, code_size)

        y = 100
        x = 100

        for element in slide:
            if element['type'] == 'title':
                y = self.render_text(element['content'], x, y,
                                     element['align'], is_title=True)
                y += 30
            elif element['type'] == 'text':
                y = self.render_text(element['content'], x, y, element['align'])
                y += 10
            elif element['type'] == 'code_block':
                lines = element['content'].split('\n')
                for line in lines:
                    self.canvas.create_text(x, y, text=line, fill='#00ff00',
                                            font=self.code_font, anchor='nw')
                    y += self.code_font.metrics()['linespace']
                y += 20
            elif element['type'] == 'image':
                try:
                    img_path = self.resolve_path(element['path'])

                    # Load image with PIL if available
                    if PIL_AVAILABLE:
                        pil_img = Image.open(img_path)

                        # Resize if too large (max 80% of screen height)
                        max_height = int(self.root.winfo_height() * 0.8)
                        max_width = int(self.root.winfo_width() * 0.9)

                        if pil_img.height > max_height or pil_img.width > max_width:
                            pil_img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

                        img = ImageTk.PhotoImage(pil_img)
                    else:
                        # Fallback to tkinter PhotoImage (GIF/PNG only)
                        img = tk.PhotoImage(file=img_path)

                    # Keep reference to prevent garbage collection
                    if not hasattr(self, 'images'):
                        self.images = []
                    self.images.append(img)

                    # Calculate position based on alignment
                    screen_width = self.root.winfo_width()
                    if element['align'] == 'center':
                        img_x = screen_width // 2
                        anchor = 'n'
                    elif element['align'] == 'right':
                        img_x = screen_width - 50
                        anchor = 'ne'
                    else:
                        img_x = x
                        anchor = 'nw'

                    self.canvas.create_image(img_x, y, image=img, anchor=anchor)
                    y += img.height() + 20
                except Exception as e:
                    error_msg = f"[Image error: {element['path']} - {str(e)}]"
                    self.canvas.create_text(x, y, text=error_msg, fill='red',
                                            font=self.normal_font, anchor='nw')
                    y += 40
            elif element['type'] == 'video':
                try:
                    video_path = self.resolve_path(element['path'])
                    video_msg = f"🎬 Video: {os.path.basename(video_path)}"
                    self.canvas.create_text(x, y, text=video_msg, fill='yellow',
                                            font=self.normal_font, anchor='nw')
                    self.canvas.create_text(x, y + 35,
                                            text="(Press SPACE to play/pause)",
                                            fill='gray', font=self.code_font, anchor='nw')
                    self.current_video = video_path
                    y += 80
                except Exception as e:
                    error_msg = f"[Video not found: {element['path']}]"
                    self.canvas.create_text(x, y, text=error_msg, fill='red',
                                            font=self.normal_font, anchor='nw')
                    y += 40

        # Display slide number
        slide_info = f"Slide {self.current_slide + 1} / {len(self.slides)}"
        screen_width = self.root.winfo_width()
        screen_height = self.root.winfo_height()
        self.canvas.create_text(screen_width - 50, screen_height - 30,
                                text=slide_info, fill='gray',
                                font=self.code_font, anchor='se')

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
            if self.video_playing:
                print(f"Pausing video: {self.current_video}")
                self.video_playing = False
            else:
                print(f"Playing video: {self.current_video}")
                # Open video with system player
                try:
                    if sys.platform.startswith('linux'):
                        # Try mpv first (common on Sway), then fallback to xdg-open
                        # Run in foreground without & to get focus
                        import subprocess
                        import shutil

                        if shutil.which('mpv'):
                            # Use mpv with fullscreen flag
                            subprocess.Popen(['mpv', '--fullscreen', self.current_video])
                        elif shutil.which('vlc'):
                            subprocess.Popen(['vlc', '--fullscreen', self.current_video])
                        else:
                            # Fallback to xdg-open without &
                            subprocess.Popen(['xdg-open', self.current_video])

                        self.video_playing = True
                    elif sys.platform == 'darwin':
                        os.system(f'open "{self.current_video}"')
                        self.video_playing = True
                    else:
                        os.system(f'start "" "{self.current_video}"')
                        self.video_playing = True
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