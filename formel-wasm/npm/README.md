# @manuel-rhdt/formel-wasm

Typeset MathML and LaTeX to SVG in the browser with any OpenType **MATH** font, using the layout
engine of [formel](https://github.com/manuel-rhdt/formel). It implements the OpenType MATH
specification and [MathML Core](https://www.w3.org/TR/mathml-core/): script and fraction placement,
stretchy operators, radicals, tables, accents, italic corrections, math kerning.

Unlike MathJax or KaTeX this is not a JavaScript typesetter: it shapes text with the MATH font you
load, so it matches what LuaTeX or XeTeX produce with the same font. The cost is that **you supply
the font**.

## Install

```sh
npm install @manuel-rhdt/formel-wasm
```

## Use

```js
import init, { MathRenderer } from "@manuel-rhdt/formel-wasm";

await init();

const font = new Uint8Array(await (await fetch("/fonts/latinmodern-math.otf")).arrayBuffer());
const renderer = new MathRenderer(font);

document.querySelector("#formula").innerHTML =
  renderer.render_svg('<math><mfrac><mi>a</mi><mi>b</mi></mfrac></math>');
```

`render()` returns the SVG together with its size and the baseline inside it, both in font units
(`units_per_em()` per em), which is what you need to place a formula inline with text:

```js
const { svg, width, height, baseline } = renderer.render("<math><mi>x</mi></math>", false);
```

LaTeX is converted with [math-core](https://github.com/tmke8/math-core) before it is laid out:

```js
import { latex_to_mathml, latex_error_range } from "@manuel-rhdt/formel-wasm";

const mathml = latex_to_mathml("\\int_0^1 x^2\\,\\mathrm{d}x", true); // display style
const range = latex_error_range("\\frac{", true); // [start, end] in UTF-16 units, or undefined
```

All free OpenType MATH fonts work (New Computer Modern, STIX Two, TeX Gyre, Asana, Fira Math, …);
Cambria Math works too but its license does not allow redistribution.

## Bundlers

The module is a wasm-bindgen `--target web` build. It loads its `.wasm` relative to itself
(`import.meta.url`), which Vite, webpack, Rollup and esbuild rewrite for you. If you serve the
JavaScript and the `.wasm` yourself, make sure the server sends `application/wasm`; otherwise the
glue falls back to a slower fetch-and-instantiate path.

## License

MIT for the engine. Fonts are not included and keep their own licenses.
