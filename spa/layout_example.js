// Example layout.js - copy to your output folder and rename to layout.js
// All variables are optional - remove any you don't need

// Custom header (HTML string)
const HEADER = 'My Visualization';

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
