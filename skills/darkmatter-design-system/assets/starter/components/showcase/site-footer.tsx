import { Logo } from "@/components/logo"

export function SiteFooter() {
  return (
    <footer className="border-t border-zinc-900/50 py-14">
      <div className="mx-auto flex max-w-[1280px] flex-col items-start justify-between gap-6 px-6 md:flex-row md:items-center">
        <Logo artwork="wordmark" height={14} descriptor="design system" />
        <p className="font-mono text-[10px] tracking-[0.04em] text-zinc-700">
          © 2026 Darkmatter. All rights reserved.
        </p>
      </div>
    </footer>
  )
}
