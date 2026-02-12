from PIL import Image, ImageDraw
import os

# Create a 1024x1024 image with a red background
size = 1024
img = Image.new('RGB', (size, size), color='#D32F2F')

draw = ImageDraw.Draw(img)

# Draw a shield shape (simplified as a rounded rectangle with a point at bottom)
shield_margin = 150
shield_width = size - 2 * shield_margin
shield_height = size - 2 * shield_margin

# Main shield body (rounded rectangle)
shield_color = '#C62828'
draw.rounded_rectangle(
    [(shield_margin, shield_margin), (size - shield_margin, size - shield_margin - 100)],
    radius=80,
    fill=shield_color
)

# Shield point at bottom
points = [
    (size // 2, size - shield_margin),  # Bottom point
    (shield_margin + 100, size - shield_margin - 100),  # Left
    (size - shield_margin - 100, size - shield_margin - 100),  # Right
]
draw.polygon(points, fill=shield_color)

# Draw a white circle in the center for the phone icon background
circle_radius = 280
circle_center = (size // 2, size // 2 - 50)
draw.ellipse(
    [
        (circle_center[0] - circle_radius, circle_center[1] - circle_radius),
        (circle_center[0] + circle_radius, circle_center[1] + circle_radius)
    ],
    fill='white'
)

# Draw a phone icon (simplified)
phone_color = '#D32F2F'
phone_width = 120
phone_height = 200
phone_x = size // 2 - phone_width // 2
phone_y = size // 2 - phone_height // 2 - 50

# Phone body
draw.rounded_rectangle(
    [(phone_x, phone_y), (phone_x + phone_width, phone_y + phone_height)],
    radius=15,
    fill=phone_color
)

# Draw a diagonal line (block symbol) across the phone
line_width = 30
line_color = '#D32F2F'
# Diagonal line from top-left to bottom-right
draw.line(
    [(circle_center[0] - circle_radius + 60, circle_center[1] - circle_radius + 60),
     (circle_center[0] + circle_radius - 60, circle_center[1] + circle_radius - 60)],
    fill=line_color,
    width=line_width
)

# Draw a circle outline for the "no" symbol
draw.ellipse(
    [
        (circle_center[0] - circle_radius + 40, circle_center[1] - circle_radius + 40),
        (circle_center[0] + circle_radius - 40, circle_center[1] + circle_radius - 40)
    ],
    outline=phone_color,
    width=line_width
)

# Save the image
output_path = 'icon.png'
img.save(output_path)
print(f"Icon saved to {output_path}")
