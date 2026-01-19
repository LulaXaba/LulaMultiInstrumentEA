import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
    title: 'ML-Lite // Protocol',
    description: 'Performance Dashboard Delta v7.1',
}

export default function RootLayout({
    children,
}: {
    children: React.ReactNode
}) {
    return (
        <html lang="en">
            <body className="overflow-hidden">{children}</body>
        </html>
    )
}
