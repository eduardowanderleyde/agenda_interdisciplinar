module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.erb'
  ],
  safelist: [
    'bg-white/10',
    'backdrop-blur-md',
    'rounded-3xl',
    'shadow-xl',
    'border-white/20',
    'text-white',
    'bg-gradient-to-br',
    'from-indigo-500',
    'via-blue-600',
    'to-purple-600',  'bg-card',
    'rounded-card',
    'shadow-card',
    'text-primary',
    'text-secondary'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#6366f1',      // Roxo principal
        secondary: '#a21caf',    // Roxo escuro
        fundo: '#f3f4f6',        // Cinza claro
        card: '#ffffff',         // Branco para cards
      },
      borderRadius: {
        card: '1rem',
      },
      boxShadow: {
        card: '0 4px 24px 0 rgba(0,0,0,0.08)',
      }
    },
  },
  plugins: [],
}
