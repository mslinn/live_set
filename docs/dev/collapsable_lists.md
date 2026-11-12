# Collapsible Nested Lists

I want to be able to collapse nested markdown lists. For example:

```markdown
* item 1
* item 2
  * item 2.1
  * item 2.2
    * item 2.2.1
    * item 2.2.2
    * item 2.2.3
  * item 2.3
* item 3
  * item 3.1
* item 4
```

Standard Markdown can indent nested bullets, but it doesn't support collapsing
them. To make nested lists collapsible, use HTML `<details>` and `<summary>`
elements. Writing the whole list as HTML, with no Markdown inside, avoids
differences in how Markdown processors handle Markdown nested inside HTML.

```html
<ul>
  <li>item 1</li>
  <li>
    <details open>
      <summary>item 2</summary>
      <ul>
        <li>item 2.1</li>
        <li style="list-style: none;"> <!-- optional tweak for open details child -->
          <details open>
            <summary>item 2.2</summary>
            <ul>
              <li>item 2.2.1</li>
              <li>item 2.2.2</li>
              <li>item 2.2.3</li>
            </ul>
          </details>
        </li>
        <li>item 2.3</li>
      </ul>
    </details>
  </li>
  <li style="list-style: none;">
    <details closed>
      <summary>item 3  (click me to open)</summary>
      <ul>
        <li>item 3.1</li>
      </ul>
    </details>
  </li>
  <li>item 4</li>
</ul>
```

Renders as:

<ul>
  <li>item 1</li>
  <li>
    <details open>
      <summary>item 2</summary>
      <ul>
        <li>item 2.1</li>
        <li style="list-style: none;"> <!-- optional tweak for open details -->
          <details open>
            <summary>item 2.2</summary>
            <ul>
              <li>item 2.2.1</li>
              <li>item 2.2.2</li>
              <li>item 2.2.3</li>
            </ul>
          </details open>
        </li>
        <li>item 2.3</li>
      </ul>
    </details>
  </li>
  <li style="list-style: none;">
    <details closed>
      <summary>item 3  (click me to open)</summary>
      <ul>
        <li>item 3.1</li>
      </ul>
    </details>
  </li>
  <li>item 4</li>
</ul>


Notes:

- Because the block is pure HTML, it does not depend on the Markdown
  processor's rules for parsing Markdown within HTML blocks (for example,
  kramdown's `markdown="1"` requirement).
- Do not put blank lines inside the block. Some processors end an HTML block
  at a blank line and then treat the remaining indented lines as a code block.
- All items start collapsed. Add `open` to a `<details>` tag
  (`<details open>`) to start it expanded.
- Only items with children use `<details>`; leaf items are plain `<li>`. In
  most browsers, a collapsible item shows both the list bullet and the
  disclosure triangle, and leaf text is not aligned with summary text. CSS can
  adjust this if needed.
- The <details> `open` attribute controls the initial open/closed state of its
  parent list node (an `li` instance). Without it, the `li` instance element
  initializes as a collapsed / closed list node. With it, the element starts
expanded. Each <details> element is controlled independently.


## Behavior by viewer

No markup works in every viewer. This HTML degrades without losing content:

- **Current browsers (Chrome, Firefox, Safari, Edge):** `<details>` and
  `<summary>` are supported, so the lists collapse. No JavaScript or CSS is
  required.
- **Browsers without `<details>` support (Internet Explorer 11, legacy
  Edge):** the unrecognized elements are ignored and all content is shown
  expanded. The list stays readable but does not collapse.
- **Markdown renderers that pass HTML through (GitHub, for example):**
  `<details>`, `<summary>`, `<ul>` and `<li>` are allowed, so the lists
  collapse. A renderer with a stricter HTML sanitizer may strip the tags,
  leaving the text as a flattened or unindented list.
- **Raw-text viewers (plain-text editors, `cat`, `less`, email clients that
  show Markdown source):** no HTML parser runs, so the tags appear as literal
  characters. The content is still readable, in the correct order.

If the Markdown file is rendered to a web page first (for example, by Jekyll),
readers only need a current browser. If the raw file is distributed, the
raw-text case applies to some readers.
