/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        './pages/**/*.{js,ts,jsx,tsx,mdx}',
        './components/**/*.{js,ts,jsx,tsx,mdx}',
        './app/**/*.{js,ts,jsx,tsx,mdx}',
    ],
    theme: {
        extend: {
            colors: {
                terminal: {
                    black: '#0a0a0a',
                    dark: '#1a1a1a',
                    darker: '#0d0d0d',
                    green: '#00ff41',
                    crimson: '#ff0844',
                    blue: '#00d9ff',
                    yellow: '#ffeb3b',
                    gray: '#a0a0a0',
                    'gray-dark': '#666666',
                    'grid': '#2a2a2a',
                },
            },
            fontFamily: {
                mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
            },
            animation: {
                'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                'flicker': 'flicker 0.15s ease-in-out',
            },
            keyframes: {
                flicker: {
                    '0%, 100%': { opacity: 1 },
                    '50%': { opacity: 0.8 },
                },
            },
        },
    },
    plugins: [],
}
