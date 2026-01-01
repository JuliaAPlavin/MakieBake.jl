// Julia export format interfaces
interface JuliaExportData {
  snapshots: Record<string, number | string | boolean>[];
  blocks: { size: { width: number; height: number } }[];
  controls: { name: string; values: (number | string | boolean)[] }[];
}


// Internal widget representation
interface Widget {
  name: string;
  type: 'slider' | 'select' | 'checkbox';
  values: (number | string | boolean)[];
}

// Internal axis representation
interface Axis {
  id: number;
  size: { width: number; height: number };
}

// Build lookup key from widget values (must match for image lookup)
function buildKey(values: Record<string, number | string | boolean>): string {
  return Object.entries(values)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}:${typeof v === 'number' ? v.toFixed(6) : v}`)
    .join('_');
}

// Infer widget type from values array
function inferWidgetType(values: (number | string | boolean)[]): 'slider' | 'select' | 'checkbox' {
  if (values.every(v => typeof v === 'boolean')) return 'checkbox';
  if (values.every(v => typeof v === 'number')) return 'slider';
  return 'select';
}

// Build reverse lookup: key -> 1-indexed image number
function buildSnapshotLookup(snapshots: Record<string, number | string | boolean>[]): Map<string, number> {
  const lookup = new Map<string, number>();
  for (let i = 0; i < snapshots.length; i++) {
    lookup.set(buildKey(snapshots[i]), i + 1); // Julia uses 1-indexed files
  }
  return lookup;
}

// Zoom factor: PNG pixels -> screen pixels
const ZOOM = 0.5;

// Optional LAYOUT and HEADER from layout.js (loaded before this script)
declare const LAYOUT: string[] | undefined;
declare const HEADER: string | undefined;

// Default header with Julia colors (purple, green, blue, red)
const DEFAULT_HEADER = '<span style="color:#9558B2">Makie</span><span style="color:#389826">Bake</span><span style="color:#4063D8">.</span><span style="color:#CB3C33">jl</span>';

function initViewer(data: JuliaExportData) {
  // Set header
  const header = document.getElementById('header')!;
  header.innerHTML = typeof HEADER !== 'undefined' ? HEADER : DEFAULT_HEADER;

  // Build reverse lookup from snapshots array
  const lookup = buildSnapshotLookup(data.snapshots);

  // Convert controls to widgets with inferred types
  const widgets: Widget[] = data.controls.map(c => ({
    name: c.name,
    type: inferWidgetType(c.values),
    values: c.values
  }));

  // Convert blocks to axes (1-indexed to match block_N directories)
  const axes: Axis[] = data.blocks.map((block, index) => ({
    id: index + 1,
    size: block.size
  }));

  // Get main container
  const main = document.getElementById('main')!;
  const controlsContainer = document.getElementById('controls')!;

  // Compute layout: use LAYOUT if defined, else default row layout
  // Block areas use "A", "B", "C"...; "S" for sliders
  const blockArea = (i: number) => String.fromCharCode(65 + i); // A, B, C...
  const layout = typeof LAYOUT !== 'undefined' ? LAYOUT
    : [axes.map((_, i) => blockArea(i)).concat(['S']).join(' ')];

  // Apply CSS grid-template-areas
  const gridAreas = layout.map(row => `"${row}"`).join(' ');
  main.style.gridTemplateAreas = gridAreas;

  // Create block containers with grid-area
  const imageElements: HTMLImageElement[] = [];
  for (const axis of axes) {
    const container = document.createElement('div');
    container.className = 'block';
    container.style.gridArea = blockArea(axis.id - 1);

    const img = document.createElement('img');
    img.alt = `Block ${axis.id}`;
    img.onload = () => {
      img.style.width = `${img.naturalWidth * ZOOM}px`;
    };
    container.appendChild(img);
    main.appendChild(container);
    imageElements.push(img);
  }

  // Track current widget values
  const currentValues: Record<string, number | string | boolean> = {};

  // Create widget elements
  for (const widget of widgets) {
    const group = document.createElement('div');
    group.className = 'widget-group';

    const label = document.createElement('label');
    label.textContent = `${widget.name}: `;

    const valueSpan = document.createElement('span');
    valueSpan.className = 'value-display';
    label.appendChild(valueSpan);

    group.appendChild(label);

    if (widget.type === 'slider') {
      const input = document.createElement('input');
      input.type = 'range';
      input.min = '0';
      input.max = String(widget.values.length - 1);
      const midIndex = Math.floor((widget.values.length - 1) / 2);
      input.value = String(midIndex);

      currentValues[widget.name] = widget.values[midIndex];
      valueSpan.textContent = formatValue(widget.values[midIndex]);

      input.addEventListener('input', () => {
        const val = widget.values[Number(input.value)];
        currentValues[widget.name] = val;
        valueSpan.textContent = formatValue(val);
        updateImages();
      });

      group.appendChild(input);

    } else if (widget.type === 'select') {
      const select = document.createElement('select');

      for (let i = 0; i < widget.values.length; i++) {
        const option = document.createElement('option');
        option.value = String(i);
        option.textContent = String(widget.values[i]);
        select.appendChild(option);
      }

      currentValues[widget.name] = widget.values[0];
      valueSpan.textContent = '';

      select.addEventListener('change', () => {
        const val = widget.values[Number(select.value)];
        currentValues[widget.name] = val;
        updateImages();
      });

      group.appendChild(select);

    } else if (widget.type === 'checkbox') {
      const input = document.createElement('input');
      input.type = 'checkbox';
      input.checked = widget.values[0] === true;

      currentValues[widget.name] = widget.values[0];
      valueSpan.textContent = '';

      input.addEventListener('change', () => {
        currentValues[widget.name] = input.checked;
        updateImages();
      });

      group.appendChild(input);
    }

    controlsContainer.appendChild(group);
  }

  function formatValue(val: number | string | boolean): string {
    if (typeof val === 'number') {
      return val.toFixed(2);
    }
    return String(val);
  }

  function updateImages() {
    const id = lookup.get(buildKey(currentValues));
    if (id !== undefined) {
      for (let i = 0; i < axes.length; i++) {
        // Julia exports to block_N directories with 1-indexed image files
        imageElements[i].src = `./block_${axes[i].id}/${id}.png`;
      }
    }
  }

  // Initial update
  updateImages();
}

// Export for use by HTML bootstrap
(window as any).initViewer = initViewer;
