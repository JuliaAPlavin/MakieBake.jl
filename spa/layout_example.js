// Example layout.js - copy to your output folder and rename to layout.js
// All variables are optional - remove any you don't need

// Custom header (HTML string)
const HEADER = 'My Visualization';

// Custom page title (default: 'MakieBake – interactive Makie plots')
const TITLE = 'My Visualization';

// Hide footer (default: false)
const NO_FOOTER = false;

// Zoom factor for images (default: 1)
const ZOOM = 0.5;

// Max width for the grid (e.g., '1200px', '80vw')
const MAXWIDTH = '1200px';

// Custom grid layout using CSS grid-template-areas syntax
// Each string is a row, use:
//   A, B, C... for block areas (1st block = A, 2nd = B, etc.)
//   S for sliders/controls
//   . for empty cell
const LAYOUT = [
    "A A S",
    "B C S"
];

// More layout examples:
//
// Vertical stack with controls on right:
// const LAYOUT = ["A S", "B S", "C S"];
//
// Controls on top:
// const LAYOUT = ["S S", "A B"];
//
// Single block with controls below:
// const LAYOUT = ["A", "S"];
//
// Complex 3-block layout:
// const LAYOUT = ["A A B", "A A C", "S S S"];
