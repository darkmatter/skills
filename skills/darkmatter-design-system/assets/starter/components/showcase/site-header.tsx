"use client"

import { Logo } from "@/components/logo"
import { GitHubIcon } from "@/components/ui/github-icon"
import { Button } from "@/components/ui/button"

const NAV = [
  { label: "products", href: "#products" },
  { label: "color", href: "#color" },
  { label: "type", href: "#type" },
  { label: "components", href: "#components" },
  { label: "effects", href: "#effects" },
]

export function SiteHeader() {
  return (
    <header className="fixed inset-x-0 top-0 z-50 border-b border-zinc-900/70 bg-black/70 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-[1280px] items-center justify-between px-6">
        <a href="#top" className="flex items-center">
          {/* Phones get the mark: the wordmark would crowd the buttons. */}
          <Logo artwork="mark" height={15} descriptor="design system" className="sm:hidden" />
          <Logo artwork="wordmark" height={18} descriptor="design system" className="max-sm:hidden" />
        </a>

        {/* The links fit beside the wordmark and the buttons from `lg`; at `md` they push "Get started" off the edge. */}
        <nav className="hidden items-center gap-7 lg:flex">
          {NAV.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="font-sans text-[13px] font-medium tracking-[0.01em] text-zinc-400 capitalize transition-colors hover:text-white"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <Button asChild variant="ghost" size="icon" className="text-zinc-400 hover:text-white">
            <a href="#" aria-label="GitHub repository">
              <GitHubIcon className="size-4" />
            </a>
          </Button>
          <Button size="sm">Get started</Button>
        </div>
      </div>
    </header>
  )
}
