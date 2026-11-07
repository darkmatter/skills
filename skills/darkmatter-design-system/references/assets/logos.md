# Logos & assets

The Darkmatter logo is the DRKMTR wordmark and its mark, from the Darkmatter brand pack v1 (guidelines dated October 2026). The starter's `public/` holds byte-for-byte copies of the pack's files. To give another app the logo, copy these files into its `public/` unchanged, names included.

## Logo files

| Path | Artwork | Use |
| --- | --- | --- |
| `/img/drkmtr-wordmark-white.svg` | Wordmark, white, 1187.592 × 100 | Dark surfaces, which is every surface in this dark-only system |
| `/img/drkmtr-wordmark-black.svg` | Wordmark, `#060606`, 1187.592 × 100 | Light surfaces |
| `/img/drkmtr-mark-white.svg` | Mark, white, 186.092 × 100 | Slots under 120 px wide on dark surfaces: avatars, icons, a phone header |
| `/img/drkmtr-mark-black.svg` | Mark, `#060606`, 186.092 × 100 | Slots under 120 px wide on light surfaces, such as a light button |
| `/favicon-16.png` | App icon on the pack's black tile, 16 × 16 | Browser tab icon |

Take logo files only from this table, and check any copy against the SHA-256 list under [Source](#source). Other darkmatter repos carry artwork that is not the pack's. In darkmatter/web, which v0 mounts as a reference, `/logo-white.svg`, `/logo-black.svg` and `/img/logo-square-*.svg` are the retired `{d'}` logo, and `/img/wordmark-white.svg` is an earlier DRKMTR drawing with curved strokes.

## Placing the logo

- **Pick the ink by surface.** White artwork on dark surfaces, `#060606` artwork on light ones, set straight on the surface exactly as the file draws it: one ink at full strength, with no backing plate or tile. Only the favicon keeps the pack's black tile, because it sits in the browser tab rather than on the page.
- **Pick the artwork by slot.** In headers and footers, use the wordmark with the product's name beside it, as darkmatter/agents does. Where the logo gets less than 120 px of width (avatars, icons, a phone header), use the mark, 25 px wide or more. The pack's own default is its horizontal lockup, and it keeps the bare wordmark for places where the mark is already close by. The lockup, the small mark (16–24 px) and the larger app icons are not in this skill: ask the user for those pack files rather than assembling or scaling them from these.
- **Size by cap height.** Both drawings are 100 units tall and all capitals, so the rendered height is the cap height. Width is height × 11.876 for the wordmark and height × 1.861 for the mark.
- **Keep one cap height of clear space around the logo.** The product's name sits exactly that far to its right, in the logo's ink, set like darkmatter/agents' brand mockups: `font-sans` with `tracking-[0.12em]`, at `text-xs` beside a wordmark up to about 18 px tall (the mockups use 15 px beside a 25 px one). darkmatter/agents writes `agents` there; this starter writes `design system`.
- **Write the name as Darkmatter.** The wordmark exists only as artwork, so text and alt text spell the name "Darkmatter". Give the logo `alt="Darkmatter"`, or `alt=""` when a surrounding link or button already carries the name.

The starter's [`components/logo.tsx`](../../assets/starter/components/logo.tsx) applies these rules for the white artwork, and its header and footer use it:

```tsx
import { Logo } from "@/components/logo"

{/* header: the wordmark, 18 px tall, with the product's name */}
<Logo artwork="wordmark" height={18} descriptor="design system" />

{/* phone header: the mark, 15 px tall and so 28 px wide */}
<Logo artwork="mark" height={15} descriptor="design system" />

{/* footer */}
<Logo artwork="wordmark" height={14} descriptor="design system" />
```

## Fonts

- `/fonts/monaspace-neon-var.woff2` — the Monaspace Neon variable brand face, loaded via `@font-face` in `app/globals.css`. Other families (Geist, Montserrat, Lora, Monaspace Xenon) load from `@fontsource*` packages.

## Icons

- `lucide-react` and `@tabler/icons-react` are installed — use these for UI icons.
- `@/components/ui/github-icon` provides an inline GitHub mark.

## Source

The logo files are byte-for-byte copies from the brand pack v1 (`drkmtr-brand-pack.zip`, SHA-256 `a609276732d22943e29c38e9a78b9da0247c02aebe2bd347587ff2af403ff5ed`), taken from the copies darkmatter/agents keeps in its `darkmatter-brand-pack` folder under `docs/brand/`. That folder's `README.md` summarizes the pack's rules and its `provenance.json` records each file's path in the pack. Replace a file by copying it from there; edit none in place. In the starter's `public/`, `sha256sum -c` on this list passes:

```text
1aa7a631eaaf97a62464284ce7c9c5c42c1ddd6684664ed145e7352150ab57cd  img/drkmtr-wordmark-black.svg
4995daea62bb8c858f9f9eb85bd7c5381c4dd9d74654b423967c44c7ab0587a6  img/drkmtr-wordmark-white.svg
c1d37d5777c45259e3cd8b2e38a9711ee5bd43691513be3ac3411ab7d017845a  img/drkmtr-mark-black.svg
00c84a65e93e94af8e4a3dd7baa942941291160c4d5c7cf31fca43a7a3bab589  img/drkmtr-mark-white.svg
52c5bc49033cf4b899fd22c6075a37b19b9dad16e57c5846d4ee9efee10ef795  favicon-16.png
```
