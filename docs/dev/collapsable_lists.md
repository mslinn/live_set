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
them. Because markdown processors pass through html unchanged, we generate this
portion of the `als_report` markdown output as HTML.

To make nested lists collapsible, use HTML `<details>` and `<summary>`
elements. Writing the whole list as HTML, with no Markdown inside, avoids
differences in how Markdown processors handle Markdown nested inside HTML. No
CSS or JavaScript is required.

```html
<ul style="list-style: none; padding-left: 12pt;">
  <li>1. This is the top level blah</li>
  <li style="list-style: none;">
    <details open>
      <summary>1.1 Sublevel Blah</summary>
      <ul style="list-style: none;">
        <li>1.1 blah</li>
        <li"> <!-- optional tweak for open details child -->
          <details open>
            <summary>1.2 blah</summary>
            <ul>
              <li>2.2.1 blah</li>
              <li>2.2.2 blah</li>
              <li>2.2.3 blah</li>
            </ul>
          </details>
        </li>
        <li>2.3 blah</li>
      </ul>
    </details>
  </li>
  <li style="list-style: none;">
    <details closed>
      <summary>3  <i>click me to open</i></summary>
      <ul style="list-style: none;">
        <li>3.1 blah</li>
      </ul>
    </details>
  </li>
  <li>4 blah</li>
</ul>
```

Renders as:

<ul style="list-style: none; padding-left: 12pt;">
  <li>1. This is the top level blah</li>
  <li>
    <details open>
      <summary>1.1 Sublevel Blah</summary>
      <ul style="list-style: none;">
        <li>1.1 blah</li>
        <li"> <!-- optional tweak for open details child -->
          <details open>
            <summary>1.2 blah</summary>
            <ul>
              <li>2.2.1 blah</li>
              <li>2.2.2 blah</li>
              <li>2.2.3 blah</li>
            </ul>
          </details>
        </li>
        <li>2.3 blah</li>
      </ul>
    </details>
  </li>
  <li>
    <details closed>
      <summary>3  <i>click me to open</i></summary>
      <ul style="list-style: none;">
        <li>3.1 blah</li>
      </ul>
    </details>
  </li>
  <li>4 blah</li>
</ul>


Notes:

- Every `<ul>` and every `<li>` that contains a <details> needs `list-style: none;`. The
  `<ul>` elements keep their default left padding, so the indentation still shows
  the hierarchy.
- All items start collapsed. Add `open` to a `<details>` tag
  (`<details open>`) to start it expanded.
- Only items with children use `<details>`; leaf items are plain `<li>`. In
  most browsers, a collapsible item shows both the list bullet and the
  disclosure triangle, and leaf text is not aligned with summary text. CSS can
  adjust this if needed.
- The `<details>` `open` attribute controls the initial open/closed state of its
  parent list node (an `li` instance). Without it, the `li` instance element
  initializes as a collapsed / closed list node. With it, the element starts
  expanded. Each `<details>` element is controlled independently.
- Do not put blank lines inside the block. Some processors end an HTML block
  at a blank line and then treat the remaining indented lines as a code block.
- To remove the triangle as well, add `style="list-style: none;"` to each `<summary>`.
  This works in current Firefox, Chrome and Edge. Safari versions before 18 need
  the `::-webkit-details-marker` pseudo-element, which cannot be set inline, so the
  triangle remains there. Without the triangle, nothing indicates which items
  collapse, except any text you add such as “click me to open”.


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
  leaving the text as a flattened or unindented list. This is desirable
  behavior, so we get this feature for free.
