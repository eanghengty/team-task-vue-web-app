/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js}'],
  theme: {
    extend: {
      fontFamily: {
        display: ['"Bebas Neue"', 'cursive'],
        mono: ['"DM Mono"', 'monospace'],
        sans: ['"Space Grotesk"', 'sans-serif'],
      },
      colors: {
        bg: '#0d0d0d',
        surface: '#141414',
        surface2: '#1c1c1c',
        border: '#2a2a2a',
        accent: '#e8ff47',
        accent2: '#ff4747',
        accent3: '#47c5ff',
        muted: '#666',
      },
    },
  },
  plugins: [],
}
