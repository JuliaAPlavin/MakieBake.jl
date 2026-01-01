interface Position {
  rows: number | [number, number];
  cols: number | [number, number];
}

interface Axis {
  id: number;
  position: Position;
}

interface Widget {
  name: string;
  type: 'slider' | 'select' | 'checkbox';
  values: (number | string | boolean)[];
}

interface Data {
  axes: Axis[];
  widgets: Widget[];
  images: Record<string, Record<string, number | string | boolean>>;
}

// Build lookup key from widget values
function buildKey(values: Record<string, number | string | boolean>): string {
  return Object.entries(values)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}:${typeof v === 'number' ? v.toFixed(6) : v}`)
    .join('_');
}

// Zoom factor: PNG pixels -> screen pixels
const ZOOM = 0.5;

// Parse position to CSS grid values
function positionToCSS(pos: number | [number, number]): string {
  if (typeof pos === 'number') {
    return String(pos);
  }
  return `${pos[0]} / ${pos[1] + 1}`; // CSS grid uses exclusive end
}

async function main() {
  const response = await fetch('./output/params.json');
  const data: Data = await response.json();

  // Build reverse lookup: key -> image id
  const lookup = new Map<string, number>();
  for (const [id, params] of Object.entries(data.images)) {
    lookup.set(buildKey(params), Number(id));
  }

  // Get containers
  const controlsContainer = document.getElementById('controls')!;
  const imagesContainer = document.getElementById('images')!;

  // Calculate grid dimensions
  let maxRow = 1, maxCol = 1;
  for (const axis of data.axes) {
    const rows = axis.position.rows;
    const cols = axis.position.cols;
    const rowEnd = typeof rows === 'number' ? rows : rows[1];
    const colEnd = typeof cols === 'number' ? cols : cols[1];
    maxRow = Math.max(maxRow, rowEnd);
    maxCol = Math.max(maxCol, colEnd);
  }

  // Set up CSS grid
  imagesContainer.style.display = 'grid';
  imagesContainer.style.gridTemplateRows = `repeat(${maxRow}, auto)`;
  imagesContainer.style.gridTemplateColumns = `repeat(${maxCol}, auto)`;

  // Create image elements
  const imageElements: HTMLImageElement[] = [];
  for (const axis of data.axes) {
    const img = document.createElement('img');
    img.style.gridRow = positionToCSS(axis.position.rows);
    img.style.gridColumn = positionToCSS(axis.position.cols);
    img.alt = `Axis ${axis.id}`;
    img.onload = () => {
      img.style.width = `${img.naturalWidth * ZOOM}px`;
    };
    imagesContainer.appendChild(img);
    imageElements.push(img);
  }

  // Track current widget values
  const currentValues: Record<string, number | string | boolean> = {};

  // Create widget elements
  const widgetElements: Map<string, HTMLInputElement | HTMLSelectElement> = new Map();

  for (const widget of data.widgets) {
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
      input.value = '0';

      currentValues[widget.name] = widget.values[0];
      valueSpan.textContent = formatValue(widget.values[0]);

      input.addEventListener('input', () => {
        const val = widget.values[Number(input.value)];
        currentValues[widget.name] = val;
        valueSpan.textContent = formatValue(val);
        updateImages();
      });

      group.appendChild(input);
      widgetElements.set(widget.name, input);

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
      widgetElements.set(widget.name, select);

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
      widgetElements.set(widget.name, input);
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
      for (let i = 0; i < data.axes.length; i++) {
        imageElements[i].src = `./output/${data.axes[i].id}/${id}.png`;
      }
    }
  }

  // Initial update
  updateImages();
}

main();
