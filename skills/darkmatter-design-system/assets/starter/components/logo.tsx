import { cn } from "@/lib/utils"

// Byte-for-byte copies of the Darkmatter brand pack v1 artwork in public/img/;
// the skill's references/assets/logos.md lists their source and rules. The
// starter is dark-only, so it uses the white artwork.
const ARTWORK = {
  wordmark: { src: "/img/drkmtr-wordmark-white.svg", widthPerHeight: 1187.592 / 100 },
  mark: { src: "/img/drkmtr-mark-white.svg", widthPerHeight: 186.092 / 100 },
} as const

/**
 * The Darkmatter logo: the wordmark, or the mark for slots under 120 px wide.
 * Both drawings are all capitals, so `height` is the cap height; at 14 px or
 * more the mark is at least 25 px wide, the smallest the regular mark allows.
 * A descriptor, the product's name, sits one cap height to the right: the
 * brand pack's clear space. Pass `alt=""` when the surrounding link or button
 * already names Darkmatter.
 */
export function Logo({
  artwork,
  height,
  descriptor,
  alt = "Darkmatter",
  className,
}: {
  artwork: keyof typeof ARTWORK
  height: number
  descriptor?: string
  alt?: string
  className?: string
}) {
  const { src, widthPerHeight } = ARTWORK[artwork]
  return (
    <span className={cn("inline-flex items-center", className)} style={{ gap: height }}>
      <img
        src={src}
        alt={alt}
        width={Math.round(height * widthPerHeight)}
        height={height}
        className="shrink-0"
      />
      {descriptor ? (
        <span className="font-sans text-xs tracking-[0.12em] whitespace-nowrap text-white">
          {descriptor}
        </span>
      ) : null}
    </span>
  )
}
