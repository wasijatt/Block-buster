HOW TO USE A CUSTOM FONT (e.g. Poppins)
========================================

1. Download Poppins Bold from Google Fonts:
   https://fonts.google.com/specimen/Poppins
   (Select "Bold 700" weight, click Download Family)

2. From the downloaded ZIP, copy:
     Poppins-Bold.ttf  →  this folder  (res://assets/fonts/)
     Poppins-Regular.ttf  →  this folder  (optional, for body text)

3. In Main.gd, update _apply_visual_theme() to use the font:
     var font := load("res://assets/fonts/Poppins-Bold.ttf") as FontFile
     score_label.add_theme_font_override("font", font)
     game_over_label.add_theme_font_override("font", font)
     # etc.

4. You can also reference the font in theme.tres by adding:
     default_font = ExtResource("font_id")
   after importing the .ttf file as a resource in the Godot editor.

No font file is required to run the game — runtime size/shadow overrides
applied in Main.gd already give a premium look with the default font.
